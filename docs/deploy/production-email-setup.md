# Production Email Setup

This template keeps production email setup intentionally simple.

## Default behavior

The template sets Action Mailer to the non-delivering test adapter in `config/environments/production.rb`:

- `config.action_mailer.delivery_method = :test`
- `config.action_mailer.perform_deliveries = true`
- `config.action_mailer.raise_delivery_errors = false`

This allows signup and other mail-triggering flows to complete without SMTP infrastructure.

## What works in default mode

- No SMTP connection attempts are made.
- Mailer rendering still happens.
- `deliver_now` and `deliver_later` calls do not fail due to missing ESP credentials.
- Operators can manually confirm users through Avo during launch testing.

## Limitations in default mode

- No email is delivered to recipients.
- Confirmation, reset, and other outbound-user email flows are not externally functional.

## Moving to a real provider

When you are ready for real delivery, replace the test-delivery block in `config/environments/production.rb` with your provider's normal Rails setup.

Typical steps:

1. Choose an ESP.
2. Add any required gem.
3. Configure Action Mailer delivery method/settings in production config and/or an initializer.
4. Add secrets/environment variables required by that provider.
5. Verify sender/domain setup (SPF, DKIM, DMARC) per provider docs.

The template does not manage provider-specific integrations.
