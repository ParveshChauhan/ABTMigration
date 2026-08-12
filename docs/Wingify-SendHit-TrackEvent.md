# Wingify sendHit → trackEvent

## What this does (in simple words)

You already call events like this:

```swift
visitor.sendHit(FSEvent(eventCategory: .Action_Tracking, eventAction: "button_clicked"))
```

Nothing changes for the app.  
Behind the scenes, the SDK asks one question:

> **Is `"button_clicked"` a Wingify event?**

- **Yes** → send it to Wingify only (`trackEvent`)
- **No** → send it to ABTasty only (normal hit)

It never sends the same event to both.

This is the same idea as `getFlag`:

- Flag key known to Wingify → use Wingify
- Otherwise → use ABTasty

---

## Easy mental model

Think of two lists stored on the visitor after `fetchFlags`:

| List | Used for | Example |
| --- | --- | --- |
| Feature keys | `getFlag("checkout")` | `"checkout"`, `"banner"` |
| Event keys | `sendHit(... action: "purchase")` | `"purchase"`, `"button_clicked"` |

Both lists come from Wingify settings.

```text
fetchFlags()
    │
    ▼
Ask Wingify settings:
  - which flags exist?
  - which events exist?
    │
    ▼
Save two lists on visitor
    │
    ├── getFlag(key)     → look in flag list
    └── sendHit(FSEvent) → look in event list
```

---

## Step 1 — Prepare the lists (`fetchFlags`)

When you call `fetchFlags()`:

1. Flagship loads ABTasty campaigns as usual.
2. If Wingify is enabled, it also reads Wingify settings.
3. From those settings it builds:
   - list of flag keys
   - list of event names (metrics / goals)
4. It saves those lists on the visitor.

```text
App: visitor.fetchFlags()
              │
              ▼
     Load ABTasty data
              │
              ▼
     Wingify enabled?
         │
    No ──┴── Yes
    │         │
    │         ▼
    │   Read Wingify settings
    │         │
    │         ▼
    │   Save flag keys + event keys
    │         │
    └─────────┴──► fetchFlags finished
```

Until `fetchFlags` finishes, event routing may not know Wingify event names yet.

---

## Step 2 — Send an event (`sendHit`)

App code:

```swift
let event = FSEvent(eventCategory: .Action_Tracking, eventAction: "button_clicked")
event.label = "hero_cta"
visitor.sendHit(event)
```

What the SDK does:

```text
sendHit(FSEvent action = "button_clicked")
              │
              ▼
     Is this an FSEvent?
              │
         No ──┴── Yes
         │         │
         │         ▼
         │   Is "button_clicked" in Wingify event list?
         │              │
         │         Yes ─┴─ No
         │          │      │
         │          ▼      ▼
         │     Wingify   ABTasty
         │     trackEvent  hit
         │          │      │
         ▼          ▼      ▼
      ABTasty     DONE   DONE
      hit only
     (normal path)
```

### Example A — Wingify event

1. Settings say Wingify knows `"button_clicked"`.
2. You call `sendHit` with action `"button_clicked"`.
3. SDK calls Wingify `trackEvent("button_clicked", ...)`.
4. ABTasty hit is **not** sent.

### Example B — ABTasty event

1. `"my_abt_goal"` is **not** in the Wingify event list.
2. You call `sendHit` with action `"my_abt_goal"`.
3. SDK sends the normal ABTasty hit.
4. Wingify is **not** called.

---

## Simple flow chart

```text
                    +------------------+
                    |  App calls       |
                    |  sendHit(FSEvent)|
                    +--------+---------+
                             |
                             v
              +------------------------------+
              | Is event.action in           |
              | Wingify event list?          |
              +---------------+--------------+
                      |               |
                     YES              NO
                      |               |
                      v               v
           +----------------+   +----------------+
           | Wingify only   |   | ABTasty only   |
           | trackEvent()   |   | sendHit hit    |
           +----------------+   +----------------+
```

---

## What gets sent to Wingify

| From your `FSEvent` | Sent to Wingify as |
| --- | --- |
| `eventAction` / `action` | Event name |
| `label` (optional) | Property `"label"` |
| `eventValue` (optional) | Property `"value"` |
| Visitor id + context | Wingify user context |

Only **event** hits (`FSEvent`) use this routing.  
Page / Screen / Transaction / Item always go to ABTasty.

---

## Same rule as getFlag

| You call | SDK checks | If found in Wingify | If not found |
| --- | --- | --- | --- |
| `getFlag("checkout")` | Flag key list | Use Wingify flag | Use ABTasty flag |
| `sendHit(... "purchase")` | Event name list | Use Wingify `trackEvent` | Use ABTasty hit |

In both cases: **one engine only**, not both.

---

## Things to remember

1. **Call `fetchFlags` first** so the Wingify event list is loaded.
2. The event name must match a metric/goal name in Wingify settings.
3. If the name is unknown to Wingify, it falls back to ABTasty automatically.
4. If the visitor has no consent (or SDK is panic / not ready), events are blocked the same way as normal Flagship hits.
5. Wingify does not return success/failure to the app for `trackEvent`.

---

## Where this lives in code

| File | What it does |
| --- | --- |
| `WingifyFlagPrefetcher.swift` | Reads flag keys + event keys from Wingify settings |
| `FSVisitor.swift` | Saves those lists on the visitor |
| `FSDefaultStrategy.swift` | Decides Wingify vs ABTasty on `sendHit` |
| `WingifyEventTracker.swift` | Calls Wingify `trackEvent` |
| `WingifyFme.getEventKeys()` | Returns event names from Wingify settings |

---

## Related docs

- [Wingify flag values](./Wingify-Flag-Values.md) — same idea for flags  
- [API parity: Flagship vs Wingify](./API-Parity-Flagship-vs-Wingify.md)  
- [Optional Wingify SDK](./Optional-Wingify-SDK.md)  
