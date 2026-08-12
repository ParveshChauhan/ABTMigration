//
//  WingifyEventTracker.swift
//  FlagshipWingify
//

import Foundation
import Flagship
import Wingify_FME

/// Bridges Flagship `FSEvent` hits to Wingify `trackEvent`.
enum WingifyEventTracker {
    private static let readyTimeout: TimeInterval = 10

    static func track(
        visitor: FSVisitor,
        eventName: String,
        eventProperties: [String: Any]?
    ) {
        let trimmedName = eventName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            FlagshipLogManager.Log(
                level: .WARNING,
                tag: .TRACKING,
                messageToDisplay: FSLogMessage.MESSAGE("Wingify trackEvent skipped: empty event name")
            )
            return
        }

        WingifyInitCoordinator.waitUntilReady(timeout: readyTimeout) { ready in
            guard ready else {
                FlagshipLogManager.Log(
                    level: .WARNING,
                    tag: .TRACKING,
                    messageToDisplay: FSLogMessage.MESSAGE(
                        "Wingify trackEvent skipped: engine not ready (event=\(trimmedName))"
                    )
                )
                return
            }

            let context = WingifyContextMapper.makeContext(from: visitor)
            WingifyFme.trackEvent(
                eventName: trimmedName,
                context: context,
                eventProperties: eventProperties
            )

            FlagshipLogManager.Log(
                level: .INFO,
                tag: .TRACKING,
                messageToDisplay: FSLogMessage.MESSAGE(
                    "Wingify trackEvent sent (event=\(trimmedName))"
                )
            )
        }
    }
}
