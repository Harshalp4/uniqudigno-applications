import { Component } from '@angular/core';

@Component({
  selector: 'app-unauthorized',
  standalone: true,
  template: `
    <div class="wrap">
      <h1>Access denied</h1>
      <p>You don't have permission to view this page.</p>
    </div>
  `,
  styles: [`
    .wrap { display: grid; place-items: center; height: 70vh; text-align: center; }
    p { color: var(--text-secondary); }
  `],
})
export class UnauthorizedComponent {}
