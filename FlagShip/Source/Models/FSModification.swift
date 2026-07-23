//
//  FSModification.swift
//  Flagship
//
//  Created by Adel on 29/09/2021.
//

import Foundation

public class FSModification {
    // CampaignId
    let campaignId:String
    // Variation Group
    let variationGroupId:String
    // VariationId
    let variationId:String
    // Is reference
    var isReference:Bool = false
    // Type
    var type:String
    // Slug
    var slug:String
    // Value for flag
    var value:Any
    // CampaignName
    let campaignName:String
    // VariationGroupName
    let variationGroupName:String
    // VariationName
    let variationName:String
    /// Wingify variables keyed by variable name (nil/empty for ABTasty flags).
    var wingifyVariables: [String: Any] = [:]
    /// Raw Wingify variable count from `getVariables()` (0 for ABTasty flags).
    var wingifyVariableCount: Int = 0
    
    // init from campaign and variation
    internal init(aCampaign:FSCampaign,aVariation:FSVariation, valueForFlag:Any){
        
        // Set campId
        campaignId = aCampaign.idCampaign
        
        // Set Name
        campaignName = aCampaign.name
        
        // Set type
        type = aCampaign.type
        
        // Slug
        slug = aCampaign.slug
        
        // Set variation group id
        variationGroupId = aCampaign.variationGroupId
        
        // Set variation name
        variationGroupName = aCampaign.variationGroupName
        
        // Set variation id
        variationId = aVariation.idVariation
        
        // Set Name for variation
        variationName = aVariation.name
        
        // Set reference
        isReference = aVariation.reference
 
        // Set value
        value = valueForFlag
        
    }
    
    
    // Init from cache
    internal init(cacheCamp:FSCacheCampaign, valueForFlag:Any){
        
        // Set campId
        campaignId = cacheCamp.campaignId
        // Set Name
        campaignName = cacheCamp.campaignName
        
        // Set type
        type = cacheCamp.type
        
        // Slug
        slug = cacheCamp.slug
        
        // Set variation group id
        variationGroupId = cacheCamp.variationGroupId
        // Set variation group name
        variationGroupName = cacheCamp.variationGroupName
        
        
        // Set variation id
        variationId = cacheCamp.variationId
        // Set Name for variation
        variationName = cacheCamp.variationName
        
        // Set reference
        isReference = cacheCamp.isReference
 
        // Set value
        value = valueForFlag
    }

    /// Creates a modification from a Wingify feature evaluation result.
    internal init(
        fromWingify featureKey: String,
        valueForFlag: Any,
        campaignId: String,
        variationId: String,
        campaignName: String,
        campaignType: String,
        wingifyVariables: [String: Any] = [:],
        wingifyVariableCount: Int = 0
    ) {
        self.campaignId = campaignId
        self.variationGroupId = campaignId
        self.variationId = variationId
        self.isReference = false
        self.type = campaignType
        self.slug = featureKey
        self.value = valueForFlag
        self.campaignName = campaignName
        self.variationGroupName = campaignName
        self.variationName = variationId
        self.wingifyVariables = wingifyVariables
        self.wingifyVariableCount = wingifyVariableCount > 0 ? wingifyVariableCount : wingifyVariables.count
    }

    static func fromWingify(
        featureKey: String,
        value: Any,
        campaignId: String,
        variationId: String,
        campaignName: String,
        campaignType: String,
        wingifyVariables: [String: Any] = [:],
        wingifyVariableCount: Int = 0
    ) -> FSModification {
        FSModification(
            fromWingify: featureKey,
            valueForFlag: value,
            campaignId: campaignId,
            variationId: variationId,
            campaignName: campaignName,
            campaignType: campaignType,
            wingifyVariables: wingifyVariables,
            wingifyVariableCount: wingifyVariableCount
        )
    }

    /// Resolves a Wingify variable by key. Returns nil if the variable key is missing.
    func wingifyVariableValue(for valueKey: String) -> Any? {
        wingifyVariables[valueKey]
    }
}
