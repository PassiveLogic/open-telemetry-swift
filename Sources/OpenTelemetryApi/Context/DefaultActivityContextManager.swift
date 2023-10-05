/*
 * Copyright The OpenTelemetry Authors
 * SPDX-License-Identifier: Apache-2.0
 */

// This class implements the Linux behavior required to employ activity, or thread, contexts as offered by
// Apple's os_activity library. There is not a one-to-one mapping between the platform libraries employed;
// we do the best we can for Linux.

import Foundation

import TaskSupport

class DefaultActivityContextManager: ContextManager {
    static let instance = DefaultActivityContextManager()

    let rlock = NSRecursiveLock()

    var contextMap = [activity_id_t: [String: AnyObject]]()

    func getCurrentContextValue(forKey key: OpenTelemetryContextKeys) -> AnyObject? {
        let (activityIdent, parentIdent) = TaskSupport.instance.getIdentifiers()

        rlock.lock()

        defer {
            rlock.unlock()
        }

        guard let context = contextMap[activityIdent] ?? contextMap[parentIdent] else {
            return nil
        }

        return context[key.rawValue]
    }

    func setCurrentContextValue(forKey key: OpenTelemetryContextKeys, value: AnyObject) {
        let (activityIdent, _) = TaskSupport.instance.getIdentifiers()
        
        rlock.lock()

        defer {
            rlock.unlock()
        }

        if contextMap[activityIdent] == nil || contextMap[activityIdent]?[key.rawValue] != nil {
            let (activityIdent, _) = TaskSupport.instance.createActivityContext()

            contextMap[activityIdent] = [String: AnyObject]()
        }

        contextMap[activityIdent]?[key.rawValue] = value
    }

    func removeContextValue(forKey key: OpenTelemetryContextKeys, value: AnyObject) {
        let activityIdent = TaskSupport.instance.getCurrentIdentifier()
        
        rlock.lock()

        defer {
            rlock.unlock()
        }
        
        if let currentValue = contextMap[activityIdent]?[key.rawValue], currentValue === value {
            contextMap[activityIdent]?[key.rawValue] = nil

            if contextMap[activityIdent]?.isEmpty ?? false {
                contextMap[activityIdent] = nil
            }
        }
    }
}
