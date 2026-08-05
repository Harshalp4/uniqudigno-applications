import { Component, computed, inject, OnDestroy, OnInit } from '@angular/core';
import { Router, RouterLink, RouterLinkActive, RouterOutlet } from '@angular/router';

import { AuthService } from '../../core/auth.service';

interface NavModule { label: string; route: string; permission: string; }

const MODULES: NavModule[] = [
  { label: 'Dashboard', route: '/dashboard', permission: 'analytics.view' },
  { label: 'Users', route: '/users', permission: 'users.view' },
  { label: 'Bookings', route: '/bookings', permission: 'bookings.view' },
  { label: 'Tests', route: '/tests', permission: 'tests.view' },
  { label: 'Packages', route: '/packages', permission: 'packages.view' },
  { label: 'Categories', route: '/categories', permission: 'categories.view' },
  { label: 'Reports', route: '/reports', permission: 'analytics.view' },
  { label: 'Coupons', route: '/coupons', permission: 'coupons.view' },
  { label: 'Refunds', route: '/refunds', permission: 'refunds.view' },
  { label: 'Branding', route: '/branding', permission: 'config.view' },
  { label: 'Home Layout', route: '/home-layout', permission: 'home_layout.view' },
  { label: 'AI Prompts', route: '/ai-prompts', permission: 'ai_prompts.view' },
  { label: 'Notifications', route: '/notifications', permission: 'notifications.view' },
  { label: 'Support', route: '/support', permission: 'support.view' },
  { label: 'App Config', route: '/config', permission: 'config.view' },
  { label: 'Roles & Permissions', route: '/roles', permission: 'roles.view' },
  { label: 'Audit Logs', route: '/audit-logs', permission: 'audit_logs.view' },
];

const IDLE_MS = 30 * 60 * 1000; // 30-minute idle auto-logout (Section 4E)

@Component({
  selector: 'app-shell',
  standalone: true,
  imports: [RouterOutlet, RouterLink, RouterLinkActive],
  template: `
    <div class="shell">
      <aside class="sidebar">
        <div class="brand">🩺 VitalScan <span>Admin</span></div>
        <nav>
          @for (m of visibleModules(); track m.route) {
            <a [routerLink]="m.route" routerLinkActive="active">{{ m.label }}</a>
          }
        </nav>
      </aside>
      <div class="main">
        <header class="topbar">
          <div class="role">{{ auth.role() || 'admin' }}</div>
          <button class="btn-outline logout" (click)="logout()">Log out</button>
        </header>
        <main class="content"><router-outlet /></main>
      </div>
    </div>
  `,
  styles: [`
    .shell { display: flex; min-height: 100vh; }
    .sidebar { width: var(--sidebar-width); background: var(--surface); border-right: 1px solid var(--border); padding: 20px 12px; }
    .brand { font-weight: 700; font-size: 16px; padding: 0 12px 20px; }
    .brand span { color: var(--teal-700); }
    nav { display: flex; flex-direction: column; gap: 2px; }
    nav a { text-decoration: none; color: var(--text-secondary); padding: 10px 12px; border-radius: 10px; font-size: 14px; font-weight: 500; }
    nav a:hover { background: var(--surface-raised); color: var(--text-primary); }
    nav a.active { background: var(--teal-50); color: var(--teal-700); font-weight: 600; }
    .main { flex: 1; display: flex; flex-direction: column; }
    .topbar { height: 56px; background: var(--surface); border-bottom: 1px solid var(--border); display: flex; align-items: center; justify-content: flex-end; gap: 16px; padding: 0 20px; }
    .role { font-size: 13px; color: var(--text-secondary); text-transform: capitalize; }
    .logout { padding: 8px 14px; }
    .content { padding: 24px; overflow: auto; }
  `],
})
export class ShellComponent implements OnInit, OnDestroy {
  protected auth = inject(AuthService);
  private router = inject(Router);
  private idleTimer?: ReturnType<typeof setTimeout>;
  private reset = () => this.armIdle();

  readonly visibleModules = computed(() =>
    MODULES.filter((m) => this.auth.hasPermission(m.permission)),
  );

  ngOnInit(): void {
    ['click', 'keydown', 'mousemove'].forEach((e) => window.addEventListener(e, this.reset));
    this.armIdle();
  }

  ngOnDestroy(): void {
    ['click', 'keydown', 'mousemove'].forEach((e) => window.removeEventListener(e, this.reset));
    if (this.idleTimer) clearTimeout(this.idleTimer);
  }

  private armIdle(): void {
    if (this.idleTimer) clearTimeout(this.idleTimer);
    this.idleTimer = setTimeout(() => this.logout(), IDLE_MS);
  }

  logout(): void {
    this.auth.logout();
    this.router.navigate(['/login']);
  }
}
