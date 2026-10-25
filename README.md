Strada
======

[![Tests](https://github.com/dblock/discord-strava/actions/workflows/test.yml/badge.svg)](https://github.com/dblock/discord-strava/actions/workflows/test.yml)
[![Coverage](https://img.shields.io/badge/coverage-88.62%25-brightgreen)](https://github.com/dblock/discord-strava)

Integrate Strava into Discord. Hosted at [strada.playplay.io](https://strada.playplay.io/).

## Install

[Add to your Discord Server](https://strada.playplay.io)

## Website artwork

The shared website layout uses the editable `public/img/screenshot-background.svg`, adapted from Strata's ribbon artwork with a logo-derived black palette (base `#000000`). The SVG preserves `preserveAspectRatio="none"` and is painted on a fixed viewport-sized layer so expanding help does not resize the background. Keep the transparent shoe logo, matching multi-resolution favicon, and original transparent `public/img/notify.png` hero when updating the design.

## Website caching

Local template assets use `asset_path` content hashes, including favicon, social and checkout images. The generated `styles.css.erb` versions its nested ribbon artwork and revalidates with `Cache-Control: private, no-cache`; template timestamps cannot validate changes to nested assets. Static ETags and timestamps retain their defaults. Old `?v=` URLs serve current files, not archived versions; do not apply immutable or long-lived caching.

### Copyright & License

Copyright [Daniel Doubrovkine, Vestris LLC](https://www.vestris.com), 2023-2025

[MIT License](LICENSE)
