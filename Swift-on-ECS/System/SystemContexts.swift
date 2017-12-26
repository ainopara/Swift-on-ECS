//
//  SystemContexts.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/16/17.
//

public protocol SystemContext: class {
    // TODO: APIs for creating entities
    
    func component<C: ManagedComponent>(forEntityWith entityID: EntityID) -> C?
    
    @discardableResult
    func setComponent<C: ManagedComponent>(_ component: C?, forEntityWith entityID: EntityID) -> C?
    
    func uniqueComponent<C>(of type: C.Type) -> C? where C: UniqueComponent
    
    @discardableResult
    func setUniqueComponent<C>(_ component: C?) -> C? where C: UniqueComponent
    
    func tuples(with predicate: ComponentSlicePredicate) -> TupleCollection
    
    func mutableTuples(with predicate: ComponentSlicePredicate) -> MutableTupleCollection
    
    func managedComponentPool<C>(of type: C.Type) -> C.Allocator.PoolType where C: ManagedComponent
    
    func mutableManagedComponentPool<C>(of type: C.Type) -> C.Allocator.MutablePoolType where C: ManagedComponent
}

public protocol ImplicitContext: SystemContext {}

public protocol InitializeContext: SystemContext {}

public protocol CommandFrameContext: ImplicitContext {}

public protocol UserEventContext: ImplicitContext {}

public protocol ReactiveContext: SystemContext {}
