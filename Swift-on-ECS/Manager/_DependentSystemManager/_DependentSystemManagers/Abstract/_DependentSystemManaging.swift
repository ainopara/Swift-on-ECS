//
//  _DependentSystemManaging.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/17/17.
//

/// Internal promise for `DependentSystem`.
///
/// - Note:
/// Why this type is placed in this file?
///
/// Good question. Go and ask fucking Swift compiler. The fucking compiler
/// crashes fuckingly if this fucking type is not in the fucking same file
/// to `_DependentSystemManaging`.
///
/// https://bugs.swift.org/browse/SR-6649
///
internal protocol _DependentSystem: DependentSystem where
    _Manager.System == Self
{
    associatedtype _Manager: _DependentSystemManaging
    
    associatedtype _Metadata: _VariantSystemMetadata
    
    var _owner: _DependentSystemOwner<_Metadata> { get }
    
    var _index: Int { get }
    
    var _manager: _Manager { get }
    
    init(owner: _DependentSystemOwner<_Metadata>, manager: _Manager)
}

extension _DependentSystem {
    @_transparent
    var _index: Int { return _owner.index }
}

/// `_DependentSystemManaging` defines a prototype for managing variant
/// kinds of systems.
///
/// Naming Convention
/// =================
/// All members with a name begins with "\_"(underscore) is not
/// synchronized. All memebers with a name begins without "\_" is
/// synchronized.
///
internal protocol _DependentSystemManaging: class where
    System._Manager == Self
{
    associatedtype System: _DependentSystem
    
    associatedtype Dispatcher: _DependentSystemDispatching
    
    var _entityManager: _EntityManager { get }
    
    var _componentManager: _ComponentManager { get }
    
    var _dispatchers: [_SystemDependencyIdentifier : Dispatcher]
        { get set }
    
    var _systems: [Int : System] { get set }
    
    /// A pool stored systems info.
    var _systemPool: _DependentSystemPool<System._Metadata> { get }
    
    /// Synchronizes acccessing in closure.
    func _sync<R>(using closure: () -> R) -> R
    
    func _dispatcher(for id: _SystemDependencyIdentifier) -> Dispatcher
    
    /// Tears the system manager down.
    func tearDown()
    
    var systems: Set<System> { get }
    
    func addSystem(with metadata: System._Metadata) -> System
    
    @discardableResult
    func removeSystem(_ system: System) -> System?
    
    func name(forSystem system: System) -> String
    
    func setName(_ name: String, forSystem system: System)
    
    func isEnabled(forSystem system: System) -> Bool
    
    func setEnabled(_ enabled: Bool, forSystem system: System)
    
    func systems(requiringSystem system: System) -> Set<System>
    
    func systems(requiredBySystem system: System) -> Set<System>
    
    func setSystem(
        _ system: System,
        requiresSystem requiredSystem: System
    )
    
    func setSystem(
        _ system: System,
        doesNotRequireSystem requiredSystem: System
    )
    
    func setSystem(
        _ system1: System,
        isRequiredBySystem requiringSystem: System
    )
    
    func setSystem(
        _ system1: System,
        isNotRequiredBySystem requiringSystem: System
    )
}

extension _DependentSystemManaging {
    internal func _dispatcher(for identifier: _SystemDependencyIdentifier)
        -> Dispatcher
    {
        if let dispatcher = _dispatchers[identifier] {
            return dispatcher
        } else {
            let dispatcher = Dispatcher()
            _dispatchers[identifier] = dispatcher
            return dispatcher
        }
    }
}

extension _DependentSystemManaging {
    /// Managed systems.
    internal var systems: Set<System> {
        return _sync { Set(_systems.values) }
    }
    
    internal func addSystem(with metadata: System._Metadata) -> System {
        return _sync {
            let owner = _systemPool.insertSystem(with: metadata)
            let index = owner.index
            if let system  = _systems[index] {
                return system
            } else {
                let system = System(owner: owner, manager: self)
                _systems[index] = system
                return system
            }
        }
    }
    
    @discardableResult
    internal func removeSystem(_ system: System) -> System? {
        precondition(system._manager === self)
        return _sync {
            let index = system._index
            if let system = _systems.removeValue(forKey: index) {
                _systemPool.unuseSystem(at: index)
                return system
            }
            return nil
        }
    }
    
    internal func name(forSystem system: System) -> String {
        precondition(system._manager === self)
        return _sync { _systemPool.name(forSystemAt: system._index) }
    }
    
    internal func setName(_ name: String, forSystem system: System) {
        precondition(system._manager === self)
        _sync { _systemPool.setName(name, forSystemAt: system._index) }
    }
    
    internal func isEnabled(forSystem system: System) -> Bool {
        precondition(system._manager === self)
        return _sync { _systemPool.isEnabled(forSystemAt: system._index) }
    }
    
    internal func setEnabled(_ enabled: Bool, forSystem system: System) {
        return _sync {
            precondition(system._manager === self)
            _systemPool.setEnabled(enabled, forSystemAt: system._index)
        }
    }
}

extension _DependentSystemManaging {
    internal func systems(requiringSystem system: System) -> Set<System> {
        precondition(system._manager === self)
        return _sync {
            let index = system._index
            let indices = _systemPool.indicesForSystemsRequiring(
                systemAt: index
            )
            let filtered = _systems.filter({indices.contains($0.key)})
            return Set(filtered.values)
        }
    }
    
    internal func systems(requiredBySystem system: System)
        -> Set<System>
    {
        precondition(system._manager === self)
        return _sync {
            let index = system._index
            let indices = _systemPool.indicesForSystemsRequired(
                bySystemAt: index
            )
            let filtered = _systems.filter({indices.contains($0.key)})
            return Set(filtered.values)
        }
    }
    
    internal func setSystem(
        _ system: System,
        requiresSystem requiredSystem: System
        )
    {
        precondition(system._manager === self)
        precondition(requiredSystem._manager === self)
        return _sync {
            _systemPool.setSystem(
                at: system._index,
                requiresSystemAt: requiredSystem._index
            )
        }
    }
    
    internal func setSystem(
        _ system: System,
        doesNotRequireSystem requiredSystem: System
        )
    {
        precondition(system._manager === self)
        precondition(requiredSystem._manager === self)
        return _sync {
            _systemPool.setSystem(
                at: system._index,
                doesNotRequireSystemAt: requiredSystem._index
            )
        }
    }
    
    internal func setSystem(
        _ system: System,
        isRequiredBySystem requiringSystem: System
        )
    {
        precondition(system._manager === self)
        precondition(requiringSystem._manager === self)
        return _sync {
            _systemPool.setSystem(
                at: system._index,
                isRequiredBySystemAt: requiringSystem._index
            )
        }
    }
    
    internal func setSystem(
        _ system: System,
        isNotRequiredBySystem requiringSystem: System
        )
    {
        precondition(system._manager === self)
        precondition(requiringSystem._manager === self)
        return _sync {
            _systemPool.setSystem(
                at: system._index,
                isNotRequiredBySystemAt: requiringSystem._index
            )
        }
    }
}


extension _DependentSystemManaging where Self: SystemContext  {
    internal func component<C>(forEntityWith entityID: EntityID) -> C? where C : ManagedComponent {
        return _entityManager.component(forEntityWith: entityID)
    }
    
    internal func setComponent<C>(_ component: C?, forEntityWith entityID: EntityID) -> C? where C : ManagedComponent {
        return _entityManager.setComponent(component, forEntityWith: entityID)
    }
    
    internal func uniqueComponent<C>(of type: C.Type) -> C? where C : UniqueComponent {
        return _componentManager.uniqueComponent(of: type)
    }
    
    internal func setUniqueComponent<C>(_ component: C?) -> C? where C : UniqueComponent {
        return _componentManager.setUniqueComponent(component)
    }
    
    internal func tuples(with predicate: ComponentSlicePredicate) -> TupleCollection {
        _unimplemented()
    }
    
    internal func mutableTuples(with predicate: ComponentSlicePredicate) -> MutableTupleCollection {
        _unimplemented()
    }
    
    internal func managedComponentPool<C>(of type: C.Type) -> C.Allocator.PoolType where C : ManagedComponent {
        _unimplemented()
    }
    
    internal func mutableManagedComponentPool<C>(of type: C.Type) -> C.Allocator.MutablePoolType where C : ManagedComponent {
        _unimplemented()
    }
}
