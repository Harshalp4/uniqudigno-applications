import { Component, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { HasPermissionDirective } from '../../core/has-permission.directive';

interface Package {
  id: string;
  name: string;
  slug: string;
  shortDescription?: string | null;
  description?: string | null;
  mrp: number;
  price: number;
  testCount: number;
  parameterCount: number;
  fastingRequired: boolean;
  reportTimeText?: string | null;
  fastingHours?: number | null;
  sampleType?: string | null;
  preparation?: string | null;
  recommendedFor?: string | null;
  faqJson?: string | null;
  isPopular: boolean;
  isFeatured: boolean;
  isActive: boolean;
  packageCategories?: { categoryId: string }[];
  packageTests?: { testId: string }[];
}

interface Category { id: string; name: string; slug: string; }
interface TestRow { id: string; name: string; parameterCount: number; }
interface Faq { question: string; answer: string; }

type Draft = Partial<Package> & {
  categoryIds?: string[]; testIds?: string[]; faqs?: Faq[];
};

@Component({
  selector: 'app-packages',
  standalone: true,
  imports: [FormsModule, HasPermissionDirective],
  template: `
    <div class="head">
      <h1>Packages</h1>
      <div class="head-actions">
        <input class="input search" placeholder="Search name or slug…"
               [(ngModel)]="term" (ngModelChange)="onSearch()" />
        <button class="btn" *appHasPermission="'packages.create'" (click)="openNew()">New package</button>
      </div>
    </div>

    <div class="card">
      <table>
        <thead>
          <tr><th>Name</th><th>Tests</th><th>Params</th><th>MRP</th><th>Price</th><th>Flags</th><th>Status</th><th></th></tr>
        </thead>
        <tbody>
          @for (p of packages(); track p.id) {
            <tr>
              <td><div class="name">{{ p.name }}</div><div class="slug muted">{{ p.slug }}</div></td>
              <td class="muted">{{ p.testCount }}</td>
              <td class="muted">{{ p.parameterCount }}</td>
              <td class="muted">₹{{ p.mrp }}</td>
              <td>₹{{ p.price }}</td>
              <td class="flags muted">
                @if (p.fastingRequired) { <span>Fasting</span> }
                @if (p.isPopular) { <span>Popular</span> }
                @if (p.isFeatured) { <span>Featured</span> }
              </td>
              <td><span class="pill" [class.on]="p.isActive" [class.off]="!p.isActive">
                {{ p.isActive ? 'Active' : 'Inactive' }}</span></td>
              <td class="actions">
                <button class="link" *appHasPermission="'packages.update'" (click)="openEdit(p)">Edit</button>
                @if (p.isActive) {
                  <button class="link danger" *appHasPermission="'packages.delete'"
                          [disabled]="busy()" (click)="deactivate(p)">Deactivate</button>
                }
              </td>
            </tr>
          } @empty {
            <tr><td colspan="8" class="muted">{{ loading() ? 'Loading…' : 'No packages found.' }}</td></tr>
          }
        </tbody>
      </table>
      <div class="pager">
        <span class="muted">Page {{ page() }} of {{ totalPages() }} · {{ total() }} packages</span>
        <span class="spacer"></span>
        <button class="link" [disabled]="page() <= 1" (click)="go(page() - 1)">‹ Prev</button>
        <button class="link" [disabled]="page() >= totalPages()" (click)="go(page() + 1)">Next ›</button>
      </div>
    </div>

    @if (draft()) {
      <div class="overlay" (click)="close()">
        <div class="modal card" (click)="$event.stopPropagation()">
          <h2>{{ draft()!.id ? 'Edit package' : 'New package' }}</h2>
          <div class="grid">
            <div class="full"><label class="field-label">Name</label>
              <input class="input" [(ngModel)]="draft()!.name" /></div>
            <div><label class="field-label">Slug (blank = auto)</label>
              <input class="input" [(ngModel)]="draft()!.slug" /></div>
            <div><label class="field-label">Report time</label>
              <input class="input" [(ngModel)]="draft()!.reportTimeText" placeholder="within 24 hrs" /></div>
            <div><label class="field-label">MRP (₹)</label>
              <input class="input" type="number" [(ngModel)]="draft()!.mrp" /></div>
            <div><label class="field-label">Price (₹)</label>
              <input class="input" type="number" [(ngModel)]="draft()!.price" /></div>
            <div><label class="field-label">Test count</label>
              <input class="input" type="number" [(ngModel)]="draft()!.testCount" /></div>
            <div><label class="field-label">Parameter count</label>
              <input class="input" type="number" [(ngModel)]="draft()!.parameterCount" /></div>
            <div class="full"><label class="field-label">Short description</label>
              <input class="input" [(ngModel)]="draft()!.shortDescription" /></div>
            <div class="full"><label class="field-label">Description</label>
              <textarea class="input" rows="3" [(ngModel)]="draft()!.description"></textarea></div>
            <div><label class="field-label">Sample type</label>
              <input class="input" [(ngModel)]="draft()!.sampleType" placeholder="Blood" /></div>
            <div><label class="field-label">Fasting hours (blank = none)</label>
              <input class="input" type="number" [(ngModel)]="draft()!.fastingHours" placeholder="10" /></div>
            <div class="full"><label class="field-label">Who should take this</label>
              <textarea class="input" rows="2" [(ngModel)]="draft()!.recommendedFor"></textarea></div>
            <div class="full"><label class="field-label">How to prepare (pre-test instructions)</label>
              <textarea class="input" rows="2" [(ngModel)]="draft()!.preparation"></textarea></div>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.fastingRequired" /> Fasting required</label>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.isPopular" /> Popular</label>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.isFeatured" /> Featured</label>
            <label class="check"><input type="checkbox" [(ngModel)]="draft()!.isActive" /> Active</label>
            <div class="full">
              <label class="field-label">Categories (home filter chips — select all that apply)</label>
              <div class="cats">
                @for (c of categories(); track c.id) {
                  <label class="cat" [class.on]="isCat(c.id)">
                    <input type="checkbox" [checked]="isCat(c.id)" (change)="toggleCat(c.id)" />
                    {{ c.name }}
                  </label>
                } @empty {
                  <span class="muted">No package categories yet — add them in the Categories screen.</span>
                }
              </div>
            </div>
            <div class="full">
              <label class="field-label">Included tests — shows in the app's "What's included"
                ({{ (draft()!.testIds?.length ?? 0) }} selected)</label>
              <input class="input" placeholder="Search tests…" [(ngModel)]="testTerm" />
              <div class="tests">
                @for (t of filteredTests(); track t.id) {
                  <label class="testrow" [class.on]="isTest(t.id)">
                    <input type="checkbox" [checked]="isTest(t.id)" (change)="toggleTest(t.id)" />
                    <span class="tname">{{ t.name }}</span>
                    <span class="muted">{{ t.parameterCount }} params</span>
                  </label>
                } @empty {
                  <span class="muted">No tests match.</span>
                }
              </div>
            </div>
            <div class="full">
              <label class="field-label">FAQs — shown on the app's package detail
                ({{ (draft()!.faqs?.length ?? 0) }})</label>
              @for (f of draft()!.faqs ?? []; track $index) {
                <div class="faq">
                  <input class="input" placeholder="Question"
                    [(ngModel)]="f.question" [ngModelOptions]="{ standalone: true }" />
                  <textarea class="input" rows="2" placeholder="Answer"
                    [(ngModel)]="f.answer" [ngModelOptions]="{ standalone: true }"></textarea>
                  <button type="button" class="link danger" (click)="removeFaq($index)">Remove</button>
                </div>
              }
              <button type="button" class="btn ghost" (click)="addFaq()">+ Add FAQ</button>
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
    .modal { width: 680px; max-width: 92vw; max-height: 88vh; overflow: auto; }
    .modal h2 { font-size: 20px; margin: 0 0 18px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
    .grid .full { grid-column: 1 / -1; }
    .check { display: flex; align-items: center; gap: 8px; font-size: 14px; }
    .cats { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 6px; }
    .cat { display: inline-flex; align-items: center; gap: 6px; font-size: 13px; padding: 6px 12px;
           border: 1px solid var(--border); border-radius: 999px; cursor: pointer; }
    .cat.on { border-color: var(--teal-700); background: #e6f4f1; color: var(--teal-700); font-weight: 600; }
    .cat input { margin: 0; }
    .tests { max-height: 220px; overflow: auto; border: 1px solid var(--border); border-radius: 10px; margin-top: 8px; }
    .testrow { display: flex; align-items: center; gap: 10px; padding: 9px 12px; font-size: 13px; border-bottom: 1px solid var(--border); cursor: pointer; }
    .testrow:last-child { border-bottom: none; }
    .testrow.on { background: #e6f4f1; }
    .testrow .tname { flex: 1; }
    .foot { display: flex; justify-content: flex-end; align-items: center; gap: 14px; margin-top: 22px; }
    .error { color: var(--error); font-size: 13px; margin: 12px 0 0; }
    .faq { display: grid; gap: 6px; padding: 10px; margin-bottom: 8px; border: 1px solid var(--border); border-radius: 10px; }
    .faq .link.danger { justify-self: start; margin-left: 0; }
    .btn.ghost { background: none; border: 1px dashed var(--border); color: var(--teal-700); }
  `],
})
export class PackagesComponent {
  private http = inject(HttpClient);

  packages = signal<Package[]>([]);
  categories = signal<Category[]>([]);
  tests = signal<TestRow[]>([]);
  testTerm = '';
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

  totalPages = computed(() => Math.max(1, Math.ceil(this.total() / this.pageSize())));

  constructor() {
    this.load();
    this.loadCategories();
    this.loadTests();
  }

  private async loadCategories(): Promise<void> {
    try {
      const res = await firstValueFrom(
        this.http.get<any>(`${API_BASE_URL}/admin/categories?type=Package`));
      this.categories.set((res.data ?? []) as Category[]);
    } catch {
      this.categories.set([]);
    }
  }

  private async loadTests(): Promise<void> {
    try {
      const res = await firstValueFrom(
        this.http.get<any>(`${API_BASE_URL}/admin/tests?page=1&pageSize=200`));
      this.tests.set((res.data ?? []) as TestRow[]);
    } catch {
      this.tests.set([]);
    }
  }

  filteredTests(): TestRow[] {
    const q = this.testTerm.trim().toLowerCase();
    const all = this.tests();
    if (!q) return all;
    return all.filter(t => t.name.toLowerCase().includes(q));
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

  isTest(id: string): boolean {
    return (this.draft()?.testIds ?? []).includes(id);
  }

  toggleTest(id: string): void {
    const d = this.draft();
    if (!d) return;
    const set = new Set(d.testIds ?? []);
    set.has(id) ? set.delete(id) : set.add(id);
    this.draft.set({ ...d, testIds: [...set] });
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
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/packages?${q}`));
      this.packages.set((res.data ?? []) as Package[]);
      this.total.set(res.pagination?.total ?? this.packages().length);
      this.pageSize.set(res.pagination?.pageSize ?? this.pageSize());
    } catch {
      this.packages.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  openNew(): void {
    this.error.set('');
    this.testTerm = '';
    this.draft.set({
      name: '', mrp: 0, price: 0, testCount: 0, parameterCount: 0,
      fastingRequired: false, isPopular: false, isFeatured: false, isActive: true,
      categoryIds: [], testIds: [], faqs: [],
    });
  }

  openEdit(p: Package): void {
    this.error.set('');
    this.testTerm = '';
    this.draft.set({
      ...p,
      categoryIds: (p.packageCategories ?? []).map(pc => pc.categoryId),
      testIds: (p.packageTests ?? []).map(pt => pt.testId),
      faqs: this.parseFaqs(p.faqJson),
    });
  }

  private parseFaqs(json?: string | null): Faq[] {
    if (!json) return [];
    try {
      const arr = JSON.parse(json);
      // Tolerate camelCase and any legacy PascalCase rows.
      return Array.isArray(arr)
        ? arr.map(f => ({
            question: f.question ?? f.Question ?? '',
            answer: f.answer ?? f.Answer ?? '',
          }))
        : [];
    } catch { return []; }
  }

  addFaq(): void {
    const d = this.draft();
    if (!d) return;
    this.draft.set({ ...d, faqs: [...(d.faqs ?? []), { question: '', answer: '' }] });
  }

  removeFaq(i: number): void {
    const d = this.draft();
    if (!d) return;
    const faqs = [...(d.faqs ?? [])];
    faqs.splice(i, 1);
    this.draft.set({ ...d, faqs });
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
      description: d.description ?? null,
      mrp: Number(d.mrp) || 0,
      price: Number(d.price) || 0,
      testCount: Number(d.testCount) || 0,
      parameterCount: Number(d.parameterCount) || 0,
      fastingRequired: !!d.fastingRequired,
      reportTimeText: d.reportTimeText ?? null,
      fastingHours: d.fastingHours != null && `${d.fastingHours}` !== ''
        ? Number(d.fastingHours) : null,
      sampleType: d.sampleType ?? null,
      preparation: d.preparation ?? null,
      recommendedFor: d.recommendedFor ?? null,
      faqs: (d.faqs ?? [])
        .filter(f => f.question?.trim() && f.answer?.trim())
        .map(f => ({ question: f.question.trim(), answer: f.answer.trim() })),
      isPopular: !!d.isPopular,
      isFeatured: !!d.isFeatured,
      isActive: d.isActive ?? true,
      categoryIds: d.categoryIds ?? [],
      testIds: d.testIds ?? [],
    };
    try {
      if (d.id) {
        await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/packages/${d.id}`, body));
      } else {
        await firstValueFrom(this.http.post(`${API_BASE_URL}/admin/packages`, body));
      }
      this.close();
      await this.load();
    } catch (e: any) {
      this.error.set(e?.error?.message ?? 'Could not save the package.');
    } finally {
      this.saving.set(false);
    }
  }

  async deactivate(p: Package): Promise<void> {
    this.busy.set(true);
    try {
      await firstValueFrom(this.http.delete(`${API_BASE_URL}/admin/packages/${p.id}`));
      this.packages.update(list => list.map(x => x.id === p.id ? { ...x, isActive: false } : x));
    } finally {
      this.busy.set(false);
    }
  }
}
