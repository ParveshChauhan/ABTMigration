//
//  FSVisitorBuilder.swift
//  Flagship
//
//  Created by Adel on 09/12/2021.
//

import Foundation

public typealias OnFetchFlagsStatusChanged = ((_ newStatus: FSFetchStatus, _ reason: FSFetchReasons)-> Void)?

/// Visitor builder
@objc public class FSVisitorBuilder: NSObject {
    /// Visitor
    public private(set) var _visitorId: String
    /// Has consented
    public private(set) var _hasConsented: Bool = true
    /// Context
    public private(set) var _context: [String: Any] = [:]
    /// Is authenticated
    public private(set) var _isAuthenticated: Bool = false
    /// instance
    private var _instanceType: Instance = .SHARED_INSTANCE
    /// Optional Wingify user-context options
    private var _wingifyUserContext: FSWingifyVisitorOptions?
    
    // Callbak for status
    private var _onFetchFlagsStatusChanged: OnFetchFlagsStatusChanged = nil
    
    public init(_ visitorId: String, _ hasConsented: Bool, instanceType: Instance = .SHARED_INSTANCE) {
        if visitorId.isEmpty {
            _visitorId = FSGenerator.generateFlagShipId()
            FlagshipLogManager.Log(level: .WARNING, tag: .VISITOR, messageToDisplay: FSLogMessage.ID_NULL_OR_EMPTY)
            
        } else {
            _visitorId = visitorId
        }
        
        _instanceType = instanceType
        _hasConsented = hasConsented
    }
    
    @objc public func withContext(context: [String: Any])->FSVisitorBuilder {
        _context = context
        return self
    }

    /// Sets Wingify user-context options used when mapping this visitor to `WingifyUserContext`.
    /// - Parameters:
    ///   - shouldUseDeviceIdAsUserId: When true, Wingify may fall back to the device ID if needed.
    ///   - bucketingSeed: Optional seed for consistent Wingify bucketing.
    ///   - postSegmentationVariables: Custom-variable keys used for Wingify post-segmentation.
    @discardableResult
    @objc public func withWingifyUserContext(
        shouldUseDeviceIdAsUserId: Bool = false,
        bucketingSeed: String? = nil,
        postSegmentationVariables: [String]? = nil
    ) -> FSVisitorBuilder {
        _wingifyUserContext = FSWingifyVisitorOptions(
            shouldUseDeviceIdAsUserId: shouldUseDeviceIdAsUserId,
            bucketingSeed: bucketingSeed,
            postSegmentationVariables: postSegmentationVariables
        )
        return self
    }
    
    @objc public func isAuthenticated(_ autenticated: Bool)->FSVisitorBuilder {
        _isAuthenticated = autenticated
        return self
    }
    
    public func withFetchFlagsStatus(_ pCallback: OnFetchFlagsStatusChanged)->FSVisitorBuilder {
        _onFetchFlagsStatusChanged = pCallback
        return self
    }
    
    @objc public func build()->FSVisitor {
        let newVisitor = Flagship.sharedInstance.newVisitor(_visitorId, context: _context, hasConsented: _hasConsented, isAuthenticated: _isAuthenticated, pOnFetchFlagStatusChanged: _onFetchFlagsStatusChanged)
        newVisitor.wingifyUserContext = _wingifyUserContext
        
        if _instanceType == .SHARED_INSTANCE {
            /// Set this visitor as shared instance
            Flagship.sharedInstance.setSharedVisitor(newVisitor)
        }
        return newVisitor
    }
}
