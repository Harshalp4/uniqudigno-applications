import { Component, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { HasPermissionDirective } from '../../core/has-permission.directive';

interface Refund {
  id: string;
  bookingNumber: string;
  customer: string;
  amount: number;
  method: string;
  status: string;
  reason?: string | null;
  createdAt: string;
  processedAt?: string | null;
}

const STATUSES = ['Requested', 'Approved', 'Processing', 'Completed', 'Rejected'];

@Component({
  selector: 'app-refunds',
  standalone: true,
  imports: [FormsModule, DatePipe, HasPermissionDirective],
  template: `
    <div class="head">
      <h1>Refunds</h1>
      <select class="input filter" [(ngModel)]="status" (ngModelChange)="load()">
        <option value="">All statuses</option>
        @for (s of statuses; track s) { <option [value]="s">{{ s }}</option> }
      </select>
    </div>

    <div class="card">
      <table>
        <thead>
          <tr><th>Booking</th><th>Customer</th><th class="r">Amount</th><th>Method</th>
              <th>Requested</th><th>Status</th><th></th></tr>
        </thead>
        <tbody>
          @for (r of refunds(); track r.id) {
            <tr>
              <td class="name">{{ r.bookingNumber }}</td>
              <td class="muted">{{ r.customer }}</td>
              <td class="r">₹{{ r.amount }}</td>
              <td class="muted">{{ label(r.method) }}</td>
              <td class="muted">{{ r.createdAt | date:'mediumDate' }}</td>
              <td><span class="pill" [attr.data-s]="r.status">{{ r.status }}</span></td>
              <td class="actions">
                @if (r.status !== 'Completed' && r.status !== 'Rejected') {
                  <button class="link" *appHasPermission="'refunds.process'"
                          [disabled]="busy() === r.id" (click)="process(r)">Process</button>
                  <button class="link danger" *appHasPermission="'refunds.process'"
                          [disabled]="busy() === r.id" (click)="reject(r)">Reject</button>
                } @else {
                  <span class="muted">{{ r.processedAt ? (r.processedAt | date:'mediumDate') : '—' }}</span>
                }
              </td>
            </tr>
          } @empty {
            <tr><td colspan="7" class="muted">{{ loading() ? 'Loading…' : 'No refunds found.' }}</td></tr>
          }
        </tbody>
      </table>
    </div>
  `,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 0; }
    .filter { max-width: 200px; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 12px; color: var(--text-secondary); padding: 8px 12px; border-bottom: 1px solid var(--border); }
    th.r, td.r { text-align: right; }
    td { padding: 12px; border-bottom: 1px solid var(--border); font-size: 14px; }
    .name { font-weight: 600; font-family: monospace; }
    .muted { color: var(--text-secondary); }
    .actions { text-align: right; white-space: nowrap; }
    .link { background: none; border: none; color: var(--teal-700); font-weight: 600; cursor: pointer; margin-left: 10px; }
    .link.danger { color: var(--error); }
    .pill { font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 999px; background: #eef2f6; color: var(--text-secondary); }
    .pill[data-s="Completed"] { background: #e6f4f1; color: var(--teal-700); }
    .pill[data-s="Rejected"] { background: #fde8e8; color: var(--error); }
    .pill[data-s="Requested"] { background: #fff4e5; color: #b26a00; }
  `],
})
export class RefundsComponent {
  private http = inject(HttpClient);

  refunds = signal<Refund[]>([]);
  loading = signal(false);
  busy = signal<string | null>(null);
  status = '';
  statuses = STATUSES;

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
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/refunds${q}`));
      this.refunds.set((res.data ?? []) as Refund[]);
    } catch {
      this.refunds.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  async process(r: Refund): Promise<void> {
    this.busy.set(r.id);
    try {
      await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/refunds/${r.id}/process`, {}));
      this.patch(r.id, 'Completed');
    } finally {
      this.busy.set(null);
    }
  }

  async reject(r: Refund): Promise<void> {
    this.busy.set(r.id);
    try {
      await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/refunds/${r.id}/reject`, { reason: null }));
      this.patch(r.id, 'Rejected');
    } finally {
      this.busy.set(null);
    }
  }

  private patch(id: string, status: string): void {
    const now = new Date().toISOString();
    this.refunds.update(list => list.map(x => x.id === id ? { ...x, status, processedAt: now } : x));
  }
}
