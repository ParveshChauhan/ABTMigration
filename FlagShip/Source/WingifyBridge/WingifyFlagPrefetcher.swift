//
//  WingifyFlagPrefetcher.swift
//  Flagship
//

import Foundation
import Flagship
import Wingify_FME

struct WingifyPrefetchResult {
    /// Feature keys from the Wingify `FlagCollection`
    let featureKeys: Set<String>
    /// Trackable event identifiers from Wingify settings (feature + holdout metrics)
    let eventKeys: Set<String>
    /// Only enabled features mapped to FSModification
    let modifications: [String: FSModification]
}

/// Fetches Wingify flags via `WingifyFme.fetchFlags` and maps results to `FSModification`.
enum WingifyFlagPrefetcher {
    private static let evaluationTimeout: TimeInterval = 15

    /// Waits for Wingify readiness, then calls `fetchFlags` once (all features, no variation-shown impressions).
    static func evaluateAllFeatures(
        visitor: FSVisitor,
        completion: @escaping (WingifyPrefetchResult) -> Void
    ) {
        WingifyInitCoordinator.waitUntilReady(timeout: evaluationTimeout) { ready in
            guard ready else {
                completion(WingifyPrefetchResult(featureKeys: [], eventKeys: [], modifications: [:]))
                return
            }

            let context = WingifyContextMapper.makeContext(from: visitor)
            let eventKeys = Set(WingifyFme.getEventKeys())

            // Single bulk call — no getFeatureKeys + N× getFlag loop.
            // `flagNames: nil` evaluates every feature from settings.
            // fetchFlags uses shouldSendTrackingCalls: false → sticky + variationShownSent=false.
            // Flagship value()/visitorExposed calls exposeResult to send impressions.
            WingifyFme.fetchFlags(flagNames: nil, context: context) { collection in
                completion(
                    WingifyPrefetchResult(
                        featureKeys: collection.keys(),
                        eventKeys: eventKeys,
                        modifications: WingifyFlagAdapter.map(collection: collection)
                    )
                )
            }
        }
    }
}
