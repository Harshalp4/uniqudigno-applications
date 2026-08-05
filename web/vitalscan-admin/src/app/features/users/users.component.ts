import { Component, computed, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { HasPermissionDirective } from '../../core/has-permission.directive';

interface AdminUser {
  id: string;
  name?: string | null;
  mobile: string;
  email?: string | null;
  isActive: boolean;
  createdAt?: string;
}

@Component({
  selector: 'app-users',
  standalone: true,
  imports: [FormsModule, DatePipe, HasPermissionDirective],
  template: `
    <div class="head">
      <h1>Users</h1>
      <input class="input search" placeholder="Search name, mobile, email…"
             [(ngModel)]="term" />
    </div>

    <div class="card">
      <table>
        <thead>
          <tr><th>Name</th><th>Mobile</th><th>Email</th><th>Status</th><th>Joined</th><th></th></tr>
        </thead>
        <tbody>
          @for (u of filtered(); track u.id) {
            <tr>
              <td class="name">{{ u.name || '—' }}</td>
              <td>{{ u.mobile }}</td>
              <td class="muted">{{ u.email || '—' }}</td>
              <td>
                <span class="pill" [class.on]="u.isActive" [class.off]="!u.isActive">
                  {{ u.isActive ? 'Active' : 'Inactive' }}
                </span>
              </td>
              <td class="muted">{{ u.createdAt ? (u.createdAt | date:'mediumDate') : '—' }}</td>
              <td class="actions">
                <button class="link" *appHasPermission="'users.update'"
                        [disabled]="busy() === u.id" (click)="toggle(u)">
                  {{ u.isActive ? 'Deactivate' : 'Activate' }}
                </button>
              </td>
            </tr>
          } @empty {
            <tr><td colspan="6" class="muted">{{ loading() ? 'Loading…' : 'No users found.' }}</td></tr>
          }
        </tbody>
      </table>

      <div class="pager">
        <span class="muted">Page {{ page() }} of {{ totalPages() }} · {{ total() }} users</span>
        <span class="spacer"></span>
        <button class="link" [disabled]="page() <= 1" (click)="go(page() - 1)">‹ Prev</button>
        <button class="link" [disabled]="page() >= totalPages()" (click)="go(page() + 1)">Next ›</button>
      </div>
    </div>
  `,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; gap: 16px; }
    h1 { font-size: 24px; margin: 0; }
    .search { max-width: 320px; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 12px; color: var(--text-secondary); padding: 8px 12px; border-bottom: 1px solid var(--border); }
    td { padding: 12px; border-bottom: 1px solid var(--border); font-size: 14px; }
    .name { font-weight: 600; }
    .muted { color: var(--text-secondary); }
    .actions { text-align: right; }
    .link { background: none; border: none; color: var(--teal-700); font-weight: 600; cursor: pointer; }
    .link:disabled { color: var(--text-secondary); cursor: default; }
    .pill { font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 999px; }
    .pill.on { background: #e6f4f1; color: var(--teal-700); }
    .pill.off { background: #fde8e8; color: var(--error); }
    .pager { display: flex; align-items: center; gap: 12px; padding: 14px 12px 4px; font-size: 13px; }
    .spacer { flex: 1; }
  `],
})
export class UsersComponent {
  private http = inject(HttpClient);

  users = signal<AdminUser[]>([]);
  page = signal(1);
  pageSize = signal(20);
  total = signal(0);
  loading = signal(false);
  busy = signal<string | null>(null);
  term = '';

  totalPages = computed(() => Math.max(1, Math.ceil(this.total() / this.pageSize())));
  filtered = computed(() => {
    const t = this.term.trim().toLowerCase();
    if (!t) return this.users();
    return this.users().filter(u =>
      (u.name ?? '').toLowerCase().includes(t) ||
      u.mobile.toLowerCase().includes(t) ||
      (u.email ?? '').toLowerCase().includes(t));
  });

  constructor() {
    this.load();
  }

  go(p: number): void {
    this.page.set(p);
    this.load();
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(
        `${API_BASE_URL}/admin/users?page=${this.page()}&pageSize=${this.pageSize()}`));
      this.users.set((res.data ?? []) as AdminUser[]);
      this.total.set(res.pagination?.total ?? this.users().length);
      this.pageSize.set(res.pagination?.pageSize ?? this.pageSize());
    } catch {
      this.users.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  async toggle(u: AdminUser): Promise<void> {
    this.busy.set(u.id);
    try {
      await firstValueFrom(this.http.put(
        `${API_BASE_URL}/admin/users/${u.id}/status`, { active: !u.isActive }));
      this.users.update(list => list.map(x => x.id === u.id ? { ...x, isActive: !x.isActive } : x));
    } catch {
      // leave state unchanged on failure
    } finally {
      this.busy.set(null);
    }
  }
}
