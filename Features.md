1️⃣ USER ONBOARDING & AUTH

Authentication

 Phone number login

 OTP-based authentication

 JWT session management

 Secure token storage (mobile)

 Logout & session invalidation

User Profile

 Basic profile creation (name, email, phone)

 PAN collection & validation

 Address capture

 DOB & age validation (18+)

2️⃣ KYC & COMPLIANCE

KYC Flow

 Aadhaar-based eKYC OR Video KYC

 PAN verification (mandatory)

 KYC status tracking (Pending / Verified / Failed)

 Re-KYC handling (expired KYC)

 User-visible KYC progress screen

Compliance

 SEBI disclaimer display

 Digital gold risk disclaimer

 Terms & Conditions acceptance

 Privacy policy acceptance

 Audit-log creation for every compliance action

3️⃣ PORTFOLIO & INVESTMENT SETUP

Portfolio Selection

 Conservative portfolio

 Balanced portfolio

 Growth portfolio

 Asset allocation mapping (Equity / Debt / Gold)

 Portfolio change flow (with confirmation)

Investment Rules

 Investment frequency (daily / weekly batch)

 Market holiday handling

 Investment failure retry logic

 Minimum & maximum investment caps

4️⃣ ROUND-UP ENGINE (CORE FEATURE)

Round-Up Logic

 Round to nearest ₹10

 Round to nearest ₹50

 Round to nearest ₹100

 User-configurable rounding rule

 Daily roundup cap

 Monthly roundup cap

Round-Up Accumulation

 Track per-transaction roundups

 Daily roundup aggregation

 Monthly summary calculation

 Refund / reversal handling

5️⃣ UPI AUTOPAY & PAYMENTS

UPI Mandate

 UPI AutoPay mandate creation

 Mandate OTP confirmation

 Mandate status tracking (Active / Paused / Cancelled)

 Mandate pause/resume

 Mandate cancellation

Payment Execution

 Daily/weekly debit trigger

 24-hour pre-debit notification

 Failed debit retry logic

 Insufficient balance handling

 User notification on debit success/failure

6️⃣ INVESTMENT EXECUTION

Mutual Funds

 Mutual Fund Utility (MFU) integration

 Buy order placement

 Order confirmation tracking

 NAV fetch & units calculation

 SIP / lump-sum handling

 Redemption (withdrawal) flow

Digital Gold

 SafeGold API integration

 Gold purchase execution

 Gold balance tracking (grams)

 Sell gold / withdraw funds

 Custody & vault confirmation

7️⃣ LEDGER & TRANSACTION SYSTEM (CRITICAL)

Ledger

 Immutable transaction ledger

 Debit entries

 Credit entries

 Investment mapping

 Unique transaction IDs

 Idempotency support

Audit Logs

 Login events

 Mandate events

 Payment events

 Investment events

 Compliance events

 Tamper-proof storage

8️⃣ DASHBOARD & USER EXPERIENCE

Dashboard

 Total invested amount

 Current portfolio value

 This month’s roundup amount

 Growth chart (time-series)

 Asset allocation chart

Activity

 Transaction history list

 Investment history list

 Pending transactions view

 Failed transactions view

9️⃣ SETTINGS & CONTROLS

User Controls

 Pause investing

 Resume investing

 Change rounding rule

 Change portfolio

 Withdraw funds

 Close account

Preferences

 Notification preferences

 Investment reminders

 Language / locale settings (₹ formatting)

🔔 NOTIFICATIONS & COMMUNICATION

 OTP messages

 Mandate creation notification

 Pre-debit notification (24h rule)

 Debit success/failure notification

 Investment confirmation

 Monthly investment summary

 Compliance alerts

☁️ INFRASTRUCTURE & DEVOPS

Backend

 Flask app modular structure

 REST APIs with versioning

 Background jobs / cron workers

 Webhook handlers

 Rate limiting

Database

 PostgreSQL setup

 Daily backups

 Migration system

 Read/write separation (optional)

Deployment

 Dockerized backend

 Nginx reverse proxy

 Gunicorn / WSGI server

 CI/CD pipeline

 Staging environment

 Production environment

🔐 SECURITY & RELIABILITY

 HTTPS everywhere

 Encrypted data at rest

 Secure secrets management

 Role-based access control

 API authentication middleware

 Penetration testing

 Disaster recovery plan

 Uptime monitoring (99.9%)

📊 ANALYTICS & METRICS

Product Metrics

 User activation rate

 KYC completion rate

 DAU / MAU

 7-day & 30-day retention

 Average monthly investment/user

 Assets Under Management (AUM)

Business Metrics

 Subscription status tracking

 Revenue per user

 Churn rate

 LTV / CAC calculation

🧾 LEGAL & BUSINESS

 SEBI RIA or MFD registration flow

 Fee-only advisory logic (if RIA)

 Commission logic (if MFD)

 Risk disclosures

 Data retention policies

 Regulatory reporting support

🟢 MVP MINIMUM (NON-NEGOTIABLE)

For first public launch, these MUST be done:

✅ UPI mandate creation

✅ Roundup calculation

✅ At least ONE investment option (MF or Gold)

✅ Ledger + audit logs

✅ Withdraw anytime

✅ KYC compliant

✅ Transparent dashboard