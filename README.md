# IGenerate

A minimal, monochrome iOS app with two screens:

- **Generate** — enter a prompt (optionally attach a reference photo to edit
  instead of generating from scratch), tap Generate/Edit.
- **Generations** — a grid of everything you've made, tap any tile for the
  full image, share, or delete.

Everything runs **on-device, fully offline**, via
[`xocialize/flux2-klein-swift`](https://github.com/xocialize/flux2-klein-swift)
(Swift/MLX port of FLUX.2-klein-4B).

## Building via GitHub Actions (no Mac needed)

This repo includes `project.yml` (an XcodeGen spec) and
`.github/workflows/build.yml`. The workflow runs on a macOS GitHub-hosted
runner, generates the `.xcodeproj` from `project.yml`, resolves the
`flux2-klein-swift` package, signs, archives, and uploads a downloadable
`.ipa` artifact — you never need to open Xcode yourself.

**Prerequisite: a paid Apple Developer Program membership ($99/yr).**
Ad-hoc distribution (the kind of signing that lets you install an IPA on
your own device without a jailbreak, e.g. via AnyTrans) requires a
distribution certificate and a device-specific provisioning profile, which
free Apple IDs cannot generate.

### One-time setup

1. **Find your device's UDID.** AnyTrans shows this in the device summary
   panel, or use `Finder`/`iTunes` on any machine, or
   `https://get.udid.io`.
2. **In [Apple Developer](https://developer.apple.com/account)**:
   - Devices → register your iPhone's UDID.
   - Certificates → create an **Apple Distribution** certificate. Download
     it, then export it as a `.p12` from Keychain Access (needs a Mac once
     — a friend's, a cloud Mac rental, whatever) and set a password on
     export.
   - Identifiers → register `com.yourname.igenerate` (match
     `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` if you change it).
   - Profiles → create an **Ad Hoc** profile using that cert + app ID +
     your registered device. Download the `.mobileprovision` file. Note
     its exact **name**.
3. **Base64-encode the two files** (works fine on Windows, in PowerShell):
   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("cert.p12")) | Out-File cert_b64.txt
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("profile.mobileprovision")) | Out-File profile_b64.txt
   ```
4. **Add repo secrets** (Settings → Secrets and variables → Actions):
   - `BUILD_CERTIFICATE_BASE64` — contents of `cert_b64.txt`
   - `P12_PASSWORD` — the password you set exporting the `.p12`
   - `KEYCHAIN_PASSWORD` — any throwaway string
   - `BUILD_PROVISION_PROFILE_BASE64` — contents of `profile_b64.txt`
   - `DEVELOPMENT_TEAM` — your 10-character Team ID (top-right of the
     developer portal)
   - `PROVISIONING_PROFILE_NAME` — the exact name you gave the profile
5. Push this repo to GitHub, then run the workflow from the **Actions**
   tab (`Build IGenerate IPA` → Run workflow). When it finishes, download
   the `IGenerate-ipa` artifact — it's a zip containing your `.ipa`.
6. Open **AnyTrans** → Apps → install the `.ipa` → pick your device.
   You'll also need to trust the developer certificate once on-device:
   Settings → General → VPN & Device Management → trust it.

Re-run the workflow any time you push changes — no Mac required for any
of it, only for the one-time `.p12` export in step 2.

### Building locally in Xcode instead

If you do get occasional Mac access, you can skip all of the above:
open the folder in Xcode via `xcodegen generate && open IGenerate.xcodeproj`
(after installing `xcodegen` via `brew install xcodegen`), sign with your
Apple ID under Signing & Capabilities, and run directly to your device.

### On-device notes

- Set the deployment target to iOS 17+ (already set in `project.yml`) —
  needed for `PhotosPicker`'s `Transferable` API.
- Build/run needs a **physical Apple Silicon device** — the simulator
  can't run the on-device MLX model. 16GB RAM (int4 quant, ~11GB resident)
  is the practical minimum.
- On first launch, `GenerationStore.loadModelIfNeeded()` will
  auto-download and cache the bf16 weights
  (`mlx-community/FLUX.2-klein-4B-bf16`) the first time someone generates —
  make sure the device has network for that one-time fetch and a few GB
  free. After that, generation is fully offline.

## Notes

- The whole UI is intentionally forced to light mode / pure black-and-white
  (see `Theme.swift` and the `UITabBar`/`UINavigationBar` appearance calls
  in `IGenerateApp.swift`) so it doesn't pick up the system accent color or
  dark mode.
- `Klein4BT2IPackage` is configured with `.int4` quantization for speed and
  a smaller memory footprint. Swap in `.bf16` in `GenerationStore.swift` if
  you want the base/quality tier instead (see the repo's README for the
  quality-vs-speed tradeoffs between the distilled and base checkpoints).
- Generated PNGs and their metadata are stored in the app's
  `Documents/Generations` folder, indexed in `index.json` — no backend, no
  account, nothing leaves the device.
- `PhotosPicker` doesn't require an `NSPhotoLibraryUsageDescription` entry
  since it uses the system picker sandbox — no extra Info.plist entry
  needed for the reference-image picker.
