//
//  Utilities+Cocoa.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 11/30/17.
//

import os

internal func _log(for type: _LogType = .`default`, subsystem: _LogSubsystem = .`default`, category: _LogCategory = .`default`, _ message: StaticString, _ args: CVarArg...) {
    os_log(message, log: OSLog(subsystem: subsystem.rawValue, category: category.rawValue), type: type.rawValue, args)
}

@_transparent
internal func _abstract(_ class: AnyClass, _ function: StaticString = #function, _ line: Int = #line, _ file: StaticString = #file) -> Never {
    fatalError("Abstract class: \(`class`) in file: \"\(file)\" at line: \(line). You need to implement the function: \"\(function)\" by yourself.")
}

@_transparent
internal func _abstract(_ object: AnyObject, _ function: StaticString = #function, _ line: Int = #line, _ file: StaticString = #file) -> Never {
    fatalError("Abstract class: \(type(of: object)) in file: \"\(file)\" at line: \(line). You need to implement the function: \"\(function)\" by yourself.")
}

@_transparent
internal func _unimplemented(_ function: StaticString = #function, _ line: Int = #line, _ file: StaticString = #file) -> Never {
    fatalError("Unimplemented function: \"\(function)\" in file: \"\(file)\" at line: \(line).")
}
