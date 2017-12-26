//
//  _ComponentManager.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/6/17.
//

internal class _ComponentManager {
    internal unowned let runtime: _Runtime
    
    internal var _uniqueComponentOwners: UnorderedMap<ComponentSignature, AnyObject>
    
    internal var _componentContexts: UnorderedMap<ObjectIdentifier, ComponentContext>
    
    internal init(runtime: _Runtime) {
        self.runtime = runtime
        _uniqueComponentOwners = [:]
        _componentContexts = [:]
    }
}

// MARK: Querying Managed Component
extension _ComponentManager {
    internal func managedComponentPool<C>(of type: C.Type) -> C.Allocator.PoolType where C: ManagedComponent {
        return C.Allocator.pool(in: self)
    }
    
    internal func mutableManagedComponentPool<C>(of type: C.Type) -> C.Allocator.MutablePoolType where C: ManagedComponent {
        return C.Allocator.mutablePool(in: self)
    }
}

// MARK: - Managing Unique Component
extension _ComponentManager {
    internal func uniqueComponent<C>(of type: C.Type) -> C? where C: UniqueComponent {
        return _uniqueComponentOwner(of: C.self).component
    }
    
    internal func setUniqueComponent<C>(_ component: C?) -> C? where C: UniqueComponent {
        runtime.registerComponentType(C.self)
        let owner = _uniqueComponentOwner(of: C.self)
        let oldComponent = owner.component
        _uniqueComponentOwner(of: C.self).component = component
        return oldComponent
    }
    
    internal func _uniqueComponentOwner<C>(of type: C.Type) -> _UniqueComponentOwner<C> where C: UniqueComponent {
        let signature = C.signature
        if let owner = _uniqueComponentOwners[signature] {
            return unsafeBitCast(owner, to: _UniqueComponentOwner<C>.self)
        } else {
            let owner = _UniqueComponentOwner<C>()
            _uniqueComponentOwners[signature] = owner
            return owner
        }
    }
}

extension _ComponentManager: ComponentSpace {
    internal func componentContext<C: ComponentContext>() -> C? {
        let key = ObjectIdentifier(C.self)
        if let context = _componentContexts[key] {
            return unsafeBitCast(context, to: C.self)
        }
        return nil
    }
    
    internal func addComponentContext<C: ComponentContext>(_ context: C) {
        let key = ObjectIdentifier(C.self)
        _componentContexts[key] = context
    }
    
    internal func removeComponentContext<C: ComponentContext>(_ context: C) -> C? {
        let key = ObjectIdentifier(C.self)
        if let context = _componentContexts[key] {
            _componentContexts[key] = nil
            return unsafeBitCast(context, to: C.self)
        }
        return nil
    }
}

internal final class _UniqueComponentOwner<C: UniqueComponent> {
    internal typealias Component = C
    
    internal var component: Component?
    
    internal init() { }
}
