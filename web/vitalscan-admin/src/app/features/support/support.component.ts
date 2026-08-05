import { Component, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { HasPermissionDirective } from '../../core/has-permission.directive';

interface Ticket {
  id: string;
  ticketNumber: string;
  customer: string;
  subject: string;
  category: string;
  status: string;
  priority: string;
  createdAt: string;
  updatedAt: string;
}

interface Message {
  id: string;
  senderUserId: string;
  isFromAgent: boolean;
  body: string;
  createdAt: string;
}

const STATUSES = ['Open', 'Assigned', 'InProgress', 'Resolved', 'Closed'];

@Component({
  selector: 'app-support',
  standalone: true,
  imports: [FormsModule, DatePipe, HasPermissionDirective],
  template: `
    <div class="head">
      <h1>Support</h1>
      <select class="input filter" [(ngModel)]="status" (ngModelChange)="load()">
        <option value="">All statuses</option>
        @for (s of statuses; track s) { <option [value]="s">{{ label(s) }}</option> }
      </select>
    </div>

    <div class="card">
      <table>
        <thead>
          <tr><th>Ticket #</th><th>Customer</th><th>Subject</th><th>Category</th>
              <th>Priority</th><th>Status</th><th>Updated</th></tr>
        </thead>
        <tbody>
          @for (t of tickets(); track t.id) {
            <tr class="clickable" (click)="open(t)">
              <td class="name">{{ t.ticketNumber }}</td>
              <td class="muted">{{ t.customer }}</td>
              <td>{{ t.subject }}</td>
              <td class="muted">{{ t.category }}</td>
              <td class="muted">{{ t.priority }}</td>
              <td><span class="pill" [attr.data-s]="t.status">{{ label(t.status) }}</span></td>
              <td class="muted">{{ t.updatedAt | date:'short' }}</td>
            </tr>
          } @empty {
            <tr><td colspan="7" class="muted">{{ loading() ? 'Loading…' : 'No tickets found.' }}</td></tr>
          }
        </tbody>
      </table>
    </div>

    @if (active()) {
      <div class="overlay" (click)="close()">
        <div class="drawer card" (click)="$event.stopPropagation()">
          <div class="drawer-head">
            <div>
              <h2>{{ active()!.ticketNumber }}</h2>
              <span class="muted">{{ active()!.subject }} · {{ active()!.customer }}</span>
            </div>
            <button class="link" (click)="close()">Close</button>
          </div>

          <div class="thread">
            @for (m of messages(); track m.id) {
              <div class="bubble-row" [class.agent]="m.isFromAgent">
                <div class="bubble" [class.agent]="m.isFromAgent">
                  <div class="bubble-body">{{ m.body }}</div>
                  <div class="bubble-time">{{ m.createdAt | date:'short' }}</div>
                </div>
              </div>
            } @empty {
              <p class="muted">{{ loadingMsgs() ? 'Loading…' : 'No messages yet.' }}</p>
            }
          </div>

          <div class="reply" *appHasPermission="'support.respond'">
            <textarea class="input" rows="3" placeholder="Write a reply…" [(ngModel)]="replyText"></textarea>
            <div class="reply-foot">
              <button class="btn" [disabled]="sending() || !replyText.trim()" (click)="reply()">
                {{ sending() ? 'Sending…' : 'Send reply' }}
              </button>
            </div>
          </div>

          <div class="drawer-foot">
            @if (active()!.status !== 'Closed') {
              <button class="link danger" *appHasPermission="'support.close'"
                      [disabled]="closing()" (click)="closeTicket()">Close ticket</button>
            }
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 0; }
    .filter { max-width: 200px; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 12px; color: var(--text-secondary); padding: 8px 12px; border-bottom: 1px solid var(--border); }
    td { padding: 12px; border-bottom: 1px solid var(--border); font-size: 14px; }
    .clickable { cursor: pointer; }
    .clickable:hover { background: #f8fafc; }
    .name { font-weight: 600; font-family: monospace; }
    .muted { color: var(--text-secondary); }
    .link { background: none; border: none; color: var(--teal-700); font-weight: 600; cursor: pointer; }
    .link.danger { color: var(--error); }
    .pill { font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 999px; background: #eef2f6; color: var(--text-secondary); }
    .pill[data-s="Resolved"], .pill[data-s="Closed"] { background: #e6f4f1; color: var(--teal-700); }
    .pill[data-s="Open"] { background: #fff4e5; color: #b26a00; }
    .overlay { position: fixed; inset: 0; background: rgba(15,23,42,.45); display: flex; justify-content: flex-end; z-index: 50; }
    .drawer { width: 520px; max-width: 92vw; height: 100%; border-radius: 0; display: flex; flex-direction: column; overflow-y: auto; }
    .drawer-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; margin-bottom: 18px; }
    .drawer-head h2 { font-size: 18px; margin: 0 0 4px; }
    .thread { flex: 1; display: flex; flex-direction: column; gap: 10px; padding: 8px 0; }
    .bubble-row { display: flex; }
    .bubble-row.agent { justify-content: flex-end; }
    .bubble { max-width: 78%; background: #eef2f6; border-radius: 12px; padding: 10px 12px; }
    .bubble.agent { background: var(--teal-700); color: #fff; }
    .bubble-body { font-size: 14px; white-space: pre-wrap; }
    .bubble-time { font-size: 11px; opacity: .7; margin-top: 4px; }
    .reply { margin-top: 16px; }
    textarea.input { resize: vertical; }
    .reply-foot { display: flex; justify-content: flex-end; margin-top: 10px; }
    .drawer-foot { display: flex; justify-content: flex-start; margin-top: 16px; padding-top: 14px; border-top: 1px solid var(--border); }
  `],
})
export class SupportComponent {
  private http = inject(HttpClient);

  tickets = signal<Ticket[]>([]);
  loading = signal(false);
  status = '';
  statuses = STATUSES;

  active = signal<Ticket | null>(null);
  messages = signal<Message[]>([]);
  loadingMsgs = signal(false);
  sending = signal(false);
  closing = signal(false);
  replyText = '';

  constructor() {
    this.load();
  }

  label(s: string): string {
    return s.replace(/([a-z])([A-Z])/g, '$1 $2');
  }

  async load(): Promise<void> {
    this.loading.set(true);
    try {
      const q = this.status ? `?status=${this.status}` : '';
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/support/tickets${q}`));
      this.tickets.set((res.data ?? []) as Ticket[]);
    } catch {
      this.tickets.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  open(t: Ticket): void {
    this.active.set(t);
    this.replyText = '';
    this.loadMessages(t.id);
  }

  close(): void {
    this.active.set(null);
    this.messages.set([]);
  }

  private async loadMessages(id: string): Promise<void> {
    this.loadingMsgs.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/support/tickets/${id}/messages`));
      this.messages.set((res.data ?? []) as Message[]);
    } catch {
      this.messages.set([]);
    } finally {
      this.loadingMsgs.set(false);
    }
  }

  async reply(): Promise<void> {
    const t = this.active();
    if (!t || !this.replyText.trim()) return;
    this.sending.set(true);
    try {
      await firstValueFrom(this.http.post(`${API_BASE_URL}/admin/support/tickets/${t.id}/reply`, { body: this.replyText }));
      this.replyText = '';
      await this.loadMessages(t.id);
    } finally {
      this.sending.set(false);
    }
  }

  async closeTicket(): Promise<void> {
    const t = this.active();
    if (!t) return;
    this.closing.set(true);
    try {
      await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/support/tickets/${t.id}/close`, {}));
      this.close();
      await this.load();
    } finally {
      this.closing.set(false);
    }
  }
}
