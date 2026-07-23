# Wingify flag values

When Flagship is started with `wingifyInitOptions`, `fetchFlags` evaluates Wingify features and `getFlag` resolves **Wingify first**, then ABTasty.

## Getting a flag value

```swift
let flag = visitor.getFlag(key: "checkoutFlow")
```

### Single-variable Wingify feature

Use the non-overloaded API. The SDK returns that variable automatically:

```swift
let value = flag.value(defaultValue: "defaultValue")
```

### Multi-variable Wingify feature

If the feature has **more than one variable** and you call `value(defaultValue:)` without a variable key:

1. The SDK returns your `defaultValue`.
2. A **WARNING** log is printed, for example:

   > Wingify feature 'checkoutFlow' contains multiple variables. Please specify a variable key using .value(Value: "variableKey", defaultValue:).

Pass the variable key with the overloaded API:

```swift
let cta = flag.value(Value: "cta", defaultValue: "Buy now")
let discount = flag.value(Value: "discount", defaultValue: 0)
```

### Summary

| Wingify variables | API | Result |
| --- | --- | --- |
| 1 | `value(defaultValue:)` | Returns that variable |
| > 1 | `value(defaultValue:)` | Returns `defaultValue` + warning log |
| Any | `value(Value:defaultValue:)` | Returns the named variable (or `defaultValue` if missing / type mismatch) |

ABTasty flags are unchanged: `value(defaultValue:)` returns the modification value; the `Value:` parameter is ignored.

## Visitor → WingifyUserContext mapping

When creating a visitor, pass Wingify options and context:

```swift
let visitor = Flagship.sharedInstance
    .newVisitor(visitorId: "userId", hasConsented: true)
    .withContext(context: [
        "userAgent": userAgent,
        "ipAddress": ipAddress
        // …other custom variables
    ])
    .withWingifyUserContext(
        shouldUseDeviceIdAsUserId: true,
        bucketingSeed: bucketingSeed,
        postSegmentationVariables: postSegmentationVariables
    )
    .build()
```

| Flagship | WingifyUserContext |
| --- | --- |
| `visitorId` | `id` |
| `withContext` / `getContext()` | `customVariables` |
| context key `userAgent` | `userAgent` |
| context key `ipAddress` | `ipAddress` |
| `withWingifyUserContext.shouldUseDeviceIdAsUserId` | `shouldUseDeviceIdAsUserId` |
| `withWingifyUserContext.bucketingSeed` | `bucketingSeed` |
| `withWingifyUserContext.postSegmentationVariables` | `postSegmentationVariables` |

This mapping is applied in `WingifyContextMapper` before Wingify `getFlag` during `fetchFlags`.

## Related APIs

- `Flagship.start(..., wingifyInitOptions:)` — optional dual-engine init
- `FSVisitorBuilder.withWingifyUserContext(...)` — Wingify user-context options on the visitor
- `visitor.fetchFlags` — prefetches Wingify features when configured
- `visitor.getFlag(key:)` — Wingify key preferred when present in Wingify settings
