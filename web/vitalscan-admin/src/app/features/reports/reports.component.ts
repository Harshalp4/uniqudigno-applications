import { Component, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';

interface StatusCount { status: string; count: number; }

interface Summary {
  totalUsers: number;
  totalBookings: number;
  bookingsToday: number;
  revenueTotal: number;
  revenueThisMonth: number;
  openTickets: number;
  pendingRefunds: number;
  activeCoupons: number;
  bookingsByStatus: StatusCount[];
}

@Component({
  selector: 'app-reports',
  standalone: true,
  imports: [],
  template: `
    <div class="head">
      <h1>Reports</h1>
      <span class="muted">Analytics overview across the platform</span>
    </div>

    @if (!summary()) {
      <div class="card">
        <p class="muted">{{ loading() ? 'Loading…' : 'No analytics available.' }}</p>
      </div>
    } @else {
      <div class="stats">
        <div class="stat card"><div class="stat-label">Total Users</div><div class="stat-value">{{ summary()!.totalUsers }}</div></div>
        <div class="stat card"><div class="stat-label">Total Bookings</div><div class="stat-value">{{ summary()!.totalBookings }}</div></div>
        <div class="stat card"><div class="stat-label">Bookings Today</div><div class="stat-value">{{ summary()!.bookingsToday }}</div></div>
        <div class="stat card"><div class="stat-label">Revenue (Total)</div><div class="stat-value">₹{{ summary()!.revenueTotal }}</div></div>
        <div class="stat card"><div class="stat-label">Revenue (This Month)</div><div class="stat-value">₹{{ summary()!.revenueThisMonth }}</div></div>
        <div class="stat card"><div class="stat-label">Open Tickets</div><div class="stat-value">{{ summary()!.openTickets }}</div></div>
        <div class="stat card"><div class="stat-label">Pending Refunds</div><div class="stat-value">{{ summary()!.pendingRefunds }}</div></div>
        <div class="stat card"><div class="stat-label">Active Coupons</div><div class="stat-value">{{ summary()!.activeCoupons }}</div></div>
      </div>

      <div class="card">
        <h2>Bookings by status</h2>
        @for (b of summary()!.bookingsByStatus; track b.status) {
          <div class="bar-row">
            <div class="bar-label">{{ b.status }}</div>
            <div class="bar-track">
              <div class="bar-fill" [style.width.%]="pct(b.count)"></div>
            </div>
            <div class="bar-count">{{ b.count }}</div>
          </div>
        } @empty {
          <p class="muted">No bookings yet.</p>
        }
      </div>
    }
  `,
  styles: [`
    .head { margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 0 0 4px; }
    h2 { font-size: 18px; margin: 0 0 16px; }
    .muted { color: var(--text-secondary); }
    .stats { display: grid; grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); gap: 16px; margin-bottom: 20px; }
    .stat { padding: 18px 20px; }
    .stat-label { font-size: 13px; color: var(--text-secondary); margin-bottom: 8px; }
    .stat-value { font-size: 26px; font-weight: 700; color: var(--teal-700); }
    .bar-row { display: grid; grid-template-columns: 160px 1fr 60px; align-items: center; gap: 14px; padding: 8px 0; }
    .bar-label { font-size: 14px; }
    .bar-track { background: #eef2f6; border-radius: 999px; height: 12px; overflow: hidden; }
    .bar-fill { background: var(--teal-700); height: 100%; border-radius: 999px; min-width: 2px; }
    .bar-count { text-align: right; font-size: 14px; font-weight: 600; }
  `],
})
export class ReportsComponent {
  private http = inject(HttpClient);

  summary = signal<Summary | null>(null);
  loading = signal(false);

  maxCount = computed(() => {
    const s = this.summary();
    if (!s) return 0;
    return Math.max(1, ...s.bookingsByStatus.map(b => b.count));
  });

  constructor() {
    this.load();
  }

  pct(count: number): number {
    return Math.round((count / this.maxCount()) * 100);
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/analytics/summary`));
      const data = (res.data ?? res) as Summary;
      this.summary.set({ ...data, bookingsByStatus: data.bookingsByStatus ?? [] });
    } catch {
      this.summary.set(null);
    } finally {
      this.loading.set(false);
    }
  }
}
