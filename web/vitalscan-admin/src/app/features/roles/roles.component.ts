import { Component, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { HasPermissionDirective } from '../../core/has-permission.directive';

interface Role { id: string; name: string; description?: string; isSystem: boolean; }

@Component({
  selector: 'app-roles',
  standalone: true,
  imports: [HasPermissionDirective],
  template: `
    <div class="head">
      <h1>Roles &amp; Permissions</h1>
      <button class="btn" *appHasPermission="'roles.create'">New role</button>
    </div>
    <div class="card">
      <table>
        <thead><tr><th>Role</th><th>Type</th><th>Description</th><th></th></tr></thead>
        <tbody>
          @for (r of roles(); track r.id) {
            <tr>
              <td class="name">{{ r.name }}</td>
              <td>{{ r.isSystem ? 'System' : 'Custom' }}</td>
              <td class="muted">{{ r.description || '—' }}</td>
              <td class="actions">
                @if (!r.isSystem) {
                  <button class="link" *appHasPermission="'roles.update'">Edit</button>
                } @else {
                  <span class="muted">Locked</span>
                }
              </td>
            </tr>
          } @empty {
            <tr><td colspan="4" class="muted">No roles loaded.</td></tr>
          }
        </tbody>
      </table>
    </div>
  `,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 0; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 12px; color: var(--text-secondary); padding: 8px 12px; border-bottom: 1px solid var(--border); }
    td { padding: 12px; border-bottom: 1px solid var(--border); font-size: 14px; }
    .name { font-weight: 600; text-transform: capitalize; }
    .muted { color: var(--text-secondary); }
    .actions { text-align: right; }
    .link { background: none; border: none; color: var(--teal-700); font-weight: 600; }
  `],
})
export class RolesComponent {
  private http = inject(HttpClient);
  roles = signal<Role[]>([]);

  constructor() {
    this.load();
  }

  private async load(): Promise<void> {
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/roles`));
      this.roles.set((res.data ?? res) as Role[]);
    } catch {
      this.roles.set([]);
    }
  }
}
