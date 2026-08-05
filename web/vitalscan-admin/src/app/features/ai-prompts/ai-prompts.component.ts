import { Component, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { FormsModule } from '@angular/forms';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from '../../core/api.config';
import { HasPermissionDirective } from '../../core/has-permission.directive';

interface Prompt {
  id: string;
  name: string;
  version: number;
  systemPrompt: string;
  model: string;
  isActive: boolean;
  createdAt: string;
}

type Draft = Partial<Prompt>;

@Component({
  selector: 'app-ai-prompts',
  standalone: true,
  imports: [FormsModule, HasPermissionDirective],
  template: `
    <div class="head">
      <h1>AI Prompts</h1>
      <button class="btn" *appHasPermission="'ai_prompts.create'" (click)="openNew()">New prompt</button>
    </div>

    <div class="card">
      <table>
        <thead>
          <tr><th>Name</th><th>Version</th><th>Model</th><th>Status</th><th></th></tr>
        </thead>
        <tbody>
          @for (p of prompts(); track p.id) {
            <tr>
              <td class="name">{{ p.name }}</td>
              <td class="muted">v{{ p.version }}</td>
              <td class="muted mono">{{ p.model }}</td>
              <td><span class="pill" [class.on]="p.isActive" [class.off]="!p.isActive">
                {{ p.isActive ? 'Active' : 'Inactive' }}</span></td>
              <td class="actions">
                <button class="link" *appHasPermission="'ai_prompts.create'" (click)="openEdit(p)">Edit</button>
                @if (!p.isActive) {
                  <button class="link" *appHasPermission="'ai_prompts.activate'"
                          [disabled]="busy() === p.id" (click)="activate(p)">Activate</button>
                }
              </td>
            </tr>
          } @empty {
            <tr><td colspan="5" class="muted">{{ loading() ? 'Loading…' : 'No prompts found.' }}</td></tr>
          }
        </tbody>
      </table>
    </div>

    @if (draft()) {
      <div class="overlay" (click)="close()">
        <div class="modal card" (click)="$event.stopPropagation()">
          <h2>{{ draft()!.id ? 'Edit prompt' : 'New prompt' }}</h2>
          <div class="grid">
            <div class="full"><label class="field-label">Name</label>
              <input class="input" [(ngModel)]="draft()!.name" /></div>
            <div class="full"><label class="field-label">Model</label>
              <input class="input" placeholder="claude-opus-4-8" [(ngModel)]="draft()!.model" /></div>
            <div class="full"><label class="field-label">System prompt</label>
              <textarea class="input mono" rows="10" [(ngModel)]="draft()!.systemPrompt"></textarea></div>
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
    .head { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; gap: 16px; }
    h1 { font-size: 24px; margin: 0; }
    table { width: 100%; border-collapse: collapse; }
    th { text-align: left; font-size: 12px; color: var(--text-secondary); padding: 8px 12px; border-bottom: 1px solid var(--border); }
    td { padding: 12px; border-bottom: 1px solid var(--border); font-size: 14px; }
    .name { font-weight: 600; }
    .mono { font-family: monospace; }
    .muted { color: var(--text-secondary); }
    .actions { text-align: right; white-space: nowrap; }
    .link { background: none; border: none; color: var(--teal-700); font-weight: 600; cursor: pointer; margin-left: 10px; }
    .link.danger { color: var(--error); }
    .pill { font-size: 12px; font-weight: 600; padding: 3px 10px; border-radius: 999px; }
    .pill.on { background: #e6f4f1; color: var(--teal-700); }
    .pill.off { background: #eef2f6; color: var(--text-secondary); }
    .overlay { position: fixed; inset: 0; background: rgba(15,23,42,.45); display: grid; place-items: center; z-index: 50; }
    .modal { width: 680px; max-width: 92vw; }
    .modal h2 { font-size: 20px; margin: 0 0 18px; }
    .grid { display: grid; grid-template-columns: 1fr 1fr; gap: 14px; }
    .grid .full { grid-column: 1 / -1; }
    textarea.input { resize: vertical; font-size: 13px; }
    .check { display: flex; align-items: center; gap: 8px; font-size: 14px; }
    .foot { display: flex; justify-content: flex-end; align-items: center; gap: 14px; margin-top: 22px; }
    .error { color: var(--error); font-size: 13px; margin: 12px 0 0; }
  `],
})
export class AiPromptsComponent {
  private http = inject(HttpClient);

  prompts = signal<Prompt[]>([]);
  loading = signal(false);
  saving = signal(false);
  busy = signal<string | null>(null);
  error = signal('');
  draft = signal<Draft | null>(null);

  constructor() {
    this.load();
  }

  private async load(): Promise<void> {
    this.loading.set(true);
    try {
      const res = await firstValueFrom(this.http.get<any>(`${API_BASE_URL}/admin/ai-prompts`));
      this.prompts.set((res.data ?? []) as Prompt[]);
    } catch {
      this.prompts.set([]);
    } finally {
      this.loading.set(false);
    }
  }

  openNew(): void {
    this.error.set('');
    this.draft.set({ name: '', model: '', systemPrompt: '', isActive: false });
  }

  openEdit(p: Prompt): void {
    this.error.set('');
    this.draft.set({ ...p });
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
      systemPrompt: d.systemPrompt ?? '',
      model: d.model ?? '',
      isActive: !!d.isActive,
    };
    try {
      if (d.id) {
        await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/ai-prompts/${d.id}`, body));
      } else {
        await firstValueFrom(this.http.post(`${API_BASE_URL}/admin/ai-prompts`, body));
      }
      this.close();
      await this.load();
    } catch (e: any) {
      this.error.set(e?.error?.message ?? 'Could not save the prompt.');
    } finally {
      this.saving.set(false);
    }
  }

  async activate(p: Prompt): Promise<void> {
    this.busy.set(p.id);
    try {
      await firstValueFrom(this.http.put(`${API_BASE_URL}/admin/ai-prompts/${p.id}/activate`, {}));
      await this.load();
    } finally {
      this.busy.set(null);
    }
  }
}
