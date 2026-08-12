//
//  FSWingifyVisitorOptions.swift
//  Flagship
//

import Foundation

/// Wingify-specific options attached to a Flagship visitor.
/// Used when building `WingifyUserContext` during Wingify flag evaluation.
@objc public class FSWingifyVisitorOptions: NSObject {
    /// When true, Wingify may use the device ID as user id if no id is available.
    public let shouldUseDeviceIdAsUserId: Bool
    /// Optional seed used for consistent Wingify bucketing across users.
    public let bucketingSeed: String?
    /// Keys from custom variables used for Wingify post-segmentation.
    public let postSegmentationVariables: [String]?

    @objc public init(
        shouldUseDeviceIdAsUserId: Bool = false,
        bucketingSeed: String? = nil,
        postSegmentationVariables: [String]? = nil
    ) {
        self.shouldUseDeviceIdAsUserId = shouldUseDeviceIdAsUserId
        self.bucketingSeed = bucketingSeed
        self.postSegmentationVariables = postSegmentationVariables
        super.init()
    }
}
