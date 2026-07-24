# Production Email Setup

Production uses SMTP delivery for outbound email.

## Inspecting email configuration

Use the built-in doctor checks to inspect resolved Action Mailer config:

- `bin/rails email:doctor`
- `bin/rails email:doctor:launch_ready`

Normal doctor reports warnings for risky settings.
Launch-ready doctor fails for incomplete external email setup.

## Production behavior

The template uses SMTP in `config/environments/production.rb`:

- `config.action_mailer.delivery_method = :smtp`
- `config.action_mailer.perform_deliveries = true`
- `config.action_mailer.raise_delivery_errors = true`
- `config.action_mailer.smtp_settings` from env vars when present:
	- `SMTP_ADDRESS`
	- `SMTP_PORT`
	- `SMTP_USERNAME`
	- `SMTP_PASSWORD`
	- optional: `SMTP_AUTHENTICATION` (default `plain`)
	- optional: `SMTP_ENABLE_STARTTLS_AUTO` (default `true`)

If SMTP settings are missing or invalid, boot can still succeed, but mail-triggering flows will raise when delivery is attempted.

Find the errors in the admin panel SolidErrors ui at the /solid_errors path

## Expected behavior

- Mail-triggering flows rely on real provider credentials.
- Delivery failures raise errors (`raise_delivery_errors = true`).
- Misconfigured SMTP settings fail explicitly instead of silently dropping email.

## Moving to a real provider

Typical provider setup steps:

1. Choose an ESP.
2. Add any required gem.
3. Configure Action Mailer delivery method/settings for your provider.
4. Add secrets/environment variables required by that provider.
5. Verify sender/domain setup (SPF, DKIM, DMARC) per provider docs.

The template does not manage provider-specific integrations.
