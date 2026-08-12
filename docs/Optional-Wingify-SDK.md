# Optional Wingify SDK

Wingify FME is an **optional** add-on. ABTasty-only clients do not link Wingify, which keeps the app smaller.

## Swift Package Manager

| Product | Role |
| --- | --- |
| `Flagship` | ABTasty core (required) |
| `FlagshipWingify` | Optional Wingify engine — link **in addition to** `Flagship` |

### ABTasty only

```swift
import Flagship

Flagship.sharedInstance.start(envId: "...", apiKey: "...")
```

### ABTasty + Wingify

Link both **Flagship** and **FlagshipWingify**:

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

`start(..., wingifyInitOptions:)` is provided by `FlagshipWingify` and installs the Wingify engine automatically.

## CocoaPods

```ruby
# ABTasty only (default)
pod 'FlagShip'

# Dual-engine
pod 'FlagShip/Wingify'   # pulls FlagShip/Core + Wingify-FME
```

## Behavior without Wingify

- `WingifyBridge` is not compiled / not linked
- Wingify-FME is not in the app binary
- `fetchFlags` skips Wingify prefetch
- `withWingifyUserContext(...)` can still be called, but has no effect until `FlagshipWingify` is linked and Wingify is started

## Approx. binary size (arm64)

| Mode | Approx. size |
| --- | --- |
| ABTasty only (`Flagship` / `FlagShip`) | ~4.8 MB |
| Dual-engine (+ Wingify-FME) | ~7.8 MB |
| Extra for Wingify | ~+2.9 MB |

See [Optional Wingify dependency (full spec)](./Optional-Wingify-Dependency-Spec.md#5-framework--binary-size) for measurement details.
