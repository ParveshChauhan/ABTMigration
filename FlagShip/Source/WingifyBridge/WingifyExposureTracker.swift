//
//  WingifyExposureTracker.swift
//  FlagshipWingify
//

import Foundation
import Flagship
import Wingify_FME

/// Sends deferred Wingify variation-shown impressions via `exposeResult`.
/// Prefetch uses `fetchFlags` (`shouldSendTrackingCalls: false`); exposure runs on
/// Flagship `visitorExposed` / `value(...)` (default `visitorExposed: true`).
enum WingifyExposureTracker {
    private static let readyTimeout: TimeInterval = 10

    static func expose(visitor: FSVisitor, featureKey: String) {
        let trimmedKey = featureKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else { return }

        WingifyInitCoordinator.waitUntilReady(timeout: readyTimeout) { ready in
            guard ready else {
                FlagshipLogManager.Log(
                    level: .WARNING,
                    tag: .ACTIVATE,
                    messageToDisplay: FSLogMessage.MESSAGE(
                        "Wingify exposeResult skipped: engine not ready (flag=\(trimmedKey))"
                    )
                )
                return
            }

            let context = WingifyContextMapper.makeContext(from: visitor)
            let sent = WingifyFme.exposeResult(featureKey: trimmedKey, context: context)
            FlagshipLogManager.Log(
                level: .INFO,
                tag: .ACTIVATE,
                messageToDisplay: FSLogMessage.MESSAGE(
                    sent
                        ? "Wingify exposeResult sent (flag=\(trimmedKey))"
                        : "Wingify exposeResult no-op / already sent (flag=\(trimmedKey))"
                )
            )
        }
    }
}
