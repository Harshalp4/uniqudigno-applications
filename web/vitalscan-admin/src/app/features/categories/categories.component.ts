import { Component, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { HasPermissionDirective } from '../../core/has-permission.directive';

interface Category {
  id: string;
  name: string;
  slug: string;
  type: string;
  iconUrl?: string | null;
  showInFilter: boolean;
  sortOrder: number;
  isActive: boolean;
}

type Draft = Partial<Category>;

/** Category master — the filter-chip config behind the home package rail. */
@Component({
  selector: 'app-categories',
  standalone: true,
  imports: [FormsModule, HasPermissionDirective],
  template: `
    <div class="head">
      <h1>Categories</h1>
      <button class="btn" *appHasPermission="'categories.create'" (click)="openNew()">New category</button>
    </div>
    <p class="muted sub">Categories power the home rails: <b>Package</b> = filter chips,
      <b>Organ</b> / <b>Concern</b> / <b>Persona</b> = the browse rails that open a category
      landing page. Tag packages from the Packages screen and tests from the Tests screen.</p>

    <div class="card">
      <table>
        <thead>
          <tr><th>Name</th><th>Type</th><th>In filter</th><th>Order</th><th>Status</th><th></th></tr>
        </thead>
        <tbody>
          @for (c of categories(); track c.id) {
            <tr>
              <td><div class="name">{{ c.name }}</div><div class="slug muted">{{ c.slug }}</div></td>
              <td class="muted">{{ c.type }}</td>
              <td class="muted">{{ c.showInFilter ? 'Yes' : 'No' }}</td>
              <td class="muted">{{ c.sortOrder }}</td>
              <td><span class="pill" [class.on]="c.isActive" [class.off]="!c.isActive">
                {{ c.isActive ? 'Active' : 'Inactive' }}</span></td>
              <td class="actions">
                <button class="link" *appHasPermission="'categories.update'" (click)="openEdit(c)">Edit</button>
                @if (c.isActive) {
                  <button class="link danger" *appHasPermission="'categories.delete'"
                          [disabled]="busy()" (click)="deactivate(c)">Deactivate</button>
                }
              </td>
            </tr>
          } @empty {
            <tr><td colspan="6" class="muted">{{ loading() ? 'Loading…' : 'No categories yet.' }}</td></tr>
          }
        </tbody>
      </table>
    </div>

    @if (draft()) {
      <div class="overlay" (click)="close()">
        <div class="modal card" (click)="$event.stopPropagation()">
          <h2>{{ draft()!.id ? 'Edit category' : 'New category' }}</h2>
          <div class="grid">
            <div class="full"><label class="field-label">Name</label>
              <input class="input" [(ngModel)]="draft()!.name" /></div>
            <div><label class="field-label">Slug (blank = auto)</label>
              <input class="input" [(ngModel)]="draft()!.slug" /></div>
            <div><label class="field-label">Type</label>
              <select class="input" [(ngModel)]="draft()!.type">
                <option value="Package">Package (home filter chips)</option>
                <option value="Organ">Organ (Checkups by organ)</option>
                <option value="Concern">Concern (Shop by health concern)</option>
                <option value="Persona">Persona (Care for everyone)</option>
                <option value="Test">Test</option>
                <option value="Risk">Risk</option>
                <option value="Specialty">Specialty</option>
              </select></div>
            <div><label class="field-label">Icon name (Material)</label>
              <input class="input" [(ngModel)]="draft()!.iconUrl" placeholder="favorite" /></div>
            <div><label class="field-label">Sort order</label>
              <input class="input" type="number" [(ngModel)]="draft()!.sortOrder" /></div>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.showInFilter" /> Show as filter chip</label>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.isActive" /> Active</label>
          </div>
          @if (error()) { <p class="error">{{ error() }}</p> }
          <div class="foot">
            <button class="link" (click)="close()">Cancel</button>
            <button class="btn" [disabled]="saving()" (click)="save()">{{ saving() ? 'Saving…' : 'Save' }}</button>
          </div>
        </div>
      </div>
    }
  `,
  styles: [`
    .head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 8px; }
    h1 { font-size: 24px; margin: 0; }
    .sub { margin: 0 0 20px; font-size: 13px; max-width: 640px; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 12px; color: var(--text-secondary); padding: 8px 12px; border-bottom: 1px solid var(--border); }
    td { padding: 12px; border-bottom: 1px solid var(--border); font-size: 14px; }
    .name { font-weight: 600; }
    .slug { font-size: 12px; font-family: monospace; }
    .muted { color: var(--text-secondary); }
    .actions { text-align: right; white-space: nowrap; }
    .link { background: none; border: none; color: var(--teal-700); font-weight: 600; cursor: pointer; margin-left: 10px; }
    .link.danger { color: var(--error); }
    .pill { font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 999px; }
    .pill.on { background: #e6f4f1; color: var(--teal-700); }
    .pill.off { background: #fde8e8; color: var(--error); }
    .overlay { position: fixed; inset: 0; background: rgba(15,23,42,.45); display: grid; place-items: center; z-index: 50; }
    .modal { width: 560px; max-width: 92vw; }
    .modal h2 { font-size: 20px; margin: 0 0 18px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
    .grid .full { grid-column: 1 / -1; }
    .check { display: flex; align-items: center; gap: 8px; font-size: 14px; }
    .foot { display: flex; justify-content: flex-end; align-items: center; gap: 14px; margin-top: 22px; }
    .error { color: var(--error); font-size: 13px; margin: 12px 0 0; }
  `],
})
export class CategoriesComponent {
  private http = inject(HttpClient);

  categories = signal<Category[]>([]);
  loading = signal(false);
  saving = signal(false);
  busy = signal(false);
  error = signal('');
  draft = signal<Draft | null>(null);

  constructor() {
    this.load();
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/categories`));
      this.categories.set((res.data ?? []) as Category[]);
    } catch {
      this.categories.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  openNew(): void {
    this.error.set('');
    this.draft.set({ name: '', type: 'Package', showInFilter: true, sortOrder: 0, isActive: true });
  }

  openEdit(c: Category): void {
    this.error.set('');
    this.draft.set({ ...c });
  }

  close(): void {
    this.draft.set(null);
  }

  async save(): Promise<void> {
    const d = this.draft();
    if (!d) return;
    if (!d.name?.trim()) { this.error.set('Name is required.'); return; }

    this.saving.set(true);
    this.error.set('');
    const body = {
      name: d.name,
      slug: d.slug || null,
      type: d.type || 'Package',
      iconUrl: d.iconUrl ?? null,
      showInFilter: d.showInFilter ?? true,
      sortOrder: Number(d.sortOrder) || 0,
      isActive: d.isActive ?? true,
    };
    try {
      if (d.id) {
        await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/categories/${d.id}`, body));
      } else {
        await firstValueFrom(this.http.post(`${API_BASE_URL}/admin/categories`, body));
      }
      this.close();
      await this.load();
    } catch (e: any) {
      this.error.set(e?.error?.message ?? 'Could not save the category.');
    } finally {
      this.saving.set(false);
    }
  }

  async deactivate(c: Category): Promise<void> {
    this.busy.set(true);
    try {
      await firstValueFrom(this.http.delete(`${API_BASE_URL}/admin/categories/${c.id}`));
      this.categories.update(list => list.map(x => x.id === c.id ? { ...x, isActive: false } : x));
    } finally {
      this.busy.set(false);
    }
  }
}
