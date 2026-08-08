import { Injectable, computed, inject, signal } from '@angular/core';
import { HttpClient } from '@angular/common/http';
import { firstValueFrom } from 'rxjs';

import { API_BASE_URL } from './api.config';

interface Envelope<T> { success: boolean; data: T; message: string; }

/**
 * Admin auth (Section 11 / 4A): email + password + mandatory TOTP.
 * Access token kept in memory only; refresh token in sessionStorage (cleared on
 * tab close). Permissions loaded from /auth/me/permissions and held in a signal.
 */
@Injectable({ providedIn: 'root' })
export class AuthService {
  private http = inject(HttpClient);

  private _accessToken: string | null = null;
  readonly role = signal<string>('');
  readonly permissions = signal<readonly string[]>([]);
  readonly twoFactorPending = signal(false);
  /** First login: the user must scan a TOTP secret before verifying. */
  readonly enrollPending = signal(false);

  readonly isAuthenticated = computed(() => this.permissions().length > 0 || !!this._accessToken);

  get accessToken(): string | null {
    return this._accessToken;
  }

  hasPermission(code: string): boolean {
    return this.permissions().includes(code);
  }

  /** Step 1 — email + password. Normally moves to a 2FA step; under the dev-only
   * server bypass the response carries tokens directly and we skip 2FA. */
  async login(email: string, password: string): Promise<void> {
    const res = await firstValueFrom(
      this.http.post<Envelope<any>>(`${API_BASE_URL}/auth/admin/login`, { email, password }),
    );
    const data = res.data ?? res;
    // Dev bypass (Auth:DisableAdmin2fa): tokens returned straight away.
    const tokens = data?.tokens ?? data?.Tokens;
    if (tokens) {
      await this.applyTokens(tokens);
      this.twoFactorPending.set(false);
      this.enrollPending.set(false);
      return;
    }
    sessionStorage.setItem('admin_2fa_session', data?.sessionId ?? data?.session_id ?? '');
    // First login → enrollment required; otherwise straight to code entry.
    this.enrollPending.set(!!(data?.enrollRequired ?? data?.enroll_required));
    this.twoFactorPending.set(true);
  }

  /**
   * First-login enrollment — returns the TOTP secret + otpauth URI to render a QR,
   * plus single-use backup codes shown once. Verify a code afterwards to finish.
   */
  async enroll(): Promise<{ secret: string; otpAuthUri: string; backupCodes: string[] }> {
    const sessionId = sessionStorage.getItem('admin_2fa_session') ?? '';
    const res = await firstValueFrom(
      this.http.post<Envelope<any>>(`${API_BASE_URL}/auth/admin/2fa/enroll`, { sessionId }),
    );
    const data = res.data ?? res;
    return {
      secret: data.secret,
      otpAuthUri: data.otpAuthUri ?? data.otp_auth_uri,
      backupCodes: (data.backupCodes ?? data.backup_codes ?? []) as string[],
    };
  }

  /** Step 2 — TOTP (or backup) code. */
  async verify2fa(code: string): Promise<void> {
    const sessionId = sessionStorage.getItem('admin_2fa_session') ?? '';
    const res = await firstValueFrom(
      this.http.post<Envelope<any>>(`${API_BASE_URL}/auth/admin/2fa/verify`, { sessionId, code }),
    );
    await this.applyTokens(res.data ?? res);
    this.twoFactorPending.set(false);
    this.enrollPending.set(false);
  }

  /**
   * On app boot, silently restore a session from the refresh token kept in
   * sessionStorage (survives a page refresh; cleared on tab close). Without it —
   * or if the token is stale/revoked — we stay logged out. Runs via
   * provideAppInitializer so guards see the restored permissions before routing.
   */
  async restore(): Promise<void> {
    const refresh = sessionStorage.getItem('admin_refresh');
    if (!refresh) return;
    try {
      const res = await firstValueFrom(
        // deviceInfo MUST be "admin-portal" — refresh tokens are device-bound
        // (RefreshAsync rejects a mismatched DeviceId), and AdminAuthService issues
        // them under the literal "admin-portal". Any other string → 401 → logout.
        this.http.post<Envelope<any>>(`${API_BASE_URL}/auth/token/refresh`, {
          refreshToken: refresh,
          deviceInfo: 'admin-portal',
        }),
      );
      await this.applyTokens(res.data ?? res);
    } catch {
      this.logout();
    }
  }

  private async applyTokens(data: any): Promise<void> {
    this._accessToken = (data.accessToken ?? data.access_token) ?? null;
    const refresh = data.refreshToken ?? data.refresh_token;
    if (refresh) sessionStorage.setItem('admin_refresh', refresh);
    await this.loadPermissions();
  }

  /** Loads role + permission codes (drives sidebar, guards, directives). */
  async loadPermissions(): Promise<void> {
    const res = await firstValueFrom(
      this.http.get<Envelope<any>>(`${API_BASE_URL}/auth/me/permissions`),
    );
    const data = res.data ?? res;
    this.role.set((data.role ?? '').toString());
    this.permissions.set((data.permissions ?? []) as string[]);
  }

  logout(): void {
    this._accessToken = null;
    this.role.set('');
    this.permissions.set([]);
    sessionStorage.clear();
  }
}
