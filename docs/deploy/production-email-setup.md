# Production Email Setup

This guide covers production email decisions, configuration, and launch validation. Follow general Rails email setup instructions as well as those of your ESP. This document is a high level checklist written in preparation for initial launch, but should not be considered exhaustive for all future email needs. Update and expand as your product and email requirements evolve.

## 1) Choose an Email Service Provider

Choose one provider for transactional email delivery.

Selection criteria:
- Deliverability and reputation tooling
- API and SMTP support
- Webhooks for delivery and bounce events
- Cost and regional coverage

Examples:
- Postmark
- Resend
- SendGrid
- Amazon SES

## 2) Define Required Environment Variables

Set these values in your production environment.

Core host values:
- APP_HOST
- FRONTEND_URL
- API_URL

Mailer credentials:
- SMTP or API credentials from your ESP

Recommended sender values:
- MAILER_SENDER

## 3) Configure Action Mailer Host

Set default URL options in production config so links in emails point to your deployed host.

Example:

    config.action_mailer.default_url_options = {
      host: ENV.fetch("APP_HOST")
    }

Also ensure mail delivery is enabled in production and configured for your chosen transport.

## 4) Set Sender Identity And Domain Authentication

Replace Devise placeholder sender with a real domain sender in the Devise initializer.

Example:

    config.mailer_sender = "no-reply@yourdomain.com"

Complete sender domain setup:
- SPF
- DKIM
- DMARC

Do not go live until domain authentication is passing in your ESP dashboard.

## 5) Decide Which Emails Are Enabled At Launch

Minimum recommended launch scope:
- Admin password reset
- User password reset
- User confirmation

Optional, based on product readiness:
- Transactional product emails

Document owners for each email type and expected triggers.

## 6) Add Production Smoke Test Runbook

After deploy, run this checklist:

1. Trigger user password reset.
2. Confirm message delivery in app mailbox and ESP activity logs.
3. Validate links resolve to production host.
4. Check spam placement across at least two providers.
5. Trigger admin password reset and confirm delivery.
6. Confirm user confirmation email delivery for a new account.

## 7) Monitoring And Failure Handling

Add monitoring before launch:
- Track mail delivery failures and timeouts.
- Monitor bounce and complaint rates.
- Alert on sustained delivery failures.

Recommended implementation notes:
- Subscribe to ESP webhook events.
- Log mailer message IDs for traceability.
- Define an escalation path for incident response.

## 8) Launch Readiness Checklist

Mark each item complete before production launch:
- ESP selected and credentials configured
- APP_HOST, FRONTEND_URL, API_URL set
- Action Mailer default host configured
- Devise mailer sender updated
- SPF, DKIM, DMARC validated
- Required email types enabled
- Smoke test runbook executed successfully
- Monitoring and alerts enabled
