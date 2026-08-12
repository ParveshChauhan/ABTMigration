//
//  WingifyContextMapper.swift
//  Flagship
//

import Foundation
import Flagship
import Wingify_FME

enum WingifyContextMapper {
    private static let userAgentContextKey = "userAgent"
    private static let ipAddressContextKey = "ipAddress"

    /// Maps a Flagship visitor to `WingifyUserContext`.
    /// - `visitorId` → `id`
    /// - visitor context → `customVariables`
    /// - `wingifyUserContext` → `shouldUseDeviceIdAsUserId`, `bucketingSeed`, `postSegmentationVariables`
    /// - optional `userAgent` / `ipAddress` keys in context are also applied on the Wingify context
    static func makeContext(from visitor: FSVisitor) -> WingifyUserContext {
        let visitorContext = visitor.getContext()
        let options = visitor.wingifyUserContext

        let ipAddress = (visitorContext[ipAddressContextKey] as? String) ?? ""
        let context = WingifyUserContext(
            id: visitor.visitorId,
            shouldUseDeviceIdAsUserId: options?.shouldUseDeviceIdAsUserId ?? false,
            customVariables: visitorContext,
            postSegmentationVariables: options?.postSegmentationVariables,
            ipAddress: ipAddress.isEmpty ? nil : ipAddress,
            bucketingSeed: options?.bucketingSeed
        )

        if let userAgent = visitorContext[userAgentContextKey] as? String, !userAgent.isEmpty {
            context.userAgent = userAgent
        }

        return context
    }
}
