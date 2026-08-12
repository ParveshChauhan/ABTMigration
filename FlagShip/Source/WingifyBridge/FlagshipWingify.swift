//
//  FlagshipWingify.swift
//  FlagshipWingify
//

import Foundation
import Flagship
import Wingify_FME

/// Dual-engine add-on: ABTasty Flagship + Wingify FME.
/// Link this product **in addition to** `Flagship` when Wingify is required.
public enum FlagshipWingify {
    private static let lock = NSLock()
    private static var installed = false
    private static let integration = WingifyIntegration()

    /// Registers the Wingify engine with Flagship. Safe to call multiple times.
    public static func install() {
        lock.lock()
        defer { lock.unlock() }
        guard !installed else { return }
        FSWingifyRuntime.integration = integration
        installed = true
    }
}

private final class WingifyIntegration: FSWingifyIntegration {
    var isConfigured: Bool {
        WingifyInitCoordinator.isConfigured
    }

    func prefetchFlags(
        for visitor: FSVisitor,
        completion: @escaping (Set<String>, Set<String>, [String: FSModification]) -> Void
    ) {
        WingifyFlagPrefetcher.evaluateAllFeatures(visitor: visitor) { result in
            completion(result.featureKeys, result.eventKeys, result.modifications)
        }
    }

    func exposeFlag(for visitor: FSVisitor, featureKey: String) {
        WingifyExposureTracker.expose(visitor: visitor, featureKey: featureKey)
    }

    func trackEvent(
        for visitor: FSVisitor,
        eventName: String,
        eventProperties: [String: Any]?
    ) {
        WingifyEventTracker.track(
            visitor: visitor,
            eventName: eventName,
            eventProperties: eventProperties
        )
    }

    func reset() {
        WingifyInitCoordinator.reset()
    }
}

public extension Flagship {
    /// Starts ABTasty and optionally Wingify when `wingifyInitOptions` is provided.
    /// Requires the `FlagshipWingify` product to be linked.
    func start(
        envId: String,
        apiKey: String,
        config: FlagshipConfig? = nil,
        wingifyInitOptions: WingifyInitOptions?
    ) {
        FlagshipWingify.install()
        start(envId: envId, apiKey: apiKey, config: config)

        guard let wingifyInitOptions = wingifyInitOptions else { return }

        WingifyInitCoordinator.initialize(options: wingifyInitOptions) { success in
            FlagshipLogManager.Log(
                level: .ALL,
                tag: .INITIALIZATION,
                messageToDisplay: FSLogMessage.MESSAGE(
                    success
                        ? "Wingify engine initialized"
                        : "Wingify engine failed to initialize"
                )
            )
        }
    }
}
