//
//  Manager.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 11/29/17.
//

import SwiftExt

/// `Manager` manages entities-components and systems.
///
/// System Schedule Space
/// =====================
/// Each kind of systems is in different schedule space - because the
/// timing to schedule is different. It is impossible to build depedencies
/// among systems in different schedule spaces.
///
/// System Dependency
/// =================
/// Systems schedules with dependencies. Any system can have preceeded
/// systems and succeeded systems. `Manager` builds a directed acyclic
/// graph for each kind of system to describe those dependencies and
/// schedules systems with it.
///
/// Inter-System Intrinsic Parallelism
/// ==================================
/// As aforementioned in **Schedule Dependency**, the `Manager` builds a
/// directed acyclic graph for each kind system to help schedule them,
/// the `Manager` can also use this graph to build an intrinsic
/// parallelism.
///
public class Manager {
    internal let _runtime: _Runtime
    
    internal var _entities: _EntityManager
    
    internal let _components: _ComponentManager
    
    internal let _dependentSystems: _DependentSystemsManager
    
    internal let _groups: _GroupManager
    
    public init() {
        _runtime = _Runtime()
        
        _components = _ComponentManager(runtime: _runtime)
        
        _entities = _EntityManager(
            runtime: _runtime,
            componentSpace: _components
        )
        
        _groups = _GroupManager(
            runtime: _runtime,
            entityManager: _entities,
            componentManager: _components
        )
        
        _dependentSystems = _DependentSystemsManager(
            runtime: _runtime,
            entityManager: _entities,
            componentManager: _components
        )
    }
}

// MARK: Managing Life-Cycle
extension Manager {
    public func tearDown() {
        _dependentSystems.tearDown()
        _groups.tearDown()
    }
}

// MARK: Managing Entities
extension Manager {
    @discardableResult
    public func makeEntity() -> UnescapableEntityBuilder {
        let id = _entities.createPreparedEntityID()
        return UnescapableEntityBuilder(proxy: _entities, entityID: id)
    }
    
    public func removeEntity(with entityID: EntityID) -> Bool {
        return _entities.removeEntity(with: entityID)
    }
    
    public func isValidEntityID(_ entityID: EntityID) -> Bool {
        return _entities.isValidEntityID(entityID)
    }
    
    public func component<C: ManagedComponent>(forEntityWith entityID: EntityID) -> C? {
        return _entities.component(forEntityWith: entityID)
    }
    
    @discardableResult
    public func setComponent<C: ManagedComponent>(_ component: C?, forEntityWith entityID: EntityID) -> C? {
        return _entities.setComponent(component, forEntityWith: entityID)
    }
}

// MARK: Managing Unique Component
extension Manager {
    public func uniqueComponent<C>(of type: C.Type) -> C? where C: UniqueComponent {
        return _components.uniqueComponent(of: type)
    }
    
    @discardableResult
    public func setUniqueComponent<C>(_ component: C?) -> C? where C: UniqueComponent {
        return _components.setUniqueComponent(component)
    }
}

// MARK: Managing Initialize System
extension Manager {
    public var initializeSystems: Set<InitializeSystem> {
        return _dependentSystems.initialize.systems
    }
    
    @discardableResult
    public func addInitializeSystem(
        withHandler handler: @escaping InitializeHandler,
        name: String,
        isEnabled: Bool = true
        ) -> InitializeSystem
    {
        return _dependentSystems.initialize.addSystem(
            with: .init(
                name: name,
                isEnabled: isEnabled,
                handler: handler
            )
        )
    }
    
    @discardableResult
    public func removeInitializeSystem(_ system: InitializeSystem)
        -> InitializeSystem?
    {
        return _dependentSystems.initialize.removeSystem(system)
    }
}

// MARK: Managing Command Frame System
extension Manager {
    public var commandFrameSystems: Set<CommandFrameSystem> {
        return _dependentSystems.commandFrame.systems
    }
    
    @discardableResult
    public func addCommandFrameSystem(
        withHandler handler: @escaping CommandFrameHandler,
        name: String,
        isEnabled: Bool = true,
        qualityOfService: SystemQoS = .userInteractive
        ) -> CommandFrameSystem
    {
        return _dependentSystems.commandFrame.addSystem(
            with: .init(
                name: name,
                isEnabled: isEnabled,
                handler: handler,
                qualityOfService: qualityOfService
            )
        )
    }
    
    @discardableResult
    public func removeCommandFrameSystem(_ system: CommandFrameSystem)
        -> CommandFrameSystem?
    {
        return _dependentSystems.commandFrame.removeSystem(system)
    }
}

// MARK: Managing User Event System
extension Manager {
    public var userEventSystems: Set<UserEventSystem> {
        return _dependentSystems.userEvent.systems
    }
    
    @discardableResult
    public func addUserEventSystem(
        withHandler handler: @escaping UserEventHandler,
        name: String,
        isEnabled: Bool = true,
        qualityOfService: SystemQoS = .userInteractive
        ) -> UserEventSystem
    {
        return _dependentSystems.userEvent.addSystem(
            with: .init(
                name: name,
                isEnabled: isEnabled,
                handler: handler,
                qualityOfService: qualityOfService
            )
        )
    }
    
    @discardableResult
    public func removeUserEventSystem(_ system: UserEventSystem)
        -> UserEventSystem?
    {
        return _dependentSystems.userEvent.removeSystem(system)
    }
}

// MARK: Managing Reactive Systems
extension Manager {
    public var reactiveSystems: Set<ReactiveSystem> {
        return Set(groups.map({$0.reactiveSystems}).flatMap({$0}))
    }
    
    @discardableResult
    public func addReactiveSystem(
        to group: Group,
        withHandler handler: @escaping ReactiveHandler,
        name: String,
        isEnabled: Bool = true,
        events: GroupEventOptions,
        qualityOfService: SystemQoS
        ) -> ReactiveSystem
    {
        return group.addReactiveSystem(
            withHandler: handler,
            name: name,
            events: events,
            qualityOfService: qualityOfService
        )
    }
    
    @discardableResult
    public func removeReactiveSystem(
        _ system: ReactiveSystem,
        from group: Group
        ) -> ReactiveSystem?
    {
        return group.removeReactiveSystem(system)
    }
}

// MARK: Managing Groups
extension Manager {
    public var groups: [Group] {
        fatalError()
    }
    
    public func makeGroup(
        name: String,
        predicate: ComponentSlicePredicate
        ) -> Group
    {
        fatalError()
    }
    
    @discardableResult
    public func removeGroup(_ gruop: Group) -> Group? {
        fatalError()
    }
}

extension Manager {
    public func makeGroup(predicate: ComponentSlicePredicate)
        -> Group
    {
        return _groups.makeGroup(predicate: predicate)
    }
    
    public func makeGroup(predicates: ComponentSlicePredicate...)
        -> Group
    {
        return makeGroup(predicate: ComponentSlicePredicate(predicates))
    }
}

// MARK: Querying Groups
extension Manager {
    public func groups(with predicate: ComponentSlicePredicate)
        -> [Group]
    {
        fatalError()
    }
}

extension Manager {
    public func groups(with predicates: [ComponentSlicePredicate])
        -> [Group]
    {
        fatalError()
    }
    
    public func groups(with predicates: ComponentSlicePredicate...)
        -> [Group]
    {
        return groups(with: predicates)
    }
}
