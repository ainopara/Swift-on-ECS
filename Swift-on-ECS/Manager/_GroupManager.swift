//
//  _GroupManager.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/13/17.
//

internal class _GroupManager {
    internal unowned let runtime: _Runtime
    
    internal unowned let entityManager: _EntityManager
    
    internal unowned let componentManager: _ComponentManager
    
    internal init(
        runtime: _Runtime,
        entityManager: _EntityManager,
        componentManager: _ComponentManager
        )
    {
        self.runtime = runtime
        self.entityManager = entityManager
        self.componentManager = componentManager
    }
    
    func tearDown() {
        
    }
}

extension _GroupManager {
    internal func makeGroup(predicate: ComponentSlicePredicate)
        -> Group
    {
        fatalError()
    }
}

// MARK: Querying Tuples
extension _GroupManager {
    internal func tuples(with predicate: ComponentSlicePredicate)
        -> TupleCollection
    {
        fatalError()
    }
    
    internal func mutableTuples(with predicate: ComponentSlicePredicate)
        -> MutableTupleCollection
    {
        fatalError()
    }
}

internal protocol _TupleObserver {
    func _entity<C>(forEntityID entityID: EntityID, willSetComponent component: C?) where C : ManagedComponent
    func _entity<C>(forEntityID entityID: EntityID, didSetComponent component: C?) where C : ManagedComponent
}
