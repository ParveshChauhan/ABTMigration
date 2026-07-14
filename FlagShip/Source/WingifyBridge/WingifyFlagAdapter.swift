//
//  WingifyFlagAdapter.swift
//  Flagship
//

import Foundation
import Wingify_FME

enum WingifyFlagAdapter {
    /// Maps a Wingify `GetFlag` result into an ABTasty `FSModification`.
    /// Uses the feature key as the primary variable key when resolving the flag value.
    static func map(featureKey: String, getFlag: GetFlag) -> FSModification? {
        guard getFlag.isEnabled() else { return nil }

        let variables = getFlag.getVariables()
        let value: Any

        if let primary = variables.first(where: { ($0["key"] as? String) == featureKey }),
           let primaryValue = primary["value"] {
            value = primaryValue
        } else if let first = variables.first, let firstValue = first["value"] {
            value = firstValue
        } else {
            value = getFlag.getVariable(key: featureKey, defaultValue: NSNull())
            if value is NSNull { return nil }
        }

        return FSModification.fromWingify(
            featureKey: featureKey,
            value: value,
            campaignId: featureKey,
            variationId: "0",
            campaignName: featureKey,
            campaignType: "wingify"
        )
    }
}
