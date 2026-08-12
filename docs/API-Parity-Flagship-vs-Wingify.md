# Flagship (ABT) ↔ Wingify FME — Public API Comparison & Parity Map

**Platforms:** iOS (Swift)  
**Flagship:** `FlagShip` SDK (incl. optional `FlagshipWingify`)  
**Wingify:** `Wingify-FME` / `Wingify_FME`  
**Goal:** Review public APIs, identify what can be brought into / mapped through Flagship for Wingify feature parity, and document limitations.

---

## 1. Executive summary

| Category | Flagship (ABT) | Wingify FME | Parity status |
| --- | --- | --- | --- |
| SDK init | `Flagship.start` | `WingifyFme.initialize` | **Mapped** (via `FlagshipWingify`) |
| User / visitor | `FSVisitor` + builder | `WingifyUserContext` (per call) | **Partial** |
| Flag read | `getFlag` → `value` | `getFlag` → `getVariable` / `getVariables` | **Mapped** |
| Exposure | `visitorExposed()` | Implicit inside `getFlag` | **Limitation** (no separate API) |
| Analytics events | `sendHit(FSEvent/…)` | `trackEvent` | **Mapped** (`FSEvent`) |
| Attributes / context | `updateContext` | `setAttribute` + context `customVariables` | **Partial** |
| Identity | `authenticate` / `unauthenticate` | `setAlias` | **Partial** |
| Consent | `setConsent` | — | **Not available** in Wingify |
| Flag metadata | `metadata()` | — | **Not available** in Wingify |
| Fetch lifecycle | `fetchFlags` + status enums | Settings fetch at init / poll | **Different model** |
| Config | `FSConfigBuilder` | `WingifyInitOptions` | **Partial** (different concepts) |

### Already mapped today (FlagshipWingify)

| Flagship API | Wingify API | Notes |
| --- | --- | --- |
| `getFlag(key:).value(...)` | `getFlag` + `getVariable` / `getVariables` | Prefetch on `fetchFlags`; Wingify-first resolution |
| `start(..., wingifyInitOptions:)` | `WingifyFme.initialize` | Optional dual-engine start |
| `withWingifyUserContext` + `withContext` | `WingifyUserContext` | Mapped in `WingifyContextMapper` |
| `sendHit(FSEvent)` | `trackEvent` | Wingify-first: if event key is in Wingify settings → Wingify only; else ABTasty hit |

---

## 2. Side-by-side public API inventory

### 2.1 SDK lifecycle

| Flagship (ABT) | Wingify FME | Mappable? | Limitations / notes |
| --- | --- | --- | --- |
| `Flagship.sharedInstance` | Static `WingifyFme` (+ multi-instance via `getInstance`) | Yes | Wingify is static/multi-instance; Flagship is singleton + shared visitor |
| `start(envId:apiKey:config:)` | `initialize(options:completion:)` | Yes | Wingify init is **async** (`Result` completion). Flagship `start` is sync for ABTasty path |
| `start(..., wingifyInitOptions:)` | `initialize` | **Mapped** | Requires `FlagshipWingify` product |
| `getStatus() → FSSdkStatus` | No direct equivalent | Partial | Wingify readiness is “initialized / settings ready”; no panic/SDK status enum like Flagship |
| `close()` (flush hits) | `performEventSync()` | Partial | Wingify: optional manual flush of batched events; not a full SDK shutdown |
| `setSharedVisitor` | — | No | Wingify has no visitor object; context is passed per API call |
| — | `getInstance` / `clearInstance` / `clearAllInstances` | N/A | Multi-instance is Wingify-specific |
| — | `updateSettings` | N/A | Advanced; `Settings` not easily app-constructed |

---

### 2.2 Visitor / user identity & context

| Flagship (ABT) | Wingify FME | Mappable? | Limitations / notes |
| --- | --- | --- | --- |
| `newVisitor(visitorId:hasConsented:instanceType:)` | Create `WingifyUserContext(id:…)` | Partial | Wingify has **no visitor object** and **no consent** flag |
| `withContext` / `updateContext` / `getContext` / `clearContext` | `customVariables` on context; `setAttribute` for server props | Partial | Flagship context is long-lived on visitor. Wingify vars are on each call; `setAttribute` is fire-and-forget sync to backend |
| `withWingifyUserContext(...)` | `shouldUseDeviceIdAsUserId`, `bucketingSeed`, `postSegmentationVariables` | **Mapped** | — |
| Context `userAgent` / `ipAddress` | `userAgent`, `ipAddress` | **Mapped** | Wingify `userAgent` often set after init |
| `isAuthenticated` / `authenticate` / `unauthenticate` | `setAlias(from:to:)` | Partial | Alias needs `isAliasingEnabled`. Not the same as Flagship experience-continuity (anonymousId + visitorId pair) |
| `visitorId` / `anonymousId` | `id` (+ device id fallback) | Partial | No anonymous/authenticated pair in Wingify |
| `hasConsented` / `setConsent` | — | **No** | Wingify has no consent gate; Flagship blocks hits/cache when consent false |
| Preset `FlagshipContext` keys | — | **No** | Device presets are Flagship-specific (can be manually copied into `customVariables`) |

---

### 2.3 Flag evaluation

| Flagship (ABT) | Wingify FME | Mappable? | Limitations / notes |
| --- | --- | --- | --- |
| `fetchFlags(onFetchCompleted:)` | Settings loaded at `initialize` (+ optional poll) | Partial | Flagship: explicit per-visitor fetch. Wingify: settings global; evaluation happens on each `getFlag` |
| `getFlag(key:) → FSFlag` | `getFlag(featureKey:context:completion:) → GetFlag` | **Mapped** | Wingify is **async-only**. Flagship handle is sync after fetch |
| `FSFlag.value(defaultValue:)` | `GetFlag.getVariable` / first variable / `getVariables` | **Mapped** | Multi-var Flagship rules (warn + default) documented separately |
| `FSFlag.value(Value:defaultValue:)` | `GetFlag.getVariable(key:defaultValue:)` | **Mapped** | Wingify returns untyped `Any` |
| `FSFlag.exists()` | Infer from `isEnabled()` / variables | Partial | No dedicated exists API; disabled features may still return a `GetFlag` |
| `FSFlag.status` (`FSFlagStatus`) | — | **No** | No FETCHED / FETCH_REQUIRED / NOT_FOUND / PANIC per flag |
| `getFlags() → FSFlagCollection` | `getFeatureKeys()` + N× `getFlag` | Partial | Wingify lists keys only; no bulk sync flag collection with metadata |
| `FSFlagCollection.exposeAll` / `toJson` / `metadatas` | — | **No** | — |
| Panic mode (`FSSdkStatus.SDK_PANIC` / flag PANIC) | — | **No** | No Flagship-style panic kill-switch surface |

---

### 2.4 Exposure / activation

| Flagship (ABT) | Wingify FME | Mappable? | Limitations / notes |
| --- | --- | --- | --- |
| `value(..., visitorExposed: Bool = true)` | Impression sent inside `getFlag` | Partial | **Cannot defer exposure** in Wingify. Evaluating the flag ≈ exposing |
| `FSFlag.visitorExposed()` | — | **No** | **Major limitation:** no separate activate / visitor-exposed API |
| `onVisitorExposed` config callback | `IntegrationCallback.execute` | Partial | Integrations get generic property bags, not typed `FSVisitorExposed` / `FSExposedFlag` |
| Safer exposure checks (type mismatch warnings) | — | **No** | Flagship-specific logging / troubleshooting |

**Implication for parity:** Flagship apps that call `value(visitorExposed: false)` then later `visitorExposed()` cannot be mirrored 1:1 on Wingify. Bridging must document that Wingify exposure is tied to `getFlag` evaluation (already done during Flagship `fetchFlags` prefetch).

---

### 2.5 Tracking / analytics hits

| Flagship (ABT) | Wingify FME | Mappable? | Limitations / notes |
| --- | --- | --- | --- |
| `sendHit(FSEvent)` | `trackEvent(eventName:context:eventProperties:)` | **Mapped** | Wingify-first like getFlag: event key from settings → Wingify only; otherwise ABTasty hit. No callback |
| `sendHit(FSPage)` | — / custom `trackEvent` | Weak | No first-class page hit type |
| `sendHit(FSScreen)` | — / custom `trackEvent` | Weak | No first-class screen hit type |
| `sendHit(FSTransaction)` | — / custom `trackEvent` + properties | Weak | No e-commerce schema; map revenue/etc. into `eventProperties` manually |
| `sendHit(FSItem)` | — / custom `trackEvent` | Weak | Same as transaction |
| Hit batching (`FSTrackingManagerConfig`) | `batchMinSize` / `batchUploadTimeInterval` / `performEventSync` | Partial | Gateway URL disables online batching in Wingify |
| Consent-gated hits | — | **Partial** | No Wingify consent API; Flagship no-consent/panic/not-ready strategies skip the Wingify bridge |
| Activate hit (exposure) | Auto on `getFlag` | Different model | See §2.4 |

**Mapped behavior (`FSEvent`):**

| Flagship | Routing |
| --- | --- |
| `sendHit(FSEvent)` where `action` ∈ Wingify event keys (settings metrics) | Wingify `trackEvent` only (ABTasty hit skipped) |
| `sendHit(FSEvent)` where `action` ∉ Wingify event keys | ABTasty hit pipeline only |
| Optional `label` / `eventValue` | Mapped to Wingify `eventProperties["label"]` / `["value"]` when routed to Wingify |

---

### 2.6 Attributes & visitor properties

| Flagship (ABT) | Wingify FME | Mappable? | Limitations / notes |
| --- | --- | --- | --- |
| `updateContext` (local + affects next fetch) | Update `customVariables` for next `getFlag` **and/or** `setAttribute` | Partial | Flagship: one API for targeting context. Wingify splits **pre-segmentation vars** (context) vs **visitor attributes** (`setAttribute`) |
| — | `setAttribute(attributes:context:)` | Wingify-only | Fire-and-forget; dict only (no single-key API) |
| `clearContext` | Recreate empty context | Manual | — |

---

### 2.7 Flag metadata & reporting

| Flagship (ABT) | Wingify FME | Mappable? | Limitations / notes |
| --- | --- | --- | --- |
| `FSFlag.metadata()` → campaignId, variationId, names, slug, isReference, campaignType | — | **No** | **Major limitation:** `GetFlag` exposes only enablement + variables (`key`/`value`/`type`/`id`) |
| `FSExposedFlag` / `FSFlagMetadata.toJson()` | Integrations payload (untyped) | Weak | No stable public metadata model |
| Troubleshooting / usage hits | `isUsageStatsDisabled` / `vwoMeta` | Partial | Different purpose |

---

### 2.8 Configuration

| Flagship (ABT) | Wingify FME | Mappable? | Limitations / notes |
| --- | --- | --- | --- |
| `FSConfigBuilder.DecisionApi()` / `Bucketing()` | Always settings-driven FME | Different | No Decision API vs Bucketing modes |
| `withTimeout` | Network timeouts internal | No direct | — |
| `withLogLevel(FSLevel)` | `logLevel: LogLevelEnum` | Yes | Different enums (`ALL/INFO/…` vs `trace/debug/info/warn/error`) |
| `withBucketingPollingIntervals` | `pollInterval` | Yes | Wingify polls settings, not Flagship bucket file |
| `withCacheManager` (visitor/hit delegates) | `storage: WingifyStorageConnector` | Partial | Wingify storage is key/value decision cache, not Flagship visitor/hit SQLite model |
| `withTrackingManagerConfig` | `batchMinSize` / `batchUploadTimeInterval` | Partial | — |
| `withOnSdkStatusChanged` | Init completion only | Partial | No ongoing status stream |
| `withOnVisitorExposed` | `integrations: IntegrationCallback` | Partial | Untyped callback |
| `withDisableDeveloperUsageTracking` | `isUsageStatsDisabled` | Yes | — |
| envId + apiKey | `accountId` + `sdkKey` | Yes | Different credential pair |
| — | `gatewayService`, `cachedSettingsExpiryTime`, `cachedDecisionExpiryTime`, `isAliasingEnabled`, `logTransport`, `sdkName`/`sdkVersion` | Wingify-only | Useful for advanced FME setups |

---

### 2.9 Logging

| Flagship (ABT) | Wingify FME | Mappable? | Limitations / notes |
| --- | --- | --- | --- |
| `FSLevel` via config | `LogLevelEnum` + optional `LogTransport` | Yes | Levels don’t map 1:1; Wingify allows custom transport |

---

## 3. Mapping matrix (actionable)

Legend:

- **Mapped** — already wired in FlagshipWingify  
- **Mappable** — clear bridge candidate  
- **Partial** — can approximate with gaps  
- **Not available** — no Wingify counterpart  

| # | Flagship public API | Wingify counterpart | Status | Key Wingify limitation |
| --- | --- | --- | --- | --- |
| 1 | `Flagship.start` | `WingifyFme.initialize` | Mapped | Async init only |
| 2 | `start(..., wingifyInitOptions:)` | `initialize` | Mapped | Optional module required |
| 3 | `newVisitor` / `FSVisitor` | `WingifyUserContext` | Partial | No long-lived visitor; no consent |
| 4 | `withContext` / `updateContext` | `customVariables` (+ `setAttribute`) | Partial | Dual concept (targeting vs attributes) |
| 5 | `withWingifyUserContext` | Context options | Mapped | — |
| 6 | `fetchFlags` | Init settings + per-`getFlag` eval | Partial | No per-visitor fetch semantics |
| 7 | `getFlag` + `value` | `getFlag` + `getVariable(s)` | Mapped | Async eval; untyped values |
| 8 | `value(visitorExposed:)` | Implicit on `getFlag` | Partial | **Cannot control exposure timing** |
| 9 | `visitorExposed()` | — | **Not available** | No activate API |
| 10 | `exists` / `status` | `isEnabled` (weak) | Partial | No status enum |
| 11 | `metadata()` | — | **Not available** | No campaign/variation metadata on `GetFlag` |
| 12 | `getFlags` collection | `getFeatureKeys` + loop | Partial | No metadata/JSON/exposeAll |
| 13 | `sendHit(FSEvent)` | `trackEvent` | **Mapped** | Wingify-first via `wingifyEventKeys`; ABTasty hit skipped when matched |
| 14 | `sendHit(FSPage/Screen/Transaction/Item)` | Custom `trackEvent` | Partial | No first-class hit types |
| 15 | `setConsent` | — | **Not available** | Privacy gating is Flagship-only |
| 16 | `authenticate` / `unauthenticate` | `setAlias` | Partial | Requires aliasing enabled; different model |
| 17 | `close` | `performEventSync` | Partial | Flush ≠ shutdown |
| 18 | Cache delegates | `WingifyStorageConnector` | Partial | Different storage contract |
| 19 | `onVisitorExposed` | `IntegrationCallback` | Partial | Untyped |
| 20 | Panic / fetch status APIs | — | **Not available** | — |

---

## 4. Detailed limitation catalog (Wingify)

### 4.1 Flag APIs

| Topic | Detail |
| --- | --- |
| Exposure control | No `visitorExposed`. Impression/user-tracking happens during `getFlag`. |
| Sync API | `getFlag` is completion-based only. |
| Typing | `getVariable` returns `Any`, not generics like Flagship `value<T>`. |
| Metadata | No campaignId / variationId / variationName / slug / isReference on `GetFlag`. |
| Flag status | No FETCHED / NOT_FOUND / PANIC per key. |
| Multi-variable DX | App must pick variable key; Flagship bridge adds warning when non-overloaded API used with >1 vars. |

### 4.2 Tracking APIs

| Topic | Detail |
| --- | --- |
| Schema | Only generic `trackEvent(name, properties)`. |
| Validation | Unknown events (not on feature/holdout) are not sent. |
| Reliability signal | No success/failure completion to the app. |
| Hit types | No Page / Screen / Transaction / Item first-class models. |

### 4.3 Visitor model

| Topic | Detail |
| --- | --- |
| Object model | Context is re-supplied on every call (no `FSVisitor`-like state machine). |
| Consent | Not supported. |
| Auth continuity | `setAlias` ≠ Flagship authenticate/unauthenticate + anonymousId. |
| Experience continuity history | No assigned-variation history API like Flagship cache visitor. |

### 4.4 Platform / ops

| Topic | Detail |
| --- | --- |
| Multi-instance | Supported (`getInstance`); Flagship bridge currently uses default/single engine path. |
| Gateway vs batching | Configuring gateway disables online event batching. |
| Panic | No Flagship panic mode. |

---

## 5. Recommended next mappings (priority)

| Priority | Flagship API | Wingify API | Bridge approach | Watch-outs |
| --- | --- | --- | --- | --- |
| Done | `sendHit(FSEvent)` | `trackEvent` | Prefetch event keys from settings; if `action` ∈ keys → Wingify only; else ABTasty hit | Same strategy as getFlag |
| P1 | `updateContext` | Refresh customVariables for next prefetch + optional `setAttribute` | Decide whether context updates should call `setAttribute`, re-prefetch, or both | Dual semantics |
| P1 | Document exposure model | n/a | Explicit docs: Wingify exposure at prefetch/`getFlag` time | Apps using deferred expose need redesign |
| P2 | `authenticate` | `setAlias` | Map when aliasing enabled | Feature-flagged in Wingify init |
| P2 | `sendHit(FSTransaction/Item/Page/Screen)` | `trackEvent` conventions | Define property schema convention | Not native Wingify types |
| P3 | `metadata()` | Integrations / internal campaign data if exposed later | Blocked until Wingify public metadata exists | **Hard limitation today** |
| P3 | `setConsent` | — | Keep ABTasty-only; skip Wingify calls when no consent | Product decision (consent strategies already skip Wingify bridge) |

---

## 6. Bridge: sendHit(FSEvent) → Wingify trackEvent (Wingify-first)

Same strategy as `getFlag`: event keys are loaded from Wingify settings during `fetchFlags` prefetch (`WingifyFme.getEventKeys()` → feature + holdout metric identifiers).

```swift
visitor.sendHit(FSEvent(eventCategory: .Action_Tracking, eventAction: "button_clicked"))

// If "button_clicked" is in wingifyEventKeys:
//   → WingifyFme.trackEvent(...) only  (ABTasty hit NOT called)
// Else:
//   → ABTasty trackingManager.sendHit(...) only
```

**Behavior:**

- Prefetch stores `visitor.wingifyEventKeys` from Wingify settings metrics.
- `FSDefaultStrategy.sendHit` checks `event.action` against those keys.
- Wingify match → `trackEvent` only (no ABTasty hit).
- No match → normal ABTasty hit pipeline.
- Consent / panic / not-ready strategies override `sendHit` and skip both.
- `label` / `eventValue` map to Wingify `eventProperties` when routed to Wingify.

**Limitations:**

- Event must exist as a metric identifier in Wingify settings (feature or holdout).
- No ACK / completion callback from Wingify.
- Event keys are refreshed on `fetchFlags` (same as feature keys).

---

## 7. Test checklist for parity work

- [ ] `getFlag`/`value` parity (single + multi variable) — already in place  
- [ ] `sendHit(FSEvent)` with Wingify event key → Wingify only (no ABTasty hit)  
- [ ] `sendHit(FSEvent)` with unknown/ABTasty event → ABTasty hit only  
- [ ] Deferred exposure Flagship pattern **cannot** be reproduced — document  
- [ ] `metadata()` on Wingify-backed flag returns empty/default — document  
- [ ] Consent=false: ABTasty hits blocked **and** Wingify bridge skipped (via `FSNoConsentStrategy`)  
- [ ] `setAlias` path when `isAliasingEnabled`  
- [ ] Context update then re-`fetchFlags` refreshes Wingify feature + event keys  

---

## 8. FAQ

**Q: Can we fully match Flagship `visitorExposed()` on Wingify?**  
A: No. Wingify sends impressions as part of `getFlag`. The bridge should document this and avoid promising deferred exposure for Wingify flags.

**Q: Is `sendHit` → `trackEvent` a clean map?**  
A: For `FSEvent`, yes — same Wingify-first routing as `getFlag`. If the event action is in Wingify settings event keys, only Wingify `trackEvent` runs. Otherwise only the ABTasty hit pipeline runs. Page/Screen/Transaction/Item are not bridged yet.

**Q: Why isn’t metadata mappable?**  
A: Public `GetFlag` does not expose campaign/variation identifiers comparable to `FSFlagMetadata`.

**Q: What about consent?**  
A: Wingify has no consent API. The bridge is only invoked from `FSDefaultStrategy.sendHit`, so Flagship no-consent / panic / not-ready strategies already skip Wingify `trackEvent`.

---

## 9. Related docs

- [Wingify sendHit → trackEvent](./Wingify-SendHit-TrackEvent.md)  
- [Optional Wingify dependency spec](./Optional-Wingify-Dependency-Spec.md)  
- [Wingify flag values](./Wingify-Flag-Values.md)  
- [Optional Wingify SDK (short)](./Optional-Wingify-SDK.md)  
