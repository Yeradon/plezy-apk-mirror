#!/usr/bin/env bash
# Mirror Android APKs from the upstream plezy releases into this repository.
#
# For each upstream release it downloads the Android *.tar.gz archives,
# extracts the contained .apk, renames it per architecture, and republishes
# the APKs under the same tag in this repo. Idempotent: tags that already
# exist here are skipped, so the job is safe to run on a schedule.
set -euo pipefail

SOURCE_REPO="${SOURCE_REPO:-edde746/plezy}"
TARGET_REPO="${GITHUB_REPOSITORY:?GITHUB_REPOSITORY must be set}"
# Number of newest upstream releases to check each run. Default 1 (latest only).
MIRROR_LIMIT="${MIRROR_LIMIT:-1}"

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

echo "Mirroring up to ${MIRROR_LIMIT} newest release(s): ${SOURCE_REPO} -> ${TARGET_REPO}"

mapfile -t tags < <(gh release list --repo "$SOURCE_REPO" \
  --limit "$MIRROR_LIMIT" --exclude-drafts --exclude-pre-releases \
  --json tagName --jq '.[].tagName')

if [ "${#tags[@]}" -eq 0 ]; then
  echo "No upstream releases found."
  exit 0
fi

for tag in "${tags[@]}"; do
  echo "::group::${tag}"

  if gh release view "$tag" --repo "$TARGET_REPO" >/dev/null 2>&1; then
    echo "Already mirrored, skipping."
    echo "::endgroup::"
    continue
  fi

  mapfile -t assets < <(gh release view "$tag" --repo "$SOURCE_REPO" \
    --json assets --jq '.assets[].name | select(test("android.*\\.tar\\.gz$"))')

  if [ "${#assets[@]}" -eq 0 ]; then
    echo "No Android archives for ${tag}, skipping."
    echo "::endgroup::"
    continue
  fi

  reldir="$workdir/$tag"
  mkdir -p "$reldir"
  apks=()

  for asset in "${assets[@]}"; do
    arch="${asset#plezy-android-}"
    arch="${arch%.tar.gz}"
    extract="$reldir/extract-$arch"
    mkdir -p "$extract"

    echo "Downloading ${asset} ..."
    gh release download "$tag" --repo "$SOURCE_REPO" --pattern "$asset" --dir "$reldir"
    tar xzf "$reldir/$asset" -C "$extract"

    apk_src="$(find "$extract" -type f -name '*.apk' | head -n1)"
    if [ -z "$apk_src" ]; then
      echo "::warning::No .apk found inside ${asset}"
      continue
    fi

    apk_dst="$reldir/plezy-${tag}-${arch}.apk"
    mv "$apk_src" "$apk_dst"
    apks+=("$apk_dst")
    rm -rf "$reldir/$asset" "$extract"
  done

  if [ "${#apks[@]}" -eq 0 ]; then
    echo "::warning::No APKs extracted for ${tag}, skipping release."
    echo "::endgroup::"
    continue
  fi

  notes="$(cat <<EOF
Unofficial mirror of [\`${SOURCE_REPO}\` ${tag}](https://github.com/${SOURCE_REPO}/releases/tag/${tag}).

The Android **.apk** files in this release were extracted, unmodified, from the
upstream \`.tar.gz\` archives and republished here so the app can be installed
and auto-updated through [Obtainium](https://github.com/ImranR98/Obtainium)
without the Google Play Store.

**License:** plezy is licensed under the GNU General Public License v3.0.
The corresponding source code for this exact version is available upstream at
https://github.com/${SOURCE_REPO}/releases/tag/${tag} (and the repository
https://github.com/${SOURCE_REPO}). All rights and credit belong to the
upstream author. This repository redistributes the binaries only and is not
affiliated with or endorsed by the upstream project.
EOF
)"

  echo "Creating release ${tag} with ${#apks[@]} APK(s) ..."
  gh release create "$tag" "${apks[@]}" \
    --repo "$TARGET_REPO" \
    --title "$tag" \
    --notes "$notes"

  rm -rf "$reldir"
  echo "::endgroup::"
done

echo "Done."
