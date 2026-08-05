import { Component, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { AuthService } from '../../core/auth.service';

interface ConfigRow {
  id: string;
  key: string;
  value: string;
  valueType: string;
  category: string | null;
  description?: string | null;
  isPublic: boolean;
  dirty: boolean;
}

interface Group { category: string; rows: ConfigRow[]; }

/**
 * App config key/value editor. Reads /admin/config, groups rows by category and
 * writes changed keys back via /admin/config/{key}.
 */
@Component({
  selector: 'app-config',
  standalone: true,
  imports: [FormsModule],
  template: `
    <div class="head">
      <h1>App Config</h1>
      <span class="muted">Runtime configuration — grouped by category</span>
    </div>

    <div class="card">
      @if (rows().length === 0) {
        <p class="muted">{{ loading() ? 'Loading…' : 'No configuration keys found.' }}</p>
      }

      @for (g of groups(); track g.category) {
        <div class="group">
          <h2>{{ g.category }}</h2>
          @for (r of g.rows; track r.key) {
            <div class="row">
              <div class="meta">
                <span class="key">{{ r.key }}</span>
                @if (r.description) { <span class="desc muted">{{ r.description }}</span> }
              </div>
              <div class="control">
                @if (r.valueType === 'bool') {
                  <label class="check">
                    <input type="checkbox" [checked]="r.value === 'true'"
                           (change)="setBool(r, $event)" /> {{ r.value === 'true' ? 'On' : 'Off' }}
                  </label>
                } @else if (r.valueType === 'color') {
                  <input type="color" class="swatch" [(ngModel)]="r.value" (ngModelChange)="mark(r)" />
                  <input class="input" [(ngModel)]="r.value" (ngModelChange)="mark(r)" />
                } @else {
                  <input class="input" [(ngModel)]="r.value" (ngModelChange)="mark(r)" />
                }
              </div>
            </div>
          }
        </div>
      }

      @if (canEdit()) {
        <div class="foot">
          @if (saved()) { <span class="ok">Saved ✓</span> }
          <button class="btn" [disabled]="!anyDirty() || saving()" (click)="save()">
            {{ saving() ? 'Saving…' : 'Save changes' }}
          </button>
        </div>
      } @else {
        <p class="muted small">You have read-only access to app config.</p>
      }
    </div>
  `,
  styles: [`
    .head { margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 0 0 4px; }
    h2 { font-size: 15px; text-transform: uppercase; letter-spacing: .04em; color: var(--text-secondary); margin: 0 0 6px; }
    .muted { color: var(--text-secondary); }
    .muted.small { font-size: 13px; margin-top: 16px; }
    .group { margin-bottom: 22px; }
    .row { display: grid; grid-template-columns: 320px 1fr; align-items: center; gap: 16px;
           padding: 12px 0; border-bottom: 1px solid var(--border); }
    .meta { display: flex; flex-direction: column; gap: 3px; }
    .key { font-family: monospace; font-size: 14px; font-weight: 600; }
    .desc { font-size: 12px; }
    .control { display: flex; align-items: center; gap: 10px; }
    .check { display: flex; align-items: center; gap: 8px; font-size: 14px; }
    .swatch { width: 44px; height: 38px; border: 1px solid var(--border); border-radius: 8px; padding: 2px; background: #fff; }
    .foot { display: flex; align-items: center; justify-content: flex-end; gap: 14px; margin-top: 20px; }
    .ok { color: var(--teal-700); font-weight: 600; font-size: 14px; }
  `],
})
export class ConfigComponent {
  private http = inject(HttpClient);
  private auth = inject(AuthService);

  rows = signal<ConfigRow[]>([]);
  loading = signal(false);
  saving = signal(false);
  saved = signal(false);

  groups = computed<Group[]>(() => {
    const map = new Map<string, ConfigRow[]>();
    for (const r of this.rows()) {
      const cat = r.category ?? 'General';
      if (!map.has(cat)) map.set(cat, []);
      map.get(cat)!.push(r);
    }
    return Array.from(map.entries()).map(([category, rows]) => ({ category, rows }));
  });

  constructor() {
    this.load();
  }

  canEdit = () => this.auth.hasPermission('config.update');
  anyDirty = () => this.rows().some(r => r.dirty);

  mark(r: ConfigRow): void {
    r.dirty = true;
    this.saved.set(false);
  }

  setBool(r: ConfigRow, event: Event): void {
    r.value = (event.target as HTMLInputElement).checked ? 'true' : 'false';
    this.mark(r);
    this.rows.update(list => [...list]);
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/config`));
      const list = (res.data ?? res ?? []) as any[];
      this.rows.set(list.map(r => ({
        id: r.id,
        key: r.key,
        value: r.value ?? '',
        valueType: r.valueType ?? 'string',
        category: r.category ?? null,
        description: r.description ?? null,
        isPublic: !!r.isPublic,
        dirty: false,
      })));
    } catch {
      this.rows.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  async save(): Promise<void> {
    this.saving.set(true);
    try {
      const dirty = this.rows().filter(r => r.dirty);
      for (const r of dirty) {
        await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/config/${r.key}`, { value: r.value }));
      }
      this.rows.update(list => list.map(r => ({ ...r, dirty: false })));
      this.saved.set(true);
    } finally {
      this.saving.set(false);
    }
  }
}
