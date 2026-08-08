import { Routes } from '@angular/router';

import { authGuard, permissionGuard } from './core/guards';
import { LoginComponent } from './features/login/login.component';
import { ShellComponent } from './features/shell/shell.component';
import { DashboardComponent } from './features/dashboard/dashboard.component';
import { RolesComponent } from './features/roles/roles.component';
import { UsersComponent } from './features/users/users.component';
import { BookingsComponent } from './features/bookings/bookings.component';
import { BrandingComponent } from './features/branding/branding.component';
import { HomeLayoutComponent } from './features/home-layout/home-layout.component';
import { CouponsComponent } from './features/coupons/coupons.component';
import { AuditLogsComponent } from './features/audit-logs/audit-logs.component';
import { TestsComponent } from './features/tests/tests.component';
import { PackagesComponent } from './features/packages/packages.component';
import { CategoriesComponent } from './features/categories/categories.component';
import { RefundsComponent } from './features/refunds/refunds.component';
import { ReportsComponent } from './features/reports/reports.component';
import { ConfigComponent } from './features/config/config.component';
import { AiPromptsComponent } from './features/ai-prompts/ai-prompts.component';
import { NotificationsComponent } from './features/notifications/notifications.component';
import { SupportComponent } from './features/support/support.component';
import { UnauthorizedComponent } from './features/shared/unauthorized.component';
import { PrivacyComponent } from './features/legal/privacy.component';
import { AccountDeletionComponent } from './features/legal/account-deletion.component';

export const routes: Routes = [
  { path: '', pathMatch: 'full', redirectTo: 'dashboard' },
  { path: 'login', component: LoginComponent },
  // Public legal pages (no auth) — the URLs Play Console requires for the app.
  { path: 'privacy', component: PrivacyComponent },
  { path: 'account-deletion', component: AccountDeletionComponent },
  {
    path: '',
    component: ShellComponent,
    canActivate: [authGuard],
    children: [
      { path: 'dashboard', component: DashboardComponent, canActivate: [permissionGuard('analytics.view')] },
      { path: 'roles', component: RolesComponent, canActivate: [permissionGuard('roles.view')] },
      { path: 'users', component: UsersComponent, canActivate: [permissionGuard('users.view')] },
      { path: 'bookings', component: BookingsComponent, canActivate: [permissionGuard('bookings.view')] },
      { path: 'tests', component: TestsComponent, canActivate: [permissionGuard('tests.view')] },
      { path: 'packages', component: PackagesComponent, canActivate: [permissionGuard('packages.view')] },
      { path: 'categories', component: CategoriesComponent, canActivate: [permissionGuard('categories.view')] },
      { path: 'reports', component: ReportsComponent, canActivate: [permissionGuard('analytics.view')] },
      { path: 'coupons', component: CouponsComponent, canActivate: [permissionGuard('coupons.view')] },
      { path: 'refunds', component: RefundsComponent, canActivate: [permissionGuard('refunds.view')] },
      { path: 'branding', component: BrandingComponent, canActivate: [permissionGuard('config.view')] },
      { path: 'home-layout', component: HomeLayoutComponent, canActivate: [permissionGuard('home_layout.view')] },
      { path: 'ai-prompts', component: AiPromptsComponent, canActivate: [permissionGuard('ai_prompts.view')] },
      { path: 'notifications', component: NotificationsComponent, canActivate: [permissionGuard('notifications.view')] },
      { path: 'support', component: SupportComponent, canActivate: [permissionGuard('support.view')] },
      { path: 'config', component: ConfigComponent, canActivate: [permissionGuard('config.view')] },
      { path: 'audit-logs', component: AuditLogsComponent, canActivate: [permissionGuard('audit_logs.view')] },
      { path: 'unauthorized', component: UnauthorizedComponent },
    ],
  },
  { path: '**', redirectTo: 'dashboard' },
];
