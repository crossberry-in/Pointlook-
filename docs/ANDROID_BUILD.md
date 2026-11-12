# Pointlook Android ARM64 build

Pointlook is built from the complete Chromium source at **132.0.6834.83**.
The Android package ID is `com.crossberry.pointlook`, and the launcher label
is `Pointlook`.

The Pointlook Git repository contains the branding changes and project
configuration; it is not a complete Chromium checkout by itself. The build
process therefore checks out the matching upstream Chromium source, applies
the two Pointlook branding changes, syncs Chromium dependencies, and builds
the Android APK.

## Build machine

Use a Linux x86-64 machine with:

- At least 16 GB RAM (more is recommended).
- At least 100 GB free disk space.
- Git, Python 3, and the standard Chromium Linux build dependencies.
- A current `depot_tools` checkout.

Chromium Android builds are not suitable for standard GitHub-hosted runners
because of their disk and memory requirements.

## Local build

Create a working directory and install `depot_tools`:

```bash
mkdir -p ~/pointlook-build
cd ~/pointlook-build
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PATH:$PWD/depot_tools"
```

Check out the exact Chromium source version and configure its dependencies:

```bash
git clone --depth 1 --branch 132.0.6834.83 https://chromium.googlesource.com/chromium/src.git src
cat > .gclient <<'EOF'
solutions = [
  {
    "name": "src",
    "url": "https://chromium.googlesource.com/chromium/src.git",
    "managed": False,
    "custom_deps": {},
    "custom_vars": {},
  },
]
target_os = ["android"]
EOF

git clone --depth 1 --branch pointlook-branding https://github.com/crossberry-in/Pointlook-.git branding
sudo src/build/install-build-deps.sh --android --no-prompt
cd src
gclient sync --no-history
gclient runhooks
```

Apply Pointlook's branding values (the same exact replacements used by CI):

```bash
python3 - <<'PY'
from pathlib import Path

changes = {
    Path("chrome/android/chrome_public_apk_tmpl.gni"): (
        'chrome_public_manifest_package = "org.chromium.chrome"',
        'chrome_public_manifest_package = "com.crossberry.pointlook"',
    ),
    Path("chrome/android/java/res_chromium_base/values/channel_constants.xml"): (
        '<string name="app_name" translatable="false">Chromium</string>',
        '<string name="app_name" translatable="false">Pointlook</string>',
    ),
}
for path, (old, new) in changes.items():
    text = path.read_text()
    if text.count(old) != 1:
        raise SystemExit(f"Expected exactly one source value in {path}")
    path.write_text(text.replace(old, new, 1))
PY
```

Copy the Pointlook build script into the Chromium source tree and run it:

```bash
mkdir -p scripts
cp ../branding/scripts/build_android_arm64.sh scripts/
bash scripts/build_android_arm64.sh
```

Expected output:

`out/Pointlook/artifacts/Pointlook-Android-ARM64.apk`

## GitHub Actions

1. Register a self-hosted Linux x86-64 runner for this repository.
2. Add the labels `linux`, `x64`, and `chromium-android` in addition to
   `self-hosted`.
3. Install `depot_tools` on the runner and define the runner environment
   variable `DEPOT_TOOLS_PATH` to its absolute directory.
4. Ensure the runner account can use `sudo` for Chromium dependency
   installation and has the required disk and RAM.
5. Open **Actions → Pointlook Android ARM64 Build → Run workflow**.

The workflow checks out the complete pinned Chromium source, applies
Pointlook branding, syncs dependencies, builds the APK, and uploads it as the
`Pointlook-Android-ARM64` artifact when successful.

## Important

A successful workflow run is required before describing an APK as built.
This workflow does not create a Play Store signing key or publish a GitHub
Release. Release signing must use a private key managed outside the repository.
