# Notices

adhd-combo bundles unmodified copies of files from three projects.

## caveman

- Source: https://github.com/JuliusBrussee/caveman, commit `b4ee71d557d96e3cbc14f88fa6e953a1362865f5` (2026-11-13)
- Files: `skills/caveman`, `skills/ultracave`, `skills/megacave`, `skills/caveman-commit`, `skills/caveman-review`
- Copyright 2026 Julius Brussee. Apache License 2.0: `third_party/caveman/LICENSE`. Upstream NOTICE: `third_party/caveman/NOTICE`. Pre-3.0.0 MIT notice: `third_party/caveman/LICENSE-MIT`.
- "Caveman" is a trademark of Julius Brussee. This bundle is not the official Caveman and is not endorsed by Julius Brussee.

## ponytail

- Source: https://github.com/DietrichGebert/ponytail, commit `96608e078b2d5ea607c5c3b8b5a54d1c1fba6846` (2026-10-29)
- Files: `skills/ponytail`, `skills/ponytail-review`, `skills/ponytail-audit`, `skills/ponytail-debt`
- Copyright (c) 2026 DietrichGebert. MIT License: `third_party/ponytail/LICENSE`.

## i-have-adhd

- Source: https://github.com/ayghri/i-have-adhd, commit `1ecea1993b7fce257ffbd686c070948b5e07eda6` (2026-10-11)
- Files: `skills/i-have-adhd`
- Copyright (c) 2026 Ayoub Ghriss. MIT License: `third_party/i-have-adhd/LICENSE`.

## Changes

None of the files above were modified. adhd-combo adds its own files around them: `.claude-plugin/`, `hooks/`, `scripts/`, `skills/adhd-combo/`, `tests/`, `README.md`, `NOTICE.md` and `LICENSE`. Its hooks load the bundled `SKILL.md` files at session start in place of the upstream hooks.
