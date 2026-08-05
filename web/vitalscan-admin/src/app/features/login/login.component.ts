import { Component, inject, signal } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { Router } from '@angular/router';

import { AuthService } from '../../core/auth.service';

@Component({
  selector: 'app-login',
  standalone: true,
  imports: [FormsModule],
  template: `
    <div class="login-wrap">
      <div class="card login-card">
        <div class="brand">🩺 VitalScan <span>Admin</span></div>
        @if (!auth.twoFactorPending()) {
          <h1>Welcome back</h1>
          <p class="sub">Sign in with your admin credentials</p>
          <label class="field-label">Email</label>
          <input class="input" type="email" [(ngModel)]="email" autocomplete="username" />
          <label class="field-label" style="margin-top:12px">Password</label>
          <input class="input" type="password" [(ngModel)]="password" autocomplete="current-password" />
          @if (error()) { <p class="error">{{ error() }}</p> }
          <button class="btn full" [disabled]="busy()" (click)="signIn()">
            {{ busy() ? 'Signing in…' : 'Continue' }}
          </button>
          <!-- Honeypot (bot trap) — must stay empty (Section 4A). -->
          <input class="hp" name="website" [(ngModel)]="honeypot" tabindex="-1" autocomplete="off" />
        } @else if (auth.enrollPending() && enroll()) {
          <h1>Set up two-factor</h1>
          <p class="sub">Add this key to your authenticator app, then enter a code to confirm.</p>
          <label class="field-label">Secret key (manual entry)</label>
          <div class="secret">{{ enroll()!.secret }}</div>
          <div class="backup">
            <label class="field-label">Backup codes — save these now, each works once</label>
            <div class="codes">
              @for (c of enroll()!.backupCodes; track c) { <span>{{ c }}</span> }
            </div>
          </div>
          <label class="field-label" style="margin-top:16px">Authenticator code</label>
          <input class="input code" maxlength="6" inputmode="numeric" [(ngModel)]="otp" />
          @if (error()) { <p class="error">{{ error() }}</p> }
          <button class="btn full" [disabled]="busy()" (click)="verify()">
            {{ busy() ? 'Verifying…' : 'Confirm & sign in' }}
          </button>
        } @else {
          <h1>Two-factor code</h1>
          <p class="sub">Enter the 6-digit code from your authenticator app</p>
          <input class="input code" maxlength="6" inputmode="numeric" [(ngModel)]="otp" />
          @if (error()) { <p class="error">{{ error() }}</p> }
          <button class="btn full" [disabled]="busy()" (click)="verify()">
            {{ busy() ? 'Verifying…' : 'Verify' }}
          </button>
        }
      </div>
    </div>
  `,
  styles: [`
    .login-wrap { min-height: 100vh; display: grid; place-items: center; padding: 24px; }
    .login-card { width: 380px; }
    .brand { font-weight: 700; font-size: 18px; margin-bottom: 24px; }
    .brand span { color: var(--teal-700); }
    h1 { font-size: 24px; margin: 0 0 4px; }
    .sub { color: var(--text-secondary); margin: 0 0 24px; font-size: 14px; }
    .full { width: 100%; margin-top: 20px; }
    .error { color: var(--error); font-size: 13px; margin: 12px 0 0; }
    .code { letter-spacing: 8px; text-align: center; font-size: 20px; }
    .hp { position: absolute; left: -9999px; }
    .secret { font-family: monospace; font-size: 15px; letter-spacing: 2px; word-break: break-all;
              background: var(--bg-muted, #f1f5f9); border-radius: 8px; padding: 10px 12px; margin: 4px 0 16px; }
    .backup .codes { display: grid; grid-template-columns: repeat(2, 1fr); gap: 6px; margin-top: 4px; }
    .backup .codes span { font-family: monospace; font-size: 13px; background: var(--bg-muted, #f1f5f9);
                          border-radius: 6px; padding: 5px 8px; text-align: center; }
  `],
})
export class LoginComponent {
  protected auth = inject(AuthService);
  private router = inject(Router);

  email = '';
  password = '';
  otp = '';
  honeypot = '';
  busy = signal(false);
  error = signal('');
  enroll = signal<{ secret: string; otpAuthUri: string; backupCodes: string[] } | null>(null);

  async signIn(): Promise<void> {
    if (this.honeypot) return; // bot detected
    this.busy.set(true);
    this.error.set('');
    try {
      await this.auth.login(this.email.trim(), this.password);
      // Dev bypass: already authenticated, no 2FA — go straight in.
      if (!this.auth.twoFactorPending() && this.auth.isAuthenticated()) {
        this.router.navigate(['/dashboard']);
        return;
      }
      // First login → fetch the TOTP secret + backup codes to render the enroll step.
      if (this.auth.enrollPending()) {
        this.enroll.set(await this.auth.enroll());
      }
    } catch {
      this.error.set('Invalid email or password.');
    } finally {
      this.busy.set(false);
    }
  }

  async verify(): Promise<void> {
    this.busy.set(true);
    this.error.set('');
    try {
      await this.auth.verify2fa(this.otp.trim());
      this.router.navigate(['/dashboard']);
    } catch {
      this.error.set('Incorrect code. Try again.');
    } finally {
      this.busy.set(false);
    }
  }
}
