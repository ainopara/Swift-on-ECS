//
//  _UserEventSystemManager.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/10/17.
//

import SwiftExt
import CoreFoundation

internal class _UserEventSystemManager: _ImplicitSystemManaging {
    internal typealias System = UserEventSystem
    
    internal typealias Dispatcher = _ImplicitSystemDispatcher
    
    internal typealias SystemMetadata = _UserEventSystemMetadata
    
    internal typealias Handler = SystemMetadata.Handler
    
    internal unowned let _entityManager: _EntityManager
    
    internal unowned let _componentManager: _ComponentManager
    
    internal var _dispatchers: [_SystemDependencyIdentifier : Dispatcher]
    
    internal var _systems: [Int : System]
    
    internal let _systemPool: _DependentSystemPool<SystemMetadata>
    
    internal var _lock: UnfairLock
    
    internal var _runLoopObserver: CFRunLoopObserver!
    
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
        if let runLoopObserver = _runLoopObserver {
            CFRunLoopObserverInvalidate(runLoopObserver)
        }
    }
    
    internal var _runLoopObserverContext_: CFRunLoopObserverContext!
    
    internal var _runLoopObserverContext: CFRunLoopObserverContext {
        get {
            if _runLoopObserverContext_ == nil {
                _runLoopObserverContext_ = CFRunLoopObserverContext(
                    version: 0,
                    info: Unmanaged.passUnretained(self).toOpaque(),
                    retain: nil,
                    release: nil,
                    copyDescription: nil
                )
            }
            return _runLoopObserverContext_
        }
        set { _runLoopObserverContext_ = newValue }
    }
    
    internal func _prepareForScheduleIfNeeded() {
        if _runLoopObserver == nil {
            let activities: CFRunLoopActivity = [.beforeWaiting, .exit]
            _runLoopObserver = CFRunLoopObserverCreate(
                kCFAllocatorDefault,
                activities.rawValue,
                true,
                .max,
                _UserEventSystemManagerHandleMainRunLoopEvents,
                &_runLoopObserverContext
            )
            CFRunLoopAddObserver(
                CFRunLoopGetMain(),
                _runLoopObserver,
                .commonModes
            )
        }
    }
    
    internal func _cancelScheduleIfNeeded() {
        if _runLoopObserver != nil {
            CFRunLoopObserverInvalidate(_runLoopObserver)
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
        return { systemMetadata.handler(self, time, deltaTime) }
    }
}

extension _UserEventSystemManager: UserEventContext {}

internal func _UserEventSystemManagerHandleMainRunLoopEvents(
    _ observer: CFRunLoopObserver?,
    _ activity: CFRunLoopActivity,
    _ context: UnsafeMutableRawPointer?
    )
{
    let contextPtr = context!.bindMemory(
        to: CFRunLoopObserverContext.self, capacity: 1
    )
    
    let `self` = Unmanaged<_UserEventSystemManager>
        .fromOpaque(contextPtr[0].info)
        .takeUnretainedValue()
    
    if activity == .beforeWaiting || activity == .exit {
        // beforeWaiting: end current run-loop -> enter next run-loop.
        // exit: exit run-loop.
        `self`._systemPool.endTransaction()
        `self`._schedule()
        `self`._systemPool.beginTransaction()
    } else {
        fatalError("Unexpected run-loop events.")
    }
}
