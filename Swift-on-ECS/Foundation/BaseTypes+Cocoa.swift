//
//  BaseTypes+Cocoa.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/1/17.
//

import QuartzCore
import os

// MARK: - Timing
internal func _CurrentTime() -> TimeInterval { return CACurrentMediaTime() }

// MARK: - EntityID
extension EntityID {
    internal init() {
        #if arch(arm64) || arch(x86_64)
            _value = Int(arc4random()) + Int(arc4random())
        #elseif arch(arm) || arch(i386)
            _value = Int(arc4random())
        #endif
    }
}

// MARK: - Logging
internal struct _LogType: RawRepresentable {
    internal typealias RawValue = OSLogType
    internal var rawValue: RawValue
    internal init(rawValue: RawValue) { self.rawValue = rawValue }
    
    internal static let `default`   = _LogType(rawValue: .default)
    internal static let info        = _LogType(rawValue: .info)
    internal static let debug       = _LogType(rawValue: .debug)
    internal static let error       = _LogType(rawValue: .error)
    internal static let fault       = _LogType(rawValue: .fault)
}
