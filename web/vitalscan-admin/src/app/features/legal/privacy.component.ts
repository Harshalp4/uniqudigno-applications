import { Component } from '@angular/core';

/**
 * Public privacy policy for the Unique Diagnostic customer app. Reachable
 * without authentication at /privacy — this URL is what Play Console requires,
 * and it must specifically cover the health data the app handles.
 */
@Component({
  selector: 'app-privacy',
  standalone: true,
  template: `
    <main class="legal">
      <header>
        <h1>Privacy Policy</h1>
        <p class="meta">Unique Diagnostic Centre · Last updated 8 August 2026</p>
      </header>

      <p>
        This Privacy Policy explains how <strong>Bit2Sky India Pvt. Ltd.</strong>
        (“we”, “us”, “our”), operator of the <strong>Unique Diagnostic Centre</strong>
        mobile application (the “App”), collects, uses, discloses, and protects
        your information. Because the App handles diagnostic and health
        information, we treat that data as sensitive and process it only as
        described below. By using the App you agree to this Policy.
      </p>

      <h2>1. Information we collect</h2>
      <ul>
        <li><strong>Account &amp; contact details</strong> — your name, email
          address, and mobile number, used to create and secure your account.</li>
        <li><strong>Health information</strong> — the diagnostic tests and
          packages you book, sample-collection details, and the test reports
          generated for you and any family members you add.</li>
        <li><strong>Address &amp; location</strong> — the address you provide for
          at-home sample collection. Precise location is used only, and only with
          your permission, to help you enter that address; it is optional.</li>
        <li><strong>Payment information</strong> — payments are processed by our
          payment partner (Razorpay). We receive confirmation of a transaction
          but do not store your full card or bank details.</li>
        <li><strong>Device &amp; usage data</strong> — a device push token (for
          notifications) and basic technical logs needed to operate and secure
          the service.</li>
      </ul>

      <h2>2. How we use your information</h2>
      <ul>
        <li>To book, fulfil, and manage your diagnostic tests and sample collection.</li>
        <li>To deliver your test reports securely within the App.</li>
        <li>To process payments and issue refunds.</li>
        <li>To send you booking, report, and account notifications.</li>
        <li>To provide customer support and comply with legal and medical
          record-keeping obligations.</li>
      </ul>

      <h2>3. How we share your information</h2>
      <p>We do not sell your personal or health information. We share it only:</p>
      <ul>
        <li>with the diagnostic laboratories and phlebotomists fulfilling your
          booking;</li>
        <li>with our payment processor to complete transactions;</li>
        <li>with service providers (e.g. cloud hosting, messaging) bound by
          confidentiality obligations; and</li>
        <li>where required by law or to protect the rights and safety of users.</li>
      </ul>

      <h2>4. Data security</h2>
      <p>
        Health information is encrypted in transit and at rest, and access is
        restricted to authorised personnel. In-app viewing of reports can be
        protected by your device biometric lock. No method of transmission or
        storage is completely secure, but we work to protect your data using
        industry-standard safeguards.
      </p>

      <h2>5. Data retention</h2>
      <p>
        We retain your account and health records for as long as your account is
        active and as required by applicable medical record-keeping laws. You can
        request deletion at any time (see below), after which we delete or
        irreversibly anonymise your data except where retention is legally
        required.
      </p>

      <h2>6. Your rights &amp; choices</h2>
      <ul>
        <li>Access, correct, or update your profile from within the App.</li>
        <li>Withdraw notification or location permissions from your device settings.</li>
        <li>Request deletion of your account and associated data — see our
          <a href="/account-deletion">Account &amp; Data Deletion</a> page.</li>
      </ul>

      <h2>7. Children</h2>
      <p>
        The App is not directed to children under 18, who should use it only
        through a parent or guardian’s account.
      </p>

      <h2>8. Changes to this Policy</h2>
      <p>
        We may update this Policy from time to time. Material changes will be
        reflected by the “Last updated” date above.
      </p>

      <h2>9. Contact us</h2>
      <p>
        Questions or requests about this Policy or your data:<br />
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
  `],
})
export class PrivacyComponent {}
