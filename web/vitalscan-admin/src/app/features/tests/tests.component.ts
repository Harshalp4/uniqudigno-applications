import { Component, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { HasPermissionDirective } from '../../core/has-permission.directive';

interface Test {
  id: string;
  name: string;
  slug: string;
  shortDescription?: string | null;
  mrp: number;
  price: number;
  sampleType?: string | null;
  fastingRequired: boolean;
  homeCollectionAvailable: boolean;
  isPopular: boolean;
  isActive: boolean;
  testCategories?: { categoryId: string }[];
}

interface Category { id: string; name: string; type: string; }

type Draft = Partial<Test> & { categoryIds?: string[] };

@Component({
  selector: 'app-tests',
  standalone: true,
  imports: [FormsModule, HasPermissionDirective],
  template: `
    <div class="head">
      <h1>Tests</h1>
      <div class="head-actions">
        <input class="input search" placeholder="Search name or slug…"
               [(ngModel)]="term" (ngModelChange)="onSearch()" />
        <button class="btn" *appHasPermission="'tests.create'" (click)="openNew()">New test</button>
      </div>
    </div>

    <div class="card">
      <table>
        <thead>
          <tr><th>Name</th><th>Sample</th><th>MRP</th><th>Price</th><th>Flags</th><th>Status</th><th></th></tr>
        </thead>
        <tbody>
          @for (t of tests(); track t.id) {
            <tr>
              <td><div class="name">{{ t.name }}</div><div class="slug muted">{{ t.slug }}</div></td>
              <td class="muted">{{ t.sampleType || '—' }}</td>
              <td class="muted">₹{{ t.mrp }}</td>
              <td>₹{{ t.price }}</td>
              <td class="flags muted">
                @if (t.fastingRequired) { <span>Fasting</span> }
                @if (t.homeCollectionAvailable) { <span>Home</span> }
                @if (t.isPopular) { <span>Popular</span> }
              </td>
              <td><span class="pill" [class.on]="t.isActive" [class.off]="!t.isActive">
                {{ t.isActive ? 'Active' : 'Inactive' }}</span></td>
              <td class="actions">
                <button class="link" *appHasPermission="'tests.update'" (click)="openEdit(t)">Edit</button>
                @if (t.isActive) {
                  <button class="link danger" *appHasPermission="'tests.delete'"
                          [disabled]="busy()" (click)="deactivate(t)">Deactivate</button>
                }
              </td>
            </tr>
          } @empty {
            <tr><td colspan="7" class="muted">{{ loading() ? 'Loading…' : 'No tests found.' }}</td></tr>
          }
        </tbody>
      </table>
      <div class="pager">
        <span class="muted">Page {{ page() }} of {{ totalPages() }} · {{ total() }} tests</span>
        <span class="spacer"></span>
        <button class="link" [disabled]="page() <= 1" (click)="go(page() - 1)">‹ Prev</button>
        <button class="link" [disabled]="page() >= totalPages()" (click)="go(page() + 1)">Next ›</button>
      </div>
    </div>

    @if (draft()) {
      <div class="overlay" (click)="close()">
        <div class="modal card" (click)="$event.stopPropagation()">
          <h2>{{ draft()!.id ? 'Edit test' : 'New test' }}</h2>
          <div class="grid">
            <div class="full"><label class="field-label">Name</label>
              <input class="input" [(ngModel)]="draft()!.name" /></div>
            <div><label class="field-label">Slug (blank = auto)</label>
              <input class="input" [(ngModel)]="draft()!.slug" /></div>
            <div><label class="field-label">Sample type</label>
              <input class="input" [(ngModel)]="draft()!.sampleType" /></div>
            <div><label class="field-label">MRP (₹)</label>
              <input class="input" type="number" [(ngModel)]="draft()!.mrp" /></div>
            <div><label class="field-label">Price (₹)</label>
              <input class="input" type="number" [(ngModel)]="draft()!.price" /></div>
            <div class="full"><label class="field-label">Short description</label>
              <input class="input" [(ngModel)]="draft()!.shortDescription" /></div>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.fastingRequired" /> Fasting required</label>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.homeCollectionAvailable" /> Home collection</label>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.isPopular" /> Popular</label>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.isActive" /> Active</label>
            <div class="full">
              <label class="field-label">Browse categories — organ / concern / persona rails
                ({{ (draft()!.categoryIds?.length ?? 0) }} selected)</label>
              <div class="cats">
                @for (c of categories(); track c.id) {
                  <label class="cat" [class.on]="isCat(c.id)">
                    <input type="checkbox" [checked]="isCat(c.id)" (change)="toggleCat(c.id)" />
                    {{ c.name }} <span class="ctype">{{ c.type }}</span>
                  </label>
                } @empty {
                  <span class="muted">No organ/concern/persona categories yet — add them in the Categories screen.</span>
                }
              </div>
            </div>
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
    .head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; gap: 16px; }
    .head-actions { display: flex; gap: 12px; }
    h1 { font-size: 24px; margin: 0; }
    .search { max-width: 260px; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 12px; color: var(--text-secondary); padding: 8px 12px; border-bottom: 1px solid var(--border); }
    td { padding: 12px; border-bottom: 1px solid var(--border); font-size: 14px; }
    .name { font-weight: 600; }
    .slug { font-size: 12px; font-family: monospace; }
    .muted { color: var(--text-secondary); }
    .flags span { display: inline-block; background: #eef2f6; border-radius: 6px; padding: 2px 7px; font-size: 11px; margin-right: 4px; }
    .actions { text-align: right; white-space: nowrap; }
    .link { background: none; border: none; color: var(--teal-700); font-weight: 600; cursor: pointer; margin-left: 10px; }
    .link.danger { color: var(--error); }
    .pill { font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 999px; }
    .pill.on { background: #e6f4f1; color: var(--teal-700); }
    .pill.off { background: #fde8e8; color: var(--error); }
    .pager { display: flex; align-items: center; gap: 12px; padding: 14px 12px 4px; font-size: 13px; }
    .spacer { flex: 1; }
    .overlay { position: fixed; inset: 0; background: rgba(15,23,42,.45); display: grid; place-items: center; z-index: 50; }
    .modal { width: 640px; max-width: 92vw; }
    .modal h2 { font-size: 20px; margin: 0 0 18px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
    .grid .full { grid-column: 1 / -1; }
    .check { display: flex; align-items: center; gap: 8px; font-size: 14px; }
    .foot { display: flex; justify-content: flex-end; align-items: center; gap: 14px; margin-top: 22px; }
    .error { color: var(--error); font-size: 13px; margin: 12px 0 0; }
    .cats { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 6px; }
    .cat { display: inline-flex; align-items: center; gap: 6px; padding: 6px 10px; border: 1px solid var(--border); border-radius: 8px; font-size: 13px; cursor: pointer; }
    .cat.on { background: #e6f4f1; border-color: var(--teal-700); }
    .cat .ctype { color: var(--muted, #98a2b3); font-size: 11px; }
  `],
})
export class TestsComponent {
  private http = inject(HttpClient);

  tests = signal<Test[]>([]);
  page = signal(1);
  pageSize = signal(20);
  total = signal(0);
  loading = signal(false);
  saving = signal(false);
  busy = signal(false);
  error = signal('');
  draft = signal<Draft | null>(null);
  term = '';
  private searchTimer: any;

  categories = signal<Category[]>([]);

  totalPages = computed(() => Math.max(1, Math.ceil(this.total() / this.pageSize())));

  constructor() {
    this.load();
    this.loadCategories();
  }

  private async loadCategories(): Promise<void> {
    try {
      // Browse categories only (organ/concern/persona) — Package chips are
      // tagged from the Packages screen instead.
      const res = await firstValueFrom(
          this.http.get<any>(`${API_BASE_URL}/admin/categories`));
      const all = (res.data ?? []) as Category[];
      this.categories.set(all.filter(
          c => ['Organ', 'Concern', 'Persona'].includes(c.type)));
    } catch {
      this.categories.set([]);
    }
  }

  isCat(id: string): boolean {
    return (this.draft()?.categoryIds ?? []).includes(id);
  }

  toggleCat(id: string): void {
    const d = this.draft();
    if (!d) return;
    const set = new Set(d.categoryIds ?? []);
    set.has(id) ? set.delete(id) : set.add(id);
    this.draft.set({ ...d, categoryIds: [...set] });
  }

  onSearch(): void {
    clearTimeout(this.searchTimer);
    this.searchTimer = setTimeout(() => { this.page.set(1); this.load(); }, 300);
  }

  go(p: number): void {
    this.page.set(Math.max(1, p));
    this.load();
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const q = `page=${this.page()}&pageSize=${this.pageSize()}` + (this.term.trim() ? `&q=${encodeURIComponent(this.term.trim())}` : '');
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/tests?${q}`));
      this.tests.set((res.data ?? []) as Test[]);
      this.total.set(res.pagination?.total ?? this.tests().length);
      this.pageSize.set(res.pagination?.pageSize ?? this.pageSize());
    } catch {
      this.tests.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  openNew(): void {
    this.error.set('');
    this.draft.set({ name: '', mrp: 0, price: 0, fastingRequired: false, homeCollectionAvailable: true, isPopular: false, isActive: true, categoryIds: [] });
  }

  openEdit(t: Test): void {
    this.error.set('');
    this.draft.set({
      ...t,
      categoryIds: (t.testCategories ?? []).map(tc => tc.categoryId),
    });
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
      shortDescription: d.shortDescription ?? null,
      mrp: Number(d.mrp) || 0,
      price: Number(d.price) || 0,
      sampleType: d.sampleType ?? null,
      fastingRequired: !!d.fastingRequired,
      homeCollectionAvailable: !!d.homeCollectionAvailable,
      isPopular: !!d.isPopular,
      isActive: d.isActive ?? true,
      categoryIds: d.categoryIds ?? [],
    };
    try {
      if (d.id) {
        await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/tests/${d.id}`, body));
      } else {
        await firstValueFrom(this.http.post(`${API_BASE_URL}/admin/tests`, body));
      }
      this.close();
      await this.load();
    } catch (e: any) {
      this.error.set(e?.error?.message ?? 'Could not save the test.');
    } finally {
      this.saving.set(false);
    }
  }

  async deactivate(t: Test): Promise<void> {
    this.busy.set(true);
    try {
      await firstValueFrom(this.http.delete(`${API_BASE_URL}/admin/tests/${t.id}`));
      this.tests.update(list => list.map(x => x.id === t.id ? { ...x, isActive: false } : x));
    } finally {
      this.busy.set(false);
    }
  }
}
