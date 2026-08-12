//
//  WingifyFlagAdapter.swift
//  Flagship
//

import Foundation
import Flagship
import Wingify_FME

enum WingifyFlagAdapter {
    /// Maps a Wingify `FlagCollection` into ABTasty `[featureKey: FSModification]`.
    /// Only enabled features are included.
    static func map(collection: FlagCollection) -> [String: FSModification] {
        var modifications: [String: FSModification] = [:]
        collection.forEach { featureKey, getFlag in
            if let modification = map(featureKey: featureKey, getFlag: getFlag) {
                modifications[featureKey] = modification
            }
        }
        return modifications
    }

    /// Maps a Wingify `GetFlag` result into an ABTasty `FSModification`.
    /// Stores all variables so `FSFlag.value(Value:defaultValue:)` can look them up by key.
    static func map(featureKey: String, getFlag: GetFlag) -> FSModification? {
        guard getFlag.isEnabled() else { return nil }

        let variables = getFlag.getVariables()
        let variableCount = variables.count
        var variablesMap: [String: Any] = [:]
        for variable in variables {
            let variableKey = (variable["key"] as? String) ?? ""
            guard !variableKey.isEmpty, let variableValue = variable["value"] else { continue }
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
        }

        // Always expose the primary value under the feature key so
        // `.value(Value: featureKey, defaultValue:)` works after sticky fetchFlags.
        if variablesMap[featureKey] == nil {
            variablesMap[featureKey] = value
        }

        return FSModification.fromWingify(
            featureKey: featureKey,
            value: value,
            campaignId: featureKey,
            variationId: "0",
            campaignName: featureKey,
            campaignType: "wingify",
            wingifyVariables: variablesMap,
            wingifyVariableCount: max(variableCount, variablesMap.count)
        )
    }
}
