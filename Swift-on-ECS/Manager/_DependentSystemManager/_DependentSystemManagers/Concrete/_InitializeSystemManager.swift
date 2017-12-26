//
//  _InitializeSystemManager.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/10/17.
//

import SwiftExt

internal class _InitializeSystemManager: _DependentSystemManaging {
    internal typealias System = InitializeSystem
    
    internal typealias Dispatcher = _InitializeSystemDispatcher
    
    internal typealias SystemMetadata = _InitializeSystemMetadata
    
    internal typealias Handler = SystemMetadata.Handler
    
    internal unowned let _entityManager: _EntityManager
    
    internal unowned let _componentManager: _ComponentManager
    
    internal var _dispatchers: [_SystemDependencyIdentifier : Dispatcher]
    
    internal var _systems: [Int : System]
    
    internal let _systemPool: _DependentSystemPool<SystemMetadata>
    
    internal var _isInitialized: Bool
    
    internal var _lock: UnfairLock
    
    internal init(
        entityManager: _EntityManager,
        componentManager: _ComponentManager
        )
    {
        _dispatchers = [:]
        _entityManager = entityManager
        _componentManager = componentManager
        _systems = [:]
        _systemPool = .init()
        _isInitialized = false
        _lock = UnfairLock()
        _systemPool.beginTransaction()
    }
    
    deinit {
        _systemPool.endTransaction()
    }
    
    internal func initialize() {
        _sync {
            if !_isInitialized {
                _systemPool.endTransaction()
                
                for (id, metadata) in _systemPool {
                    let dispather = _dispatcher(for: id)
                    dispather.dispatch({metadata.handler(self)})
                }
                
                _systemPool.beginTransaction()
                _isInitialized = true
            } else {
                _log("Duplicate initialization.")
            }
        }
    }
    
    internal func tearDown() {
        _sync {
            _systemPool.endTransaction()
            _systemPool.beginTransaction()
            _isInitialized = false
        }
    }
    
    internal func _sync<R>(using closure: () -> R) -> R {
        return _lock.waitToAcquireAndPerform { closure() }
    }
}

extension _InitializeSystemManager: InitializeContext {}
