//
//  _ReactiveSystemDispatcher.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/23/17.
//

import Dispatch

internal class _ReactiveSystemDispatcher: _VariantSystemDispatching {
    internal let _userInteractiveQueue: DispatchQueue
    
    internal let _userInitiatedQueue: DispatchQueue
    
    internal let _utilityQueue: DispatchQueue
    
    internal let _backgroundQueue: DispatchQueue
    
    internal init() {
        _userInteractiveQueue = DispatchQueue(
            label: "com.WeZZard.ECS._ReactiveSystemDispatcher._userInteractiveQueue",
            qos: .userInteractive
        )
        _userInitiatedQueue = DispatchQueue(
            label: "com.WeZZard.ECS._ReactiveSystemDispatcher._userInitiatedQueue",
            qos: .userInitiated
        )
        _utilityQueue = DispatchQueue(
            label: "com.WeZZard.ECS._ReactiveSystemDispatcher._utilityQueue",
            qos: .utility
        )
        _backgroundQueue = DispatchQueue(
            label: "com.WeZZard.ECS._ReactiveSystemDispatcher._backgroundQueue",
            qos: .background
        )
    }
    
    internal func dispatch(
        _ workItem: @escaping () -> Void,
        with qualityOfService: SystemQoS
        )
    {
        switch qualityOfService {
        case .userInteractive:
            _userInteractiveQueue.async(execute: workItem)
        case .userInitiated:
            _userInitiatedQueue.async(execute: workItem)
        case .utility:
            _utilityQueue.async(execute: workItem)
        case .background:
            _backgroundQueue.async(execute: workItem)
        }
    }
}
