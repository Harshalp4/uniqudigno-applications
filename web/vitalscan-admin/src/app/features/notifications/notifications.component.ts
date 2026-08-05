import { Component, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { HasPermissionDirective } from '../../core/has-permission.directive';

interface Notification {
  id: string;
  title: string;
  body: string;
  channel: string;
  status: string;
  createdAt: string;
}

@Component({
  selector: 'app-notifications',
  standalone: true,
  imports: [FormsModule, DatePipe, HasPermissionDirective],
  template: `
    <div class="head">
      <h1>Notifications</h1>
      <span class="muted">Broadcast to users &amp; review recent sends</span>
    </div>

    <div class="cols">
      <div class="compose" *appHasPermission="'notifications.broadcast'">
        <div class="card">
          <h2>Compose broadcast</h2>
          <label class="field-label">Title</label>
          <input class="input" [(ngModel)]="title" />
          <label class="field-label">Body</label>
          <textarea class="input" rows="4" [(ngModel)]="body"></textarea>
          <label class="field-label">Deep link (optional)</label>
          <input class="input" placeholder="app://…" [(ngModel)]="deepLink" />
          @if (error()) { <p class="error">{{ error() }}</p> }
          <div class="foot">
            @if (sent()) { <span class="ok">{{ sent() }}</span> }
            <button class="btn" [disabled]="sending() || !title.trim() || !body.trim()" (click)="send()">
              {{ sending() ? 'Sending…' : 'Send broadcast' }}
            </button>
          </div>
        </div>
      </div>

      <div class="card recent">
        <h2>Recent</h2>
        @for (n of items(); track n.id) {
          <div class="item">
            <div class="row1">
              <span class="title">{{ n.title }}</span>
              <span class="when muted">{{ n.createdAt | date:'short' }}</span>
            </div>
            <div class="body muted">{{ n.body }}</div>
          </div>
        } @empty {
          <p class="muted">{{ loading() ? 'Loading…' : 'No notifications yet.' }}</p>
        }
      </div>
    </div>
  `,
  styles: [`
    .head { margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 0 0 4px; }
    h2 { font-size: 18px; margin: 0 0 16px; }
    .muted { color: var(--text-secondary); }
    .cols { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; align-items: start; }
    .field-label { display: block; margin: 14px 0 6px; }
    .field-label:first-of-type { margin-top: 0; }
    textarea.input { resize: vertical; }
    .foot { display: flex; align-items: center; justify-content: flex-end; gap: 14px; margin-top: 18px; }
    .ok { color: var(--teal-700); font-weight: 600; font-size: 14px; }
    .error { color: var(--error); font-size: 13px; margin: 12px 0 0; }
    .item { padding: 12px 0; border-bottom: 1px solid var(--border); }
    .row1 { display: flex; justify-content: space-between; align-items: baseline; gap: 12px; }
    .title { font-weight: 600; font-size: 14px; }
    .when { font-size: 12px; white-space: nowrap; }
    .body { font-size: 13px; margin-top: 4px; }
  `],
})
export class NotificationsComponent {
  private http = inject(HttpClient);

  items = signal<Notification[]>([]);
  loading = signal(false);
  sending = signal(false);
  sent = signal('');
  error = signal('');

  title = '';
  body = '';
  deepLink = '';

  constructor() {
    this.load();
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/notifications/recent?take=50`));
      this.items.set((res.data ?? []) as Notification[]);
    } catch {
      this.items.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  async send(): Promise<void> {
    if (!this.title.trim() || !this.body.trim()) return;
    this.sending.set(true);
    this.sent.set('');
    this.error.set('');
    try {
      const res = await firstValueFrom(this.http.post<any>(`${API_BASE_URL}/admin/notifications/broadcast`, {
        title: this.title,
        body: this.body,
        deepLink: this.deepLink || null,
      }));
      const data = res.data ?? res;
      this.sent.set(res.message ?? `Sent to ${data?.recipients ?? 0} user(s)`);
      this.title = '';
      this.body = '';
      this.deepLink = '';
      await this.load();
    } catch (e: any) {
      this.error.set(e?.error?.message ?? 'Could not send the broadcast.');
    } finally {
      this.sending.set(false);
    }
  }
}
