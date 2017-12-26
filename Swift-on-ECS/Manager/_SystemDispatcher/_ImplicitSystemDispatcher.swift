//
//  _ImplicitSystemDispatcher.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/23/17.
//

import Dispatch

internal class _ImplicitSystemDispatcher: _DependentSystemDispatching {
    internal let _rootQueue: DispatchQueue
    
    internal let _userInteractiveQueue: DispatchQueue
    
    internal let _userInitiatedQueue: DispatchQueue
    
    internal let _utilityQueue: DispatchQueue
    
    internal let _backgroundQueue: DispatchQueue
    
    internal required init() {
        _rootQueue = DispatchQueue(
            label: "com.WeZZard.ECS._ImplicitSystemDispatcher._rootQueue"
        )
        _userInteractiveQueue = DispatchQueue(
            label: "com.WeZZard.ECS._ImplicitSystemDispatcher._userInteractiveQueue",
            qos: .userInteractive,
            autoreleaseFrequency: .never,
            target: _rootQueue
        )
        _userInitiatedQueue = DispatchQueue(
            label: "com.WeZZard.ECS._ImplicitSystemDispatcher._userInitiatedQueue",
            qos: .userInitiated,
            autoreleaseFrequency: .never,
            target: _rootQueue
        )
        _utilityQueue = DispatchQueue(
            label: "com.WeZZard.ECS._ImplicitSystemDispatcher._utilityQueue",
            qos: .utility,
            autoreleaseFrequency: .never,
            target: _rootQueue
        )
        _backgroundQueue = DispatchQueue(
            label: "com.WeZZard.ECS._ImplicitSystemDispatcher._backgroundQueue",
            qos: .background,
            autoreleaseFrequency: .never,
            target: _rootQueue
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
