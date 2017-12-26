//
//  _InitializeSystemDispatcher.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/23/17.
//

import Dispatch

internal class _InitializeSystemDispatcher: _DependentSystemDispatching {
    internal let _queue: DispatchQueue
    
    internal required init() {
        _queue = DispatchQueue(label: "com.WeZZard.ECS._InitializeSystemDispatcher._queue")
    }
    
    internal func dispatch(_ workItem: @escaping () -> Void) {
        _queue.async(execute: workItem)
    }
}
