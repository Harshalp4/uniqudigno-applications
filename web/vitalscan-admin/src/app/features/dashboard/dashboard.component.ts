import { Component, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';

@Component({
  selector: 'app-dashboard',
  standalone: true,
  template: `
    <h1>Dashboard</h1>
    <div class="kpis">
      @for (k of kpis(); track k.label) {
        <div class="card kpi">
          <div class="kpi-label">{{ k.label }}</div>
          <div class="kpi-value">{{ k.value }}</div>
        </div>
      }
    </div>
    <div class="card chart-placeholder">Revenue & bookings charts (ApexCharts) render here.</div>
  `,
  styles: [`
    h1 { font-size: 24px; margin: 0 0 20px; }
    .kpis { display: grid; grid-template-columns: repeat(4, 1fr); gap: 16px; margin-bottom: 16px; }
    .kpi-label { color: var(--text-secondary); font-size: 13px; }
    .kpi-value { font-size: 28px; font-weight: 800; margin-top: 8px; }
    .chart-placeholder { height: 280px; display: grid; place-items: center; color: var(--text-secondary); }
  `],
})
export class DashboardComponent {
  private http = inject(HttpClient);
  kpis = signal([
    { label: 'Bookings today', value: '—' },
    { label: 'Revenue (₹)', value: '—' },
    { label: 'Active users', value: '—' },
    { label: 'Pending reports', value: '—' },
  ]);

  constructor() {
    this.load();
  }

  private async load(): Promise<void> {
    try {
      const res = await firstValueFrom(
        this.http.get<any>(`${API_BASE_URL}/admin/dashboard`),
      );
      const d = res.data ?? res;
      this.kpis.set([
        { label: 'Bookings today', value: (d.bookingsToday ?? 0).toString() },
        { label: 'Revenue (₹)', value: (d.revenue ?? 0).toString() },
        { label: 'Active users', value: (d.activeUsers ?? 0).toString() },
        { label: 'Pending reports', value: (d.pendingReports ?? 0).toString() },
      ]);
    } catch {
      /* keep placeholder values when the API is unreachable */
    }
  }
}
