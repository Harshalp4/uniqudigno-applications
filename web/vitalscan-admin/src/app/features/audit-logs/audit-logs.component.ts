import { Component, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';

interface SecurityEvent {
  id: string;
  eventType: string;
  severity: string;
  ipAddress?: string | null;
  details?: string | null;
  resolved: boolean;
  createdAt: string;
}

/** Security events / audit trail (Section 11) — read + resolve. */
@Component({
  selector: 'app-audit-logs',
  standalone: true,
  imports: [FormsModule, DatePipe],
  template: `
    <div class="head">
      <h1>Audit Logs</h1>
      <label class="toggle"><input type="checkbox" [(ngModel)]="unresolvedOnly" /> Unresolved only</label>
    </div>

    <div class="card">
      <table>
        <thead>
          <tr><th>When</th><th>Event</th><th>Severity</th><th>IP</th><th>Details</th><th></th></tr>
        </thead>
        <tbody>
          @for (e of visible(); track e.id) {
            <tr [class.resolved]="e.resolved">
              <td class="muted">{{ e.createdAt | date:'medium' }}</td>
              <td class="name">{{ label(e.eventType) }}</td>
              <td><span class="pill" [attr.data-sev]="e.severity">{{ e.severity }}</span></td>
              <td class="muted">{{ e.ipAddress || '—' }}</td>
              <td class="details muted">{{ e.details || '—' }}</td>
              <td class="actions">
                @if (e.resolved) {
                  <span class="muted">Resolved</span>
                } @else {
                  <button class="link" [disabled]="busy() === e.id" (click)="resolve(e)">Resolve</button>
                }
              </td>
            </tr>
          } @empty {
            <tr><td colspan="6" class="muted">{{ loading() ? 'Loading…' : 'No security events.' }}</td></tr>
          }
        </tbody>
      </table>
    </div>
  `,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 0; }
    .toggle { display: flex; align-items: center; gap: 8px; font-size: 14px; color: var(--text-secondary); }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 12px; color: var(--text-secondary); padding: 8px 12px; border-bottom: 1px solid var(--border); }
    td { padding: 12px; border-bottom: 1px solid var(--border); font-size: 14px; vertical-align: top; }
    tr.resolved { opacity: 0.55; }
    .name { font-weight: 600; }
    .muted { color: var(--text-secondary); }
    .details { max-width: 320px; font-family: monospace; font-size: 12px; word-break: break-all; }
    .actions { text-align: right; }
    .link { background: none; border: none; color: var(--teal-700); font-weight: 600; cursor: pointer; }
    .pill { font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 999px; background: #eef2f6; color: var(--text-secondary); }
    .pill[data-sev="High"] { background: #fff4e5; color: #b26a00; }
    .pill[data-sev="Critical"] { background: #fde8e8; color: var(--error); }
  `],
})
export class AuditLogsComponent {
  private http = inject(HttpClient);

  events = signal<SecurityEvent[]>([]);
  loading = signal(false);
  busy = signal<string | null>(null);
  unresolvedOnly = false;

  visible = computed(() =>
    this.unresolvedOnly ? this.events().filter(e => !e.resolved) : this.events());

  constructor() {
    this.load();
  }

  label(s: string): string {
    return s.replace(/([a-z])([A-Z])/g, '$1 $2');
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/security/events`));
      this.events.set((res.data ?? []) as SecurityEvent[]);
    } catch {
      this.events.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  async resolve(e: SecurityEvent): Promise<void> {
    this.busy.set(e.id);
    try {
      await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/security/events/${e.id}/resolve`, {}));
      this.events.update(list => list.map(x => x.id === e.id ? { ...x, resolved: true } : x));
    } finally {
      this.busy.set(null);
    }
  }
}
