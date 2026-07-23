//
//  Flagship.swift
//  Flagship
//
//  Created by Adel Ferguen on 23/04/2024.
//  Copyright © 2024 FlagShip. All rights reserved.
//

import Foundation

public class FSFlag: NSObject {
    // Key for flag modification
    var key: String
    // Strategy to adopt depending the scenario
    var strategy: FSStrategy?
    // Safer exposure to display warning - by default the value is false
    var isSafeToExpose: Bool = false
    // Default value changing on the fly
    public private(set) var defaultValue: Any? /// Change on the fly
    // Current status - by default the value is not found
    private var _status: FSFlagStatus {
        return strategy?.getStrategy().getFlagStatus(key) ?? .NOT_FOUND
    }
    
    // Status value
    public var status: FSFlagStatus {
        return _status
    }
    
    // Init without a defaultValue
    init(_ aKey: String, _ aStrategy: FSStrategy?) {
        key = aKey
        strategy = aStrategy
    }
    
    /// Getting value for flag
    /// - Parameters:
    ///   - Value: Optional Wingify variable key. When set for a Wingify-backed flag, returns that variable's value; if missing or type-mismatched, returns `defaultValue`. Ignored for ABTasty flags.
    ///   - defaultValue: input given by the developer
    ///   - visitorExposed: optional input to expose flag
    /// - Returns: Return a flag value. See the documentation for more details
    ///
    /// Examples:
    /// ```
    /// flag.value(defaultValue: "default")
    /// flag.value(Value: "cta", defaultValue: "default-cta")
    /// flag.value(Value: "discount", defaultValue: 0)
    /// ```
    public func value<T>(Value valueKey: String? = nil, defaultValue: T?, visitorExposed: Bool = true) -> T? {
        var result: T?
        // Update the default value
        self.defaultValue = defaultValue
        if let flagModification = strategy?.getStrategy().getFlagModification(key) {
            // Wingify: non-overloaded API with multiple variables → return defaultValue + warning
            if shouldBlockNonOverloadedWingifyValue(flagModification, valueKey: valueKey) {
                if visitorExposed {
                    self.visitorExposed()
                }
                return defaultValue
            }

            let resolvedValue = resolveFlagValue(from: flagModification, Value: valueKey, defaultValue: defaultValue)

            if let resolvedValue = resolvedValue {
                if isSameType_or_DefaultValue_Nil(defaultValue, resolvedValue) {
                    FlagshipLogManager.Log(level: .ALL, tag: .GET_MODIFICATION, messageToDisplay: .MESSAGE("The value of the flag `\(key)` is `\(resolvedValue)`"))
                    result = resolvedValue as? T
                } else {
                    result = defaultValue
                    let msg = "For the visitor \(strategy?.visitor.visitorId ?? ""), the flag `\(key)` value type does not match. Therefore, the default value \(String(describing: defaultValue)) has been returned"
                    FlagshipLogManager.Log(level: .ALL, tag: .ACTIVATE, messageToDisplay: FSLogMessage.MESSAGE(msg))
                }
            } else {
                result = defaultValue
                let msg = "For the visitor \(strategy?.visitor.visitorId ?? ""), no value was found for flag `\(key)`\(valueKey.map { " variable `\($0)`" } ?? ""). Therefore, the default value \(String(describing: defaultValue)) has been returned"
                FlagshipLogManager.Log(level: .ALL, tag: .GET_MODIFICATION, messageToDisplay: FSLogMessage.MESSAGE(msg))
            }
            
            /// Activate
            if visitorExposed {
                self.visitorExposed()
            }
            return result
        }
        FlagshipLogManager.Log(level: .ALL, tag: .GET_MODIFICATION, messageToDisplay: .MESSAGE("The key doon't exist ===> return the defaultValue"))
        
        return defaultValue
    }

    /// Resolves the raw value for ABTasty or Wingify (optionally by variable key).
    private func resolveFlagValue<T>(from modification: FSModification, Value valueKey: String?, defaultValue: T?) -> Any? {
        if modification.type == "wingify", let valueKey = valueKey, !valueKey.isEmpty {
            return modification.wingifyVariableValue(for: valueKey)
        }
        // Single Wingify variable (or ABTasty): use the primary modification value
        return modification.value
    }

    /// Wingify non-overloaded `value(defaultValue:)` with multiple variables:
    /// log a warning and signal the caller to return `defaultValue`.
    private func shouldBlockNonOverloadedWingifyValue(_ modification: FSModification, valueKey: String?) -> Bool {
        guard modification.type == "wingify" else { return false }

        let hasValueKey = valueKey.map { !$0.isEmpty } ?? false
        guard !hasValueKey else { return false }

        let variableCount = max(modification.wingifyVariableCount, modification.wingifyVariables.count)
        guard variableCount > 1 else { return false }

        let msg = "Wingify feature '\(key)' contains multiple variables. Please specify a variable key using .value(Value: \"variableKey\", defaultValue:)."
        FlagshipLogManager.Log(level: .WARNING, tag: .GET_MODIFICATION, messageToDisplay: .MESSAGE(msg))
        return true
    }
    
    @objc public func visitorExposed() {
        /// check if the value function is called before
        if strategy?.getStrategy().getFlagModification(key) != nil {
            // Before activate we should check if the last call of value() function to display the appropriate warning message.
            isSaferExposure()
            // Send activate
            strategy?.getStrategy().activateFlag(self)
            
        } else { // The key was not found
            FlagshipLogManager.Log(level: .ALL, tag: .ACTIVATE, messageToDisplay: FSLogMessage.MESSAGE("For the visitor \"\(strategy?.visitor.visitorId ?? "")\", no flags were found with the key \"\(key)\". As a result, user exposure will not be sent."))
            // Send TR on flag not found
            FSDataUsageTracking.sharedInstance.proceesTSFlag(crticalPointLabel: .VISITOR_EXPOSED_FLAG_NOT_FOUND, f: self, v: strategy?.visitor)
        }
    }
    
    @objc public func exists()->Bool {
        return (strategy?.getStrategy().getModificationInfo(key) != nil)
    }
    
    @objc public func metadata()->FSFlagMetadata {
        if let flagModification = strategy?.getStrategy().getFlagModification(key) {
            return FSFlagMetadata(flagModification)
        }
        return FSFlagMetadata(nil)
    }
    
    /// _ Check the type of flag's value with the default value
    /// _ This check return true when the default value is nil
    private func isSameType_or_DefaultValue_Nil<T>(_ defaultValue: T?, _ value: Any)->Bool {
        var matchedType = false
        /// If the default value given in the getFalg() is nil then the check return true
        if defaultValue == nil {
            isSafeToExpose = true
            return true
        }
        matchedType = value is T; isSafeToExpose = matchedType
        return matchedType
    }
}
