# Flagship iOS — Optional Wingify FME Dependency

**Platform:** iOS (Swift)  
**Module:** FlagShip SDK  
**Topic:** Making Wingify-FME an optional dependency (CocoaPods + SPM)  
**Status:** Implemented on `feat/ABTMigration`

---

## 1. Overview

Flagship iOS can run in two modes:

| Mode | Description | Wingify-FME linked? |
| --- | --- | --- |
| **ABTasty only** | Default Flagship behavior | No |
| **Dual-engine** | ABTasty + Wingify FME | Yes |

Clients who do **not** need Wingify must not be forced to download or link `Wingify-FME`. That keeps their app binary smaller and avoids an unused third-party SDK.

---

## 2. Goal

- Keep **ABTasty-only** install as the default.
- Allow clients who need Wingify to opt in explicitly.
- Ensure Wingify-FME is **not** part of the default CocoaPods / SPM link set.
- Preserve existing Flagship APIs for ABTasty-only users.

---

## 3. Architecture

```
┌─────────────────────────────────────┐
│           Client App                │
└───────────────┬─────────────────────┘
                │
     ┌──────────┴──────────┐
     │                     │
     ▼                     ▼
┌──────────┐      ┌─────────────────┐
│ Flagship │      │ FlagshipWingify │  (optional add-on)
│  (Core)  │◄─────│  WingifyBridge  │
└──────────┘      └────────┬────────┘
                           │
                           ▼
                  ┌─────────────────┐
                  │   Wingify-FME   │
                  └─────────────────┘
```

### Components

| Component | Role |
| --- | --- |
| **Flagship (Core)** | ABTasty SDK. No compile/link dependency on Wingify-FME. |
| **FlagshipWingify** | Optional plugin. Contains `WingifyBridge`, depends on Core + Wingify-FME. |
| **FSWingifyRuntime** | Core hook. When the Wingify add-on is installed, Core can prefetch Wingify flags. |
| **Wingify-FME** | Third-party FME SDK. Pulled only when the Wingify add-on is selected. |

### Runtime behavior

- If `FlagshipWingify` is **not** linked → `FSWingifyRuntime.integration == nil` → `fetchFlags` skips Wingify prefetch (ABTasty only).
- If `FlagshipWingify` **is** linked and `start(..., wingifyInitOptions:)` is used → Wingify engine is installed and used during `fetchFlags` / `getFlag`.

---

## 4. Packaging

### 4.1 CocoaPods

Wingify is a **subspec** of the same `FlagShip` pod.  
**No separate CocoaPods release** is required for `FlagShip/Wingify`.

One `FlagShip` version/tag publishes:

- `FlagShip` / `FlagShip/Core` (default)
- `FlagShip/Wingify` (optional)

#### Podspec structure

```ruby
s.default_subspec = "Core"

s.subspec "Core" do |core|
  core.source_files = "FlagShip/Source/**/*.swift"
  core.exclude_files = "FlagShip/Source/WingifyBridge/**/*"
end

s.subspec "Wingify" do |wingify|
  wingify.dependency "FlagShip/Core"
  wingify.dependency "Wingify-FME", "~> 1.55"
  wingify.source_files = "FlagShip/Source/WingifyBridge/**/*.swift"
end
```

#### Client Podfile

```ruby
# ABTasty only (default) — Wingify-FME is NOT installed
pod 'FlagShip'

# Dual-engine — installs FlagShip/Core + Wingify-FME
pod 'FlagShip/Wingify'
```

#### What `pod install` does

| Podfile line | Installs FlagShip Core | Installs WingifyBridge | Installs Wingify-FME |
| --- | --- | --- | --- |
| `pod 'FlagShip'` | Yes | No | No |
| `pod 'FlagShip/Wingify'` | Yes (via dependency) | Yes | Yes |

---

### 4.2 Swift Package Manager (SPM)

Two library products in `Package.swift`:

| Product | Target | Links Wingify-FME? |
| --- | --- | --- |
| `Flagship` | Core sources (excludes `WingifyBridge`) | No |
| `FlagshipWingify` | `WingifyBridge` only | Yes (depends on Core + Wingify-FME) |

#### Client setup — ABTasty only

1. Add Flagship package in Xcode.
2. Link product **`Flagship`** only.

```swift
import Flagship

Flagship.sharedInstance.start(envId: "...", apiKey: "...")
```

#### Client setup — Dual-engine

1. Add Flagship package.
2. Link **`Flagship`** and **`FlagshipWingify`**.

```swift
import Flagship
import FlagshipWingify
import Wingify_FME

Flagship.sharedInstance.start(
    envId: "...",
    apiKey: "...",
    wingifyInitOptions: WingifyInitOptions(sdkKey: "...", accountId: ...)
)
```

`start(..., wingifyInitOptions:)` lives on `FlagshipWingify` and calls `FlagshipWingify.install()` so Core can use the Wingify engine.

---

## 5. Framework / binary size

Measured sizes (approximate). Final App Store / IPA impact varies with thinning and linker settings.

### Summary

| Configuration | What’s linked | Approx. size (arm64) |
| --- | --- | --- |
| **ABTasty only** | Flagship Core | **~4.8 MB** |
| **Wingify-FME alone** | Wingify-FME SDK binary | **~2.9 MB** |
| **Dual-engine** | Core + FlagshipWingify bridge + Wingify-FME | **~7.8 MB** |
| **Extra cost of Wingify** | vs ABTasty-only | **~+2.9 MB (~+60%)** |

`FlagshipWingify` bridge sources are small (~10 KB of Swift) and negligible next to Wingify-FME.

### Breakdown

| Artifact | Size | Notes |
| --- | --- | --- |
| Flagship Core (`libFlagship.a`) | 4.8 MB | SPM **Release**, macOS `arm64`, static archive of Core `.o` files (no WingifyBridge) |
| Wingify-FME binary (thinned `arm64`) | 2.9 MB | **Release-iphonesimulator** framework binary, thinned from fat (`x86_64` + `arm64`) |
| Wingify-FME framework (fat, sim) | 5.9 MB binary / 7.8 MB total | Unthinned simulator Release framework (`x86_64` + `arm64`) |

### How this was measured

1. **Core:** `swift build -c release --target Flagship` → archive all `Flagship.build/*.o` into `libFlagship.a`.
2. **Wingify-FME:** Xcode **Release-iphonesimulator** `Wingify_FME.framework` → `lipo -thin arm64` for single-architecture size.
3. **Dual-engine estimate:** Core archive + thinned Wingify-FME binary (bridge omitted as negligible).

> **Note:** These are engineering measurements for comparison, not App Store download size. Re-measure on `iphoneos` Release (device) before publishing external size claims.

### Client takeaway

- Use `pod 'FlagShip'` / SPM product `Flagship` → **no Wingify-FME** in the binary → smaller app.
- Use `pod 'FlagShip/Wingify'` / SPM `Flagship` + `FlagshipWingify` → expect roughly **+~3 MB** (arm64) from Wingify-FME.

---

## 6. Dependency resolution summary

| Installer | ABTasty-only command | Dual-engine command | When is Wingify-FME fetched/linked? |
| --- | --- | --- | --- |
| CocoaPods | `pod 'FlagShip'` | `pod 'FlagShip/Wingify'` | Only for `/Wingify` subspec |
| SPM | Link `Flagship` | Link `Flagship` + `FlagshipWingify` | Only when `FlagshipWingify` is linked |

### Release note (CocoaPods)

- Do **not** publish a separate pod named `FlagShipWingify`.
- Ship one version of `FlagShip`; clients select the subspec.

---

## 7. Public APIs related to Wingify

### Available always (Core)

```swift
Flagship.sharedInstance.start(envId:apiKey:config:)

visitorBuilder.withWingifyUserContext(
    shouldUseDeviceIdAsUserId:bucketingSeed:postSegmentationVariables:
)
```

`withWingifyUserContext` stores options on the visitor. It has **no effect** until `FlagshipWingify` is linked and Wingify is started.

### Available only with FlagshipWingify linked

```swift
Flagship.sharedInstance.start(
    envId:apiKey:config:wingifyInitOptions:
)
```

### Flag resolution (when Wingify is configured)

1. `fetchFlags` prefetches Wingify features.
2. `getFlag(key:)` prefers Wingify when the key exists in Wingify settings.
3. Otherwise falls back to ABTasty.

### Visitor → WingifyUserContext mapping

| Flagship | WingifyUserContext |
| --- | --- |
| `visitorId` | `id` |
| `withContext` / `getContext()` | `customVariables` |
| context `userAgent` / `ipAddress` | `userAgent` / `ipAddress` |
| `withWingifyUserContext(...)` | `shouldUseDeviceIdAsUserId`, `bucketingSeed`, `postSegmentationVariables` |

Example:

```swift
let visitor = Flagship.sharedInstance
    .newVisitor(visitorId: "userId", hasConsented: true)
    .withContext(context: [
        "userAgent": userAgent,
        "ipAddress": ipAddress
    ])
    .withWingifyUserContext(
        shouldUseDeviceIdAsUserId: true,
        bucketingSeed: bucketingSeed,
        postSegmentationVariables: postSegmentationVariables
    )
    .build()
```

---

## 8. Multi-variable Wingify `value()` behavior

Applies only to Wingify-backed flags:

| Variables | API | Result |
| --- | --- | --- |
| 1 | `value(defaultValue:)` | Returns that variable |
| > 1 | `value(defaultValue:)` | Returns `defaultValue` + WARNING log |
| Any | `value(Value:defaultValue:)` | Returns named variable |

Warning example:

> Wingify feature 'checkoutFlow' contains multiple variables. Please specify a variable key using .value(Value: "variableKey", defaultValue:).

---

## 9. Test plan

### ABTasty-only install

- [ ] CocoaPods: `pod 'FlagShip'` → `Wingify-FME` absent from Pods
- [ ] SPM: link only `Flagship` → app does not link Wingify-FME
- [ ] `start(envId:apiKey:)` works
- [ ] `fetchFlags` / `getFlag` work for ABTasty campaigns
- [ ] App size smaller than dual-engine build

### Dual-engine install

- [ ] CocoaPods: `pod 'FlagShip/Wingify'` → Core + Wingify-FME installed
- [ ] SPM: link `Flagship` + `FlagshipWingify`
- [ ] `start(..., wingifyInitOptions:)` initializes Wingify
- [ ] `fetchFlags` prefetches Wingify features
- [ ] `getFlag` resolves Wingify-first, then ABTasty
- [ ] `withWingifyUserContext` maps into `WingifyUserContext`
- [ ] Multi-variable `value(defaultValue:)` returns default + warning

---

## 10. FAQ

**Q: Do we release `FlagShip/Wingify` separately on CocoaPods?**  
A: No. It is a subspec of `FlagShip`. One pod version covers both Core and Wingify.

**Q: If a client uses only `pod 'FlagShip'`, is Wingify-FME downloaded?**  
A: No. The Wingify-FME dependency exists only on the `Wingify` subspec.

**Q: For SPM, must clients import two modules for dual-engine?**  
A: Yes. Link/import `Flagship` and `FlagshipWingify` (and `Wingify_FME` when using Wingify types such as `WingifyInitOptions`).

**Q: What happens if Core is used but someone calls `withWingifyUserContext`?**  
A: Options are stored on the visitor, but Wingify prefetch/evaluation does not run until `FlagshipWingify` is linked and Wingify is started.

---

## 11. Related docs

- [Wingify flag values](./Wingify-Flag-Values.md)
- [Optional Wingify SDK (short)](./Optional-Wingify-SDK.md)
