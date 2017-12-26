//
//  _DependentSystemsManager.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/6/17.
//

/// `_DependentSystemsManager` manages system dependency and schedules systems.
///
internal class _DependentSystemsManager {
    internal unowned let runtime: _Runtime
    
    internal let initialize: _InitializeSystemManager
    
    internal let commandFrame: _CommandFrameSystemManager
    
    internal let userEvent: _UserEventSystemManager
    
    internal init(
        runtime: _Runtime,
        entityManager: _EntityManager,
        componentManager: _ComponentManager
        )
    {
        self.runtime = runtime
        initialize = _InitializeSystemManager(
            entityManager: entityManager,
            componentManager: componentManager
        )
        commandFrame = _CommandFrameSystemManager(
            entityManager: entityManager,
            componentManager: componentManager
        )
        userEvent = _UserEventSystemManager(
            entityManager: entityManager,
            componentManager: componentManager
        )
    }
    
    internal func tearDown() {
        initialize.tearDown()
        commandFrame.tearDown()
        userEvent.tearDown()
    }
}
