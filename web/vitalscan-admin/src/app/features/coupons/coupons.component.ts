import { Component, inject, signal } from '@angular/core';
import { DatePipe } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { AuthService } from '../../core/auth.service';
import { HasPermissionDirective } from '../../core/has-permission.directive';

interface Coupon {
  id: string;
  code: string;
  description?: string | null;
  type: string;
  value: number;
  maxDiscount?: number | null;
  minOrderValue?: number | null;
  totalUsageLimit?: number | null;
  perUserLimit: number;
  usedCount: number;
  validFrom?: string | null;
  validUntil?: string | null;
  isActive: boolean;
}

type Draft = Partial<Coupon>;

@Component({
  selector: 'app-coupons',
  standalone: true,
  imports: [FormsModule, DatePipe, HasPermissionDirective],
  template: `
    <div class="head">
      <h1>Coupons</h1>
      <button class="btn" *appHasPermission="'coupons.create'" (click)="openNew()">New coupon</button>
    </div>

    <div class="card">
      <table>
        <thead>
          <tr><th>Code</th><th>Type</th><th>Value</th><th>Min order</th><th>Used</th>
              <th>Valid until</th><th>Status</th><th></th></tr>
        </thead>
        <tbody>
          @for (c of coupons(); track c.id) {
            <tr>
              <td class="code">{{ c.code }}</td>
              <td>{{ c.type }}</td>
              <td>{{ c.type === 'Percentage' ? c.value + '%' : '₹' + c.value }}</td>
              <td class="muted">{{ c.minOrderValue ? '₹' + c.minOrderValue : '—' }}</td>
              <td class="muted">{{ c.usedCount }}{{ c.totalUsageLimit ? ' / ' + c.totalUsageLimit : '' }}</td>
              <td class="muted">{{ c.validUntil ? (c.validUntil | date:'mediumDate') : '—' }}</td>
              <td><span class="pill" [class.on]="c.isActive" [class.off]="!c.isActive">
                {{ c.isActive ? 'Active' : 'Inactive' }}</span></td>
              <td class="actions">
                <button class="link" *appHasPermission="'coupons.update'" (click)="openEdit(c)">Edit</button>
                <button class="link danger" *appHasPermission="'coupons.delete'"
                        [disabled]="busy()" (click)="remove(c)">Delete</button>
              </td>
            </tr>
          } @empty {
            <tr><td colspan="8" class="muted">{{ loading() ? 'Loading…' : 'No coupons yet.' }}</td></tr>
          }
        </tbody>
      </table>
    </div>

    @if (draft()) {
      <div class="overlay" (click)="close()">
        <div class="modal card" (click)="$event.stopPropagation()">
          <h2>{{ draft()!.id ? 'Edit coupon' : 'New coupon' }}</h2>
          <div class="grid">
            <div><label class="field-label">Code</label>
              <input class="input" [(ngModel)]="draft()!.code" /></div>
            <div><label class="field-label">Type</label>
              <select class="input" [(ngModel)]="draft()!.type">
                <option value="Percentage">Percentage</option>
                <option value="Flat">Flat</option>
              </select></div>
            <div><label class="field-label">Value</label>
              <input class="input" type="number" [(ngModel)]="draft()!.value" /></div>
            <div><label class="field-label">Max discount (₹)</label>
              <input class="input" type="number" [(ngModel)]="draft()!.maxDiscount" /></div>
            <div><label class="field-label">Min order (₹)</label>
              <input class="input" type="number" [(ngModel)]="draft()!.minOrderValue" /></div>
            <div><label class="field-label">Total usage limit</label>
              <input class="input" type="number" [(ngModel)]="draft()!.totalUsageLimit" /></div>
            <div><label class="field-label">Per-user limit</label>
              <input class="input" type="number" [(ngModel)]="draft()!.perUserLimit" /></div>
            <div><label class="field-label">Valid until</label>
              <input class="input" type="date" [(ngModel)]="validUntilStr" /></div>
            <div class="full"><label class="field-label">Description</label>
              <input class="input" [(ngModel)]="draft()!.description" /></div>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.isActive" /> Active</label>
          </div>
          @if (error()) { <p class="error">{{ error() }}</p> }
          <div class="foot">
            <button class="link" (click)="close()">Cancel</button>
            <button class="btn" [disabled]="saving()" (click)="save()">
              {{ saving() ? 'Saving…' : 'Save' }}</button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 0; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 12px; color: var(--text-secondary); padding: 8px 12px; border-bottom: 1px solid var(--border); }
    td { padding: 12px; border-bottom: 1px solid var(--border); font-size: 14px; }
    .code { font-weight: 700; font-family: monospace; }
    .muted { color: var(--text-secondary); }
    .actions { text-align: right; white-space: nowrap; }
    .link { background: none; border: none; color: var(--teal-700); font-weight: 600; cursor: pointer; margin-left: 10px; }
    .link.danger { color: var(--error); }
    .pill { font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 999px; }
    .pill.on { background: #e6f4f1; color: var(--teal-700); }
    .pill.off { background: #fde8e8; color: var(--error); }
    .overlay { position: fixed; inset: 0; background: rgba(15,23,42,.45); display: grid; place-items: center; z-index: 50; }
    .modal { width: 640px; max-width: 92vw; }
    .modal h2 { font-size: 20px; margin: 0 0 18px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
    .grid .full { grid-column: 1 / -1; }
    .check { display: flex; align-items: center; gap: 8px; font-size: 14px; }
    .foot { display: flex; justify-content: flex-end; align-items: center; gap: 14px; margin-top: 22px; }
    .error { color: var(--error); font-size: 13px; margin: 12px 0 0; }
  `],
})
export class CouponsComponent {
  private http = inject(HttpClient);
  protected auth = inject(AuthService);

  coupons = signal<Coupon[]>([]);
  loading = signal(false);
  saving = signal(false);
  busy = signal(false);
  error = signal('');
  draft = signal<Draft | null>(null);
  validUntilStr = '';

  constructor() {
    this.load();
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/coupons`));
      this.coupons.set((res.data ?? []) as Coupon[]);
    } catch {
      this.coupons.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  openNew(): void {
    this.error.set('');
    this.validUntilStr = '';
    this.draft.set({ type: 'Percentage', value: 0, perUserLimit: 1, isActive: true });
  }

  openEdit(c: Coupon): void {
    this.error.set('');
    this.validUntilStr = c.validUntil ? c.validUntil.substring(0, 10) : '';
    this.draft.set({ ...c });
  }

  close(): void {
    this.draft.set(null);
  }

  async save(): Promise<void> {
    const d = this.draft();
    if (!d) return;
    if (!d.code?.trim()) { this.error.set('Code is required.'); return; }

    this.saving.set(true);
    this.error.set('');
    const body = {
      code: d.code,
      description: d.description ?? null,
      type: d.type ?? 'Flat',
      value: Number(d.value) || 0,
      maxDiscount: d.maxDiscount != null ? Number(d.maxDiscount) : null,
      minOrderValue: d.minOrderValue != null ? Number(d.minOrderValue) : null,
      totalUsageLimit: d.totalUsageLimit != null ? Number(d.totalUsageLimit) : null,
      perUserLimit: Number(d.perUserLimit) || 1,
      validFrom: null,
      validUntil: this.validUntilStr ? new Date(this.validUntilStr).toISOString() : null,
      isActive: d.isActive ?? true,
    };
    try {
      if (d.id) {
        await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/coupons/${d.id}`, body));
      } else {
        await firstValueFrom(this.http.post(`${API_BASE_URL}/admin/coupons`, body));
      }
      this.close();
      await this.load();
    } catch (e: any) {
      this.error.set(e?.error?.message ?? 'Could not save the coupon.');
    } finally {
      this.saving.set(false);
    }
  }

  async remove(c: Coupon): Promise<void> {
    this.busy.set(true);
    try {
      await firstValueFrom(this.http.delete(`${API_BASE_URL}/admin/coupons/${c.id}`));
      this.coupons.update(list => list.filter(x => x.id !== c.id));
    } finally {
      this.busy.set(false);
    }
  }
}
