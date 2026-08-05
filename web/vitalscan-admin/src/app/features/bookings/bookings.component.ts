import { Component, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';

interface AdminBooking {
  id: string;
  bookingNumber: string;
  customer: string;
  status: string;
  scheduledDate: string;
  scheduledTime?: string | null;
  amountPayable: number;
  technicianAssigned: boolean;
  createdAt?: string;
}

const STATUSES = [
  'Pending', 'Confirmed', 'TechnicianAssigned', 'SampleCollected', 'InLab',
  'ReportReady', 'Completed', 'Cancelled', 'Rescheduled', 'NoShow',
];

@Component({
  selector: 'app-bookings',
  standalone: true,
  imports: [FormsModule, DatePipe],
  template: `
    <div class="head">
      <h1>Bookings</h1>
      <select class="input filter" [(ngModel)]="status" (ngModelChange)="go(1)">
        <option value="">All statuses</option>
        @for (s of statuses; track s) { <option [value]="s">{{ label(s) }}</option> }
      </select>
    </div>

    <div class="card">
      <table>
        <thead>
          <tr><th>Booking</th><th>Customer</th><th>Status</th><th>Scheduled</th>
              <th>Technician</th><th class="r">Payable</th></tr>
        </thead>
        <tbody>
          @for (b of bookings(); track b.id) {
            <tr>
              <td class="name">{{ b.bookingNumber }}</td>
              <td class="muted">{{ b.customer }}</td>
              <td><span class="pill" [attr.data-s]="b.status">{{ label(b.status) }}</span></td>
              <td>{{ b.scheduledDate | date:'mediumDate' }}<span class="muted">{{ b.scheduledTime ? ' · ' + b.scheduledTime : '' }}</span></td>
              <td>{{ b.technicianAssigned ? 'Assigned' : '—' }}</td>
              <td class="r">₹{{ b.amountPayable }}</td>
            </tr>
          } @empty {
            <tr><td colspan="6" class="muted">{{ loading() ? 'Loading…' : 'No bookings found.' }}</td></tr>
          }
        </tbody>
      </table>

      <div class="pager">
        <span class="muted">Page {{ page() }} of {{ totalPages() }} · {{ total() }} bookings</span>
        <span class="spacer"></span>
        <button class="link" [disabled]="page() <= 1" (click)="go(page() - 1)">‹ Prev</button>
        <button class="link" [disabled]="page() >= totalPages()" (click)="go(page() + 1)">Next ›</button>
      </div>
    </div>
  `,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; gap: 16px; }
    h1 { font-size: 24px; margin: 0; }
    .filter { max-width: 220px; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 12px; color: var(--text-secondary); padding: 8px 12px; border-bottom: 1px solid var(--border); }
    th.r, td.r { text-align: right; }
    td { padding: 12px; border-bottom: 1px solid var(--border); font-size: 14px; }
    .name { font-weight: 600; font-family: monospace; }
    .muted { color: var(--text-secondary); }
    .pill { font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 999px; background: #eef2f6; color: var(--text-secondary); }
    .pill[data-s="Completed"], .pill[data-s="ReportReady"] { background: #e6f4f1; color: var(--teal-700); }
    .pill[data-s="Cancelled"], .pill[data-s="NoShow"] { background: #fde8e8; color: var(--error); }
    .pill[data-s="Pending"] { background: #fff4e5; color: #b26a00; }
    .link { background: none; border: none; color: var(--teal-700); font-weight: 600; cursor: pointer; }
    .link:disabled { color: var(--text-secondary); cursor: default; }
    .pager { display: flex; align-items: center; gap: 12px; padding: 14px 12px 4px; font-size: 13px; }
    .spacer { flex: 1; }
  `],
})
export class BookingsComponent {
  private http = inject(HttpClient);

  bookings = signal<AdminBooking[]>([]);
  page = signal(1);
  pageSize = signal(20);
  total = signal(0);
  loading = signal(false);
  status = '';
  statuses = STATUSES;

  totalPages = computed(() => Math.max(1, Math.ceil(this.total() / this.pageSize())));

  constructor() {
    this.load();
  }

  label(s: string): string {
    return s.replace(/([a-z])([A-Z])/g, '$1 $2');
  }

  go(p: number): void {
    this.page.set(Math.max(1, p));
    this.load();
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const q = `page=${this.page()}&pageSize=${this.pageSize()}` + (this.status ? `&status=${this.status}` : '');
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/bookings?${q}`));
      this.bookings.set((res.data ?? []) as AdminBooking[]);
      this.total.set(res.pagination?.total ?? this.bookings().length);
      this.pageSize.set(res.pagination?.pageSize ?? this.pageSize());
    } catch {
      this.bookings.set([]);
    } finally {
      this.loading.set(false);
    }
  }
}
