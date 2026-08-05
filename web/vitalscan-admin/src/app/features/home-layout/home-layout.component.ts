import { Component, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { AuthService } from '../../core/auth.service';

interface HomeSection {
  id: string;
  title: string;
  sectionType: string;
  sortOrder: number;
  isVisible: boolean;
}

/** Home-screen layout editor (Section 11) — reorder + show/hide app home sections. */
@Component({
  selector: 'app-home-layout',
  standalone: true,
  template: `
    <div class="head">
      <h1>Home Layout</h1>
      <span class="muted">Order &amp; visibility of the customer app home screen</span>
    </div>

    <div class="card">
      @for (s of sections(); track s.id; let i = $index) {
        <div class="row" [class.hidden]="!s.isVisible">
          <div class="ord">
            <button class="arrow" [disabled]="i === 0 || !canEdit()" (click)="move(i, -1)">▲</button>
            <button class="arrow" [disabled]="i === sections().length - 1 || !canEdit()" (click)="move(i, 1)">▼</button>
          </div>
          <div class="info">
            <div class="title">{{ s.title }}</div>
            <div class="type muted">{{ s.sectionType }}</div>
          </div>
          <button class="toggle" [class.on]="s.isVisible" [disabled]="!canEdit() || busy() === s.id"
                  (click)="toggle(s)">
            {{ s.isVisible ? 'Visible' : 'Hidden' }}
          </button>
        </div>
      } @empty {
        <p class="muted">{{ loading() ? 'Loading…' : 'No home sections configured.' }}</p>
      }
      @if (!canEdit() && sections().length) {
        <p class="muted small">You have read-only access to the home layout.</p>
      }
    </div>
  `,
  styles: [`
    .head { margin-bottom: 20px; }
    h1 { font-size: 24px; margin: 0 0 4px; }
    .muted { color: var(--text-secondary); }
    .muted.small { font-size: 13px; margin-top: 14px; }
    .row { display: grid; grid-template-columns: 48px 1fr auto; align-items: center; gap: 14px;
           padding: 12px 0; border-bottom: 1px solid var(--border); }
    .row.hidden .info { opacity: 0.5; }
    .ord { display: flex; flex-direction: column; gap: 2px; }
    .arrow { background: none; border: 1px solid var(--border); border-radius: 6px; cursor: pointer;
             font-size: 10px; line-height: 1; padding: 3px 6px; color: var(--text-secondary); }
    .arrow:disabled { opacity: 0.35; cursor: default; }
    .title { font-weight: 600; font-size: 14px; }
    .type { font-size: 12px; text-transform: lowercase; }
    .toggle { border: 1px solid var(--border); background: #fff; border-radius: 999px;
              font-size: 12px; font-weight: 600; padding: 5px 14px; cursor: pointer; color: var(--text-secondary); }
    .toggle.on { background: #e6f4f1; color: var(--teal-700); border-color: #cfe9e3; }
    .toggle:disabled { cursor: default; }
  `],
})
export class HomeLayoutComponent {
  private http = inject(HttpClient);
  private auth = inject(AuthService);

  sections = signal<HomeSection[]>([]);
  loading = signal(false);
  busy = signal<string | null>(null);

  constructor() {
    this.load();
  }

  canEdit = () => this.auth.hasPermission('home_layout.update');

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/home/sections`));
      const list = ((res.data ?? []) as HomeSection[]).sort((a, b) => a.sortOrder - b.sortOrder);
      this.sections.set(list);
    } catch {
      this.sections.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  async toggle(s: HomeSection): Promise<void> {
    this.busy.set(s.id);
    try {
      await this.persist(s.id, { isVisible: !s.isVisible });
      this.sections.update(list => list.map(x => x.id === s.id ? { ...x, isVisible: !x.isVisible } : x));
    } finally {
      this.busy.set(null);
    }
  }

  async move(index: number, delta: number): Promise<void> {
    const list = [...this.sections()];
    const target = index + delta;
    if (target < 0 || target >= list.length) return;

    [list[index], list[target]] = [list[target], list[index]];
    // Renumber sequentially and reflect immediately.
    list.forEach((s, i) => (s.sortOrder = i));
    this.sections.set(list);

    // Persist the two affected rows' new order.
    await Promise.all([
      this.persist(list[index].id, { sortOrder: list[index].sortOrder }),
      this.persist(list[target].id, { sortOrder: list[target].sortOrder }),
    ]);
  }

  private persist(id: string, body: { isVisible?: boolean; sortOrder?: number }): Promise<unknown> {
    return firstValueFrom(this.http.put(`${API_BASE_URL}/admin/home/sections/${id}`, body));
  }
}
