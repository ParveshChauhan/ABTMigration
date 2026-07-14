//
//  WingifyFlagAdapter.swift
//  Flagship
//

import Foundation
import Wingify_FME

enum WingifyFlagAdapter {
    /// Maps a Wingify `GetFlag` result into an ABTasty `FSModification`.
    /// Stores all variables so `FSFlag.value(Value:defaultValue:)` can look them up by key.
    static func map(featureKey: String, getFlag: GetFlag) -> FSModification? {
        guard getFlag.isEnabled() else { return nil }

        let variables = getFlag.getVariables()
        var variablesMap: [String: Any] = [:]
        for variable in variables {
            guard let variableKey = variable["key"] as? String, !variableKey.isEmpty,
                  let variableValue = variable["value"] else { continue }
            variablesMap[variableKey] = variableValue
        }

        let value: Any
        if let primaryValue = variablesMap[featureKey] {
            value = primaryValue
        } else if let first = variables.first, let firstValue = first["value"] {
            value = firstValue
        } else {
            let fallback = getFlag.getVariable(key: featureKey, defaultValue: NSNull())
            if fallback is NSNull { return nil }
            value = fallback
            variablesMap[featureKey] = fallback
        }

        return FSModification.fromWingify(
            featureKey: featureKey,
            value: value,
            campaignId: featureKey,
            variationId: "0",
            campaignName: featureKey,
            campaignType: "wingify",
            wingifyVariables: variablesMap
        )
    }
}
