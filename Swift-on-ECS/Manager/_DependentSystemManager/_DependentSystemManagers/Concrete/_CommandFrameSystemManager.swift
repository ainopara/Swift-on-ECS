//
//  _CommandFrameSystemManager.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/10/17.
//

import SwiftExt
import QuartzCore

internal class _CommandFrameSystemManager: _ImplicitSystemManaging {
    internal typealias System = CommandFrameSystem
    
    internal typealias Dispatcher = _ImplicitSystemDispatcher
    
    internal typealias SystemMetadata = _CommandFrameSystemMetadata
    
    internal typealias Handler = SystemMetadata.Handler
    
    internal unowned let _entityManager: _EntityManager
    
    internal unowned let _componentManager: _ComponentManager
    
    internal var _dispatchers: [_SystemDependencyIdentifier : Dispatcher]
    
    internal var _systems: [Int : System]
    
    internal let _systemPool: _DependentSystemPool<SystemMetadata>
    
    internal var _lock: UnfairLock
    
    internal var _displayLink: CADisplayLink!
    
    internal var _scheduleInfo: (frame: Int, time: TimeInterval)?
    
    internal init(
        entityManager: _EntityManager,
        componentManager: _ComponentManager
        )
    {
        _entityManager = entityManager
        _componentManager = componentManager
        _dispatchers = [:]
        _systems = [:]
        _systemPool = .init()
        _lock = UnfairLock()
        _systemPool.beginTransaction()
    }
    
    deinit {
        _systemPool.endTransaction()
        if let displayLink = _displayLink {
            displayLink.invalidate()
        }
    }
    
    @objc
    internal func _tick(_ sender: CADisplayLink) {
        _systemPool.endTransaction()
        _schedule()
        _systemPool.beginTransaction()
    }
    
    internal func _prepareForScheduleIfNeeded() {
        if _displayLink == nil {
            _displayLink = CADisplayLink(
                target: self,
                selector: #selector(_tick(_:))
            )
            _displayLink.add(to: .main, forMode: .commonModes)
        }
    }
    
    internal func _cancelScheduleIfNeeded() {
        if _displayLink != nil {
            _displayLink.invalidate()
            _displayLink = nil
        }
    }
    
    internal func _sync<R>(using closure: () -> R) -> R {
        return _lock.waitToAcquireAndPerform { closure() }
    }
    
    internal func tearDown() {
        _sync {
            _systemPool.endTransaction()
            _scheduleInfo = nil
            _systemPool.beginTransaction()
        }
    }
    
    internal func _workItem(
        for systemMetadata: System._Metadata,
        forFrame frame: Int,
        forTime time: TimeInterval,
        forDeltaTime deltaTime: TimeInterval
        ) -> (() -> Void)
    {
        return { systemMetadata.handler(self, time, deltaTime, frame) }
    }
}

extension _CommandFrameSystemManager: CommandFrameContext {}
