//
//  FSWingifyIntegration.swift
//  Flagship
//

import Foundation

/// Optional Wingify engine plugged in by the `FlagshipWingify` product.
/// When nil, Flagship runs ABTasty-only (Wingify not linked).
public protocol FSWingifyIntegration: AnyObject {
    var isConfigured: Bool { get }
    /// Calls Wingify `fetchFlags`, adapts `FlagCollection` → Flagship modifications.
    func prefetchFlags(
        for visitor: FSVisitor,
        completion: @escaping (
            _ featureKeys: Set<String>,
            _ eventKeys: Set<String>,
            _ modifications: [String: FSModification]
        ) -> Void
    )
    /// Sends Wingify variation-shown impression (via `getFlag`) for Flagship `visitorExposed`.
    func exposeFlag(for visitor: FSVisitor, featureKey: String)
    /// Maps Flagship `sendHit(FSEvent)` → Wingify `trackEvent` when the event key is in Wingify settings.
    func trackEvent(
        for visitor: FSVisitor,
        eventName: String,
        eventProperties: [String: Any]?
    )
    func reset()
}

/// Holds the optional Wingify integration installed by `FlagshipWingify`.
public enum FSWingifyRuntime {
    public static weak var integration: FSWingifyIntegration?
}
