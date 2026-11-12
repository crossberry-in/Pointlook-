# Pointlook Android ARM64 build

Pointlook is built from the Chromium source tree. The Android package ID is
`com.crossberry.pointlook`, and the launcher label is configured as
`Pointlook`.

## Build machine

Use a Linux x86-64 machine with:

- At least 16 GB RAM (more is recommended).
- At least 100 GB free disk space.
- Git, Python 3, and the standard Chromium Linux build dependencies.
- A current `depot_tools` checkout.

Chromium Android builds are not suitable for standard GitHub-hosted runners
because of their disk and memory requirements.

## Local build

From the repository root:

```bash
git clone https://chromium.googlesource.com/chromium/tools/depot_tools.git
export PATH="$PATH:$PWD/depot_tools"

sudo ./build/install-build-deps.sh --android --no-prompt

mkdir -p out
cat > ../.gclient <<'EOF'
solutions = [
  {
    "name": "src",
    "url": "https://github.com/crossberry-in/Pointlook-.git",
    "managed": False,
    "custom_deps": {},
    "custom_vars": {},
  },
]
target_os = ["android"]
EOF

gclient sync --no-history
gclient runhooks
bash ./scripts/build_android_arm64.sh
```

The script generates a release-mode ARM64 build and invokes the Chromium
`chrome_public_apk` target. Expected output:

`out/Pointlook/artifacts/Pointlook-Android-ARM64.apk`

## GitHub Actions

1. Register a self-hosted Linux x86-64 runner for this repository.
2. Add the labels `linux`, `x64`, and `chromium-android` in addition to
   `self-hosted`.
3. Install `depot_tools` on the runner and define the runner environment
   variable `DEPOT_TOOLS_PATH` to its absolute directory.
4. Ensure the runner account can use `sudo` for the Chromium dependency
   installation step and has the required disk and RAM.
5. Open **Actions → Pointlook Android ARM64 Build → Run workflow**.

The workflow uploads the APK as the
`Pointlook-Android-ARM64` artifact when the build succeeds.

## Important

A successful workflow run is required before describing an APK as built.
The workflow does not create a Play Store signing key or publish a GitHub
Release. Release signing must use a private key managed outside the repository.
