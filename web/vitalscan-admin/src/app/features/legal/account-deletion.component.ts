import { Component } from '@angular/core';

/**
 * Public account & data deletion instructions. Play Console requires a
 * reachable URL that explains how a user requests deletion of their account and
 * data, what is deleted, and what (if anything) is retained. Served without
 * authentication at /account-deletion.
 */
@Component({
  selector: 'app-account-deletion',
  standalone: true,
  template: `
    <main class="legal">
      <header>
        <h1>Account &amp; Data Deletion</h1>
        <p class="meta">Unique Diagnostic Centre · Last updated 8 August 2026</p>
      </header>

      <p>
        You can request deletion of your <strong>Unique Diagnostic Centre</strong>
        account and the personal and health data associated with it at any time.
      </p>

      <h2>How to request deletion</h2>
      <p>Choose either option:</p>
      <ul>
        <li><strong>In the App</strong> — open the App, go to
          <em>Profile → Delete account</em>, and confirm. Your account is
          scheduled for deletion immediately.</li>
        <li><strong>By email</strong> — send a request from your registered email
          address to
          <a href="mailto:harshal.patil0526&#64;gmail.com?subject=Delete%20my%20account">
          harshal.patil0526&#64;gmail.com</a> with the subject “Delete my account”.
          We verify the request and complete deletion within 30 days.</li>
      </ul>

      <h2>What gets deleted</h2>
      <ul>
        <li>Your profile and contact details (name, email, mobile number).</li>
        <li>Your saved addresses and device notification tokens.</li>
        <li>Your bookings and diagnostic test reports held in your account,
          including family members you added.</li>
      </ul>

      <h2>What may be retained</h2>
      <p>
        Certain records are kept only where the law requires it — for example,
        transaction and invoice records needed for tax and accounting, and
        diagnostic records we are obliged to retain under applicable medical
        record-keeping regulations. These are retained for the legally mandated
        period and then deleted or irreversibly anonymised. Retained records are
        not used for any other purpose.
      </p>

      <h2>Contact</h2>
      <p>
        Bit2Sky India Pvt. Ltd.<br />
        Email: <a href="mailto:harshal.patil0526&#64;gmail.com">harshal.patil0526&#64;gmail.com</a>
      </p>
    </main>
  `,
  styles: [`
    .legal {
      max-width: 760px;
      margin: 0 auto;
      padding: 40px 20px 80px;
      color: #1f2933;
      background: #fff;
      font: 16px/1.6 system-ui, -apple-system, 'Segoe UI', Roboto, sans-serif;
    }
    header { border-bottom: 2px solid #0d9488; padding-bottom: 16px; margin-bottom: 24px; }
    h1 { margin: 0; font-size: 28px; color: #0f766e; }
    .meta { color: #64748b; margin: 6px 0 0; font-size: 14px; }
    h2 { font-size: 19px; margin: 28px 0 8px; color: #0f172a; }
    ul { padding-left: 22px; }
    li { margin: 6px 0; }
    a { color: #0d9488; }
    strong { color: #0f172a; }
    em { color: #0f766e; font-style: normal; font-weight: 600; }
  `],
})
export class AccountDeletionComponent {}
