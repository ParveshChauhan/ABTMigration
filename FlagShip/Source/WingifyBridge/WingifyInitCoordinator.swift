//
//  WingifyInitCoordinator.swift
//  Flagship
//

import Foundation
import Wingify_FME

enum WingifyInitCoordinator {
    private static let queue = DispatchQueue(label: "com.flagship.wingify.init", attributes: .concurrent)
    private static var _isReady = false
    private static var _isConfigured = false
    private static var pendingCompletions: [() -> Void] = []

    /// True when `start` was called with a non-nil `WingifyInitOptions`.
    static var isConfigured: Bool {
        queue.sync { _isConfigured }
    }

    static var isReady: Bool {
        queue.sync { _isReady }
    }

    static func initialize(options: WingifyInitOptions, completion: @escaping (Bool) -> Void) {
        queue.async(flags: .barrier) {
            _isConfigured = true

            if _isReady {
                DispatchQueue.main.async { completion(true) }
                return
            }

            WingifyFme.initialize(options: options) { result in
                switch result {
                case .success:
                    queue.async(flags: .barrier) {
                        _isReady = true
                        let callbacks = pendingCompletions
                        pendingCompletions.removeAll()
                        DispatchQueue.main.async {
                            callbacks.forEach { $0() }
                            completion(true)
                        }
                    }
                case .failure(let error):
                    FlagshipLogManager.Log(
                        level: .ERROR,
                        tag: .INITIALIZATION,
                        messageToDisplay: FSLogMessage.MESSAGE("Wingify initialization failed: \(error.localizedDescription)")
                    )
                    DispatchQueue.main.async { completion(false) }
                }
            }
        }
    }

    static func waitUntilReady(timeout: TimeInterval = 10, completion: @escaping (Bool) -> Void) {
        if isReady {
            completion(true)
            return
        }

        guard isConfigured else {
            completion(false)
            return
        }

        queue.async(flags: .barrier) {
            if _isReady {
                DispatchQueue.main.async { completion(true) }
                return
            }
            pendingCompletions.append { completion(true) }
        }

        DispatchQueue.global().asyncAfter(deadline: .now() + timeout) {
            if !isReady {
                DispatchQueue.main.async { completion(false) }
            }
        }
    }

    static func reset() {
        queue.async(flags: .barrier) {
            WingifyFme.clearAllInstances()
            _isReady = false
            _isConfigured = false
            pendingCompletions.removeAll()
        }
    }
}
