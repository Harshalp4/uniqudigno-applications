import { Component, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { AuthService } from '../../core/auth.service';

interface Field { key: string; value: string; dirty: boolean; }

/**
 * White-label branding editor (Section 5 — zero hardcoding). Reads the public
 * branding config and writes changed keys back via /admin/config/{key}.
 */
@Component({
  selector: 'app-branding',
  standalone: true,
  imports: [FormsModule],
  template: `
    <div class="head">
      <h1>Branding</h1>
      <span class="muted">White-label theme &amp; identity — applied across all apps</span>
    </div>

    <div class="card">
      @if (fields().length === 0) {
        <p class="muted">{{ loading() ? 'Loading…' : 'No branding keys configured yet.' }}</p>
      }
      @for (f of fields(); track f.key) {
        <div class="row">
          <label class="field-label">{{ pretty(f.key) }}</label>
          <div class="control">
            @if (isColor(f.key)) {
              <input type="color" class="swatch" [(ngModel)]="f.value" (ngModelChange)="mark(f)" />
            }
            <input class="input" [(ngModel)]="f.value" (ngModelChange)="mark(f)" />
          </div>
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
        <p class="muted small">You have read-only access to branding.</p>
      }
    </div>
  `,
  styles: [`
    .head { margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 0 0 4px; }
    .muted { color: var(--text-secondary); }
    .muted.small { font-size: 13px; margin-top: 16px; }
    .row { display: grid; grid-template-columns: 220px 1fr; align-items: center; gap: 16px;
           padding: 12px 0; border-bottom: 1px solid var(--border); }
    .control { display: flex; align-items: center; gap: 10px; }
    .swatch { width: 44px; height: 38px; border: 1px solid var(--border); border-radius: 8px; padding: 2px; background: #fff; }
    .foot { display: flex; align-items: center; justify-content: flex-end; gap: 14px; margin-top: 20px; }
    .ok { color: var(--teal-700); font-weight: 600; font-size: 14px; }
  `],
})
export class BrandingComponent {
  private http = inject(HttpClient);
  private auth = inject(AuthService);

  fields = signal<Field[]>([]);
  loading = signal(false);
  saving = signal(false);
  saved = signal(false);

  constructor() {
    this.load();
  }

  canEdit = () => this.auth.hasPermission('config.update');
  anyDirty = () => this.fields().some(f => f.dirty);
  isColor = (k: string) => /colou?r/i.test(k);
  pretty = (k: string) => k.replace(/[_.]/g, ' ').replace(/\b\w/g, c => c.toUpperCase());

  mark(f: Field): void {
    f.dirty = true;
    this.saved.set(false);
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/config/branding`));
      const dict = (res.data ?? res ?? {}) as Record<string, string>;
      this.fields.set(Object.entries(dict).map(([key, value]) => ({ key, value: value ?? '', dirty: false })));
    } catch {
      this.fields.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  async save(): Promise<void> {
    this.saving.set(true);
    try {
      const dirty = this.fields().filter(f => f.dirty);
      for (const f of dirty) {
        await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/config/${f.key}`, { value: f.value }));
      }
      this.fields.update(list => list.map(f => ({ ...f, dirty: false })));
      this.saved.set(true);
    } finally {
      this.saving.set(false);
    }
  }
}
