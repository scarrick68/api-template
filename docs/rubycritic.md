# RubyCritic Code Quality Metrics

This template includes RubyCritic for Ruby code quality metrics and report visualization.

## What Is Included

- RubyCritic gem in development/test groups.
- Local command wrapper: `bin/quality`.
- CI integration: `bin/ci` runs `bin/quality --no-browser` as a quality step.
- Generated HTML report UI under `tmp/rubycritic/`.

## Run Locally

Generate metrics and open report in browser:

```bash
bin/quality
```

Generate metrics without opening browser:

```bash
bin/quality --no-browser
```

## Report UI Location

Primary report entrypoint:

- `tmp/rubycritic/overview.html`

This is a local generated artifact and can be regenerated any time.

## RubyCritic vs SimpleCov

RubyCritic uses SimpleCov coverage reports, but the results are not always consistent with SimpleCov. SimpleCov is more accurate for coverage and should be considered the source of truth for coverage metrics.