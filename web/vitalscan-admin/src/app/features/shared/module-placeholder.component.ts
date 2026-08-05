import { Component, inject } from '@angular/core';
import { ActivatedRoute } from '@angular/router';

@Component({
  selector: 'app-module-placeholder',
  standalone: true,
  template: `
    <h1>{{ title }}</h1>
    <div class="card empty">
      <p>This module is scaffolded. Grid, filters and editors wire to the
      <code>{{ title }}</code> admin APIs in a later pass.</p>
    </div>
  `,
  styles: [`
    h1 { font-size: 24px; margin: 0 0 20px; }
    .empty { color: var(--text-secondary); }
    code { background: var(--surface-raised); padding: 2px 6px; border-radius: 6px; }
  `],
})
export class ModulePlaceholderComponent {
  title = inject(ActivatedRoute).snapshot.data['title'] ?? 'Module';
}
