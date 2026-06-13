# plezy-apk-mirror

**This repository is only a mirror.** It does not contain any application source
code and it is not the home of the plezy app. It automatically takes the
official releases of [`edde746/plezy`](https://github.com/edde746/plezy),
extracts the Android `.apk` out of the upstream `.tar.gz` archives, and
republishes those APKs as GitHub releases here.

The single purpose is to let you **install and auto-update plezy through
[Obtainium](https://github.com/ImranR98/Obtainium)** directly from GitHub,
without going through the Google Play Store.

## Why this exists

Upstream ships Android builds as `plezy-android-<arch>.tar.gz` archives. Obtainium
(and most "install APK from GitHub releases" tools) expect a plain `.apk` asset
on the release. This mirror unpacks the archive and re-attaches the raw APK so
those tools can pick it up.

Nothing about the app is changed. The APK is byte-for-byte the one produced by
the upstream build and shipped inside the upstream archive.

## Install with Obtainium

1. Install [Obtainium](https://github.com/ImranR98/Obtainium).
2. Add an app using this repository URL:
   ```
   https://github.com/Yeradon/plezy-apk-mirror
   ```
3. Pick the APK that matches your device. Most modern phones are `arm64-v8a`.
   If Obtainium asks for a filter, use one of:
   - `arm64-v8a` (most phones)
   - `armeabi-v7a` (older 32-bit devices)
   - `x86_64` (emulators / x86 devices)
4. Install. Obtainium will then notify you and update whenever a new version is
   mirrored here.

Each release contains:

| Asset | Device |
| --- | --- |
| `plezy-<version>-arm64-v8a.apk` | Modern 64-bit ARM phones |
| `plezy-<version>-armeabi-v7a.apk` | Older 32-bit ARM phones |
| `plezy-<version>-x86_64.apk` | x86_64 devices / emulators |

## How the mirror works

A scheduled GitHub Actions workflow ([`.github/workflows/mirror.yml`](.github/workflows/mirror.yml))
runs every 6 hours. It checks the newest upstream release, and if it has not been
mirrored yet, it downloads the Android archives, extracts each `.apk`, renames it
per architecture, and creates a matching release here. The job is idempotent, so
re-runs only mirror genuinely new versions. See [`mirror.sh`](mirror.sh) for the
exact logic. You can also trigger it manually from the Actions tab; the
`mirror_limit` input lets you backfill more than just the latest release.

## License and attribution

plezy is created by the upstream author and licensed under the
**GNU General Public License v3.0 (GPL-3.0)**.

- Upstream project: https://github.com/edde746/plezy
- Upstream homepage: https://plezy.app
- Full license text, reproduced verbatim, lives in [`LICENSE`](LICENSE).

The APKs distributed here are the unmodified binaries from the upstream releases.
The **corresponding source code** for every mirrored version is available from the
matching upstream tag, which each release here links to directly
(`https://github.com/edde746/plezy/releases/tag/<version>`), satisfying the
source-availability requirement of the GPL.

All copyright and credit for the application belong to the upstream author. This
repository redistributes the binaries only. It is an unofficial mirror and is
**not affiliated with, sponsored by, or endorsed by** the upstream project.

If you are the upstream author and would like this mirror changed or taken down,
open an issue and it will be addressed.
