# Our App vs Healthians — A Plain‑English Comparison

**Version:** 1.0 · **Date:** 8 July 2026

This document explains, in everyday language, **what our app (Unique Diagnostic Centre) does**, **what Healthians does**, and **where we stand** — what we already have, what's half‑built, and what's genuinely missing. No technical jargon. A companion technical design document (`DESIGN_TECHNICAL.md`) has the engineering detail.

---

## 1. What both apps are, in one line

Both are **"lab tests at your doorstep"** apps: you pick a blood test or a health package, book a time, a trained person comes to your home to collect the sample, and you get your report in the app.

**Healthians** is a large, established Indian brand (250+ cities, 22 labs). **Our app** is a newer, white‑label platform that does the same core job and can be re‑branded for any diagnostics business (which Healthians cannot — that's our edge).

---

## 2. The customer journey — how our app works, step by step

1. **Open the app** → a splash screen with the logo, then (first time) a short intro.
2. **Sign in** → by email (a one‑time code is sent), or mobile number, or Google. You can also **"Browse as Guest"** without signing in.
3. **Browse** → the home screen shows offers, service shortcuts (Blood Tests, Full Body, MRI & Scans, Doctor Consult, etc.), popular packages, and your health score.
4. **Add to cart** → pick tests/packages; guests get a cart too, which carries over when they sign in.
5. **Book** → choose **who** the test is for (yourself or a family member), **where** (your saved address), and **when** (a home‑collection time slot).
6. **Confirm** → the booking is created and your slot is reserved. *(Online payment is still switched off — marked "coming soon.")*
7. **After the visit** → track the booking, download your report, ask for counselling, check your wallet points, and manage family members.

Healthians follows the same journey, and adds a few things we don't yet fully offer (see below).

---

## 3. Side‑by‑side comparison

**Key:** ✅ = we have it and it works · 🟡 = partly there (built underneath but not finished/visible) · ❌ = we don't have it yet.

### The essentials (booking a test)

| Feature | Healthians | Us |
|---|:---:|:---:|
| Book blood tests & full‑body packages | ✅ | ✅ |
| Home sample collection with time slots | ✅ | ✅ |
| Cart & guest cart (browse before signing in) | ✅ | ✅ |
| Add family members and book for them | ✅ | ✅ |
| Pay online (card/UPI) | ✅ | 🟡 *(ready but switched off)* |
| Pay cash at collection | ✅ | ❌ |
| Reschedule a booking | ✅ | 🟡 *(cancel works; reschedule not finished)* |
| Cancel a booking | ✅ | ✅ |
| Live tracking of the collection agent | ✅ | 🟡 *(status exists; no live map yet)* |
| Check if your area/pincode is serviceable | ✅ | 🟡 |

### Reports & health

| Feature | Healthians | Us |
|---|:---:|:---:|
| Digital report (PDF) in the app | ✅ | ✅ |
| Report trends over time / smart insights | ✅ | 🟡 |
| Personalised diet plan from your report | ✅ | 🟡 *(built underneath, not shown)* |
| Free doctor consultation on your report | ✅ | 🟡 *(can request; no scheduling)* |
| Report sent on WhatsApp / hard copy by courier | ✅ | 🟡 |
| Health score (like "Health Karma") | ✅ | ✅ |
| Track weight / BP / sugar / steps | ✅ | 🟡 |
| AI health assistant ("Wellio") | ✅ | ✅ *(ours is also called Wellio)* |

### Money, loyalty & extras

| Feature | Healthians | Us |
|---|:---:|:---:|
| Wallet points / cashback (HCash) | ✅ | ✅ |
| Coupons & offers | ✅ | ✅ |
| Refer a friend & earn | ✅ | 🟡 *(code exists; rewards flow not built)* |
| Notifications (WhatsApp/SMS/push) | ✅ | 🟡 *(engine built; no notifications screen)* |
| Health & nutrition articles | ✅ | 🟡 *(content is there; no screen)* |
| Recurring test plan / subscription | ✅ | 🟡 |
| Corporate / employee health | ✅ | 🟡 |
| **Radiology & scans (MRI, CT, X‑Ray, ECG…)** | ✅ | ❌ *(only an info page, no booking)* |

### Where WE are ahead

| Feature | Healthians | Us |
|---|:---:|:---:|
| **Re‑brandable for any lab business (white‑label)** | ❌ | ✅ |
| Strong privacy/security (data encryption, anti‑tamper) | — | ✅ |
| Guest cart that survives closing the app | — | ✅ |
| Built‑in admin tools (coupons, refunds, analytics) | ✅ | ✅ |

---

## 4. What this means, honestly

**We are at parity with Healthians on the core job** — browsing tests, building a cart, and booking a home collection for yourself or family, plus wallet, health score, AI assistant, and admin tooling. In one area — **white‑label branding** — we're ahead: our app can become "any" diagnostics brand, which is a real commercial advantage.

The gap with Healthians is mostly about **finishing and surfacing** things, not building from scratch:

- **A lot is already built in the backend but not visible in the app** — online payment, reschedule, notifications, articles, diet plans, subscriptions, referrals. These are "last‑mile" tasks: connect the screen to the engine that already exists.
- **A few things are genuinely missing** and need real work — **radiology/scans booking**, **cash‑on‑collection**, **live agent tracking**, and the **refer‑and‑earn** rewards flow.

---

## 5. What to build next (recommended order)

1. **Turn on payments** — online (card/UPI) is ready; add cash‑on‑collection. *Biggest revenue unlock.*
2. **Finish the booking lifecycle** — reschedule + a clear order‑tracking screen.
3. **Show what we already have** — notifications, articles, subscriptions, and referral rewards screens.
4. **Close the real gaps** — radiology/scans booking, diet plans, doctor‑consult scheduling.
5. **Serviceability check** — tell users up front whether we cover their area.

Doing 1–3 first gets us to a **complete, Healthians‑equivalent everyday experience** quickly, because the hard part (the backend) is already done.

---

## 6. Sources (Healthians benchmark)

- Healthians — official site & product overview: https://www.healthians.com/
- Healthians app (Google Play): https://play.google.com/store/apps/details?id=com.healthians.main.healthians
- Healthians app (Apple App Store): https://apps.apple.com/in/app/healthians-full-body-checkup/id1453011241
- Healthians Health Packages: https://www.healthians.com/popular-package
- Healthians Scans & Imaging: https://www.healthians.com/scans
- Healthians FAQ (booking, tracking, cancel, reports): https://www.healthians.com/faq
- Healthians Refund Policy: https://www.healthians.com/refund-policy
- Referral program overview: https://allreferearnapp.com/healthians-refer-and-earn
