//
//  WingifyFlagPrefetcher.swift
//  Flagship
//

import Foundation
import Wingify_FME

struct WingifyPrefetchResult {
    /// All feature keys from Wingify settings
    let featureKeys: Set<String>
    /// Only enabled features mapped to FSModification
    let modifications: [String: FSModification]
}

/// Evaluates all Wingify feature keys and maps results to `FSModification`.
enum WingifyFlagPrefetcher {
    private static let queue = DispatchQueue(label: "com.flagship.wingify.prefetch", attributes: .concurrent)
    private static let evaluationTimeout: TimeInterval = 15

    /// Waits for Wingify readiness, reads feature keys from settings, evaluates each via `getFlag`.
    static func evaluateAllFeatures(
        visitor: FSVisitor,
        completion: @escaping (WingifyPrefetchResult) -> Void
    ) {
        WingifyInitCoordinator.waitUntilReady(timeout: evaluationTimeout) { ready in
            guard ready else {
                completion(WingifyPrefetchResult(featureKeys: [], modifications: [:]))
                return
            }

            let keys = WingifyFme.getFeatureKeys()
            let featureKeys = Set(keys)
            guard !keys.isEmpty else {
                completion(WingifyPrefetchResult(featureKeys: featureKeys, modifications: [:]))
                return
            }

            let context = WingifyContextMapper.makeContext(from: visitor)
            let group = DispatchGroup()
            var modifications: [String: FSModification] = [:]
            let lock = NSLock()

            for key in keys {
                group.enter()
                WingifyFme.getFlag(featureKey: key, context: context) { getFlag in
                    if let modification = WingifyFlagAdapter.map(featureKey: key, getFlag: getFlag) {
                        lock.lock()
                        modifications[key] = modification
                        lock.unlock()
                    }
                    group.leave()
                }
            }

            group.notify(queue: queue) {
                completion(WingifyPrefetchResult(featureKeys: featureKeys, modifications: modifications))
            }
        }
    }
}
