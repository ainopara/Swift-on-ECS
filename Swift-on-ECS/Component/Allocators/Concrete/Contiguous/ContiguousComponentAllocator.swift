//
//  ContiguousComponentAllocator.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 11/29/17.
//

public struct ContiguousComponentAllocator<C: ManagedComponent>: ComponentAllocator {
    public typealias Component = C
    
    public typealias PoolType = ContiguousComponentPool<C>
    
    public typealias MutablePoolType = MutableContiguousComponentPool<C>
    
    public static func allocateComponent(_ component: Component, with entityID: EntityID, in space: ComponentSpace) -> ComponentAddress {
        return _context(in: space).allocateCopmponent(component, with: entityID)
    }
    
    @discardableResult
    public static func deallocateComponent(at address: ComponentAddress, in space: ComponentSpace) -> (entityID: EntityID, component: Component) {
        return _context(in: space).deallocateCopmponent(at: address)
    }
    
    public static func entityID(at address: ComponentAddress, in space: ComponentSpace) -> EntityID {
        return _context(in: space).entity(at: address)
    }
    
    public static func component(at address: ComponentAddress, in space: ComponentSpace) -> Component {
        return _context(in: space).component(at: address)
    }
    
    public static func setComponent(_ component: Component, at address: ComponentAddress, in space: ComponentSpace) {
        return _context(in: space).setComponent(component, at: address)
    }
    
    public static func pool(in space: ComponentSpace) -> PoolType {
        return PoolType(context: _context(in: space))
    }
    
    public static func mutablePool(in space: ComponentSpace) -> MutablePoolType {
        return MutablePoolType(context: _context(in: space))
    }
    
    @_transparent
    internal static func _context(in space: ComponentSpace) -> _ContiguousComponentPool<C> {
        if let context: _ContiguousComponentPool<C> = space.componentContext() {
            return context
        } else {
            let context = _ContiguousComponentPool<C>()
            space.addComponentContext(context)
            return context
        }
    }
}

internal final class _ContiguousComponentPool<C>:
    ComponentContext
{
    internal typealias Component = C
    
    internal struct _Bucket {
        internal var entity: EntityID
        
        internal var component: Component
        
        internal func toTuple() -> (EntityID, Component) {
            return (entity, component)
        }
    }
    
    internal var _buckets: [_Bucket]
    
    internal var _unusedIndices: OrderedSet<Int>
    
    internal init() {
        _buckets = []
        _unusedIndices = []
    }
    
    internal var startAddress: ComponentAddress {
        return ComponentAddress(rawValue: _buckets.startIndex)
    }
    
    internal var endAddress: ComponentAddress {
        return ComponentAddress(rawValue: _buckets.endIndex)
    }
    
    internal var componentCount: ComponentAddress {
        return ComponentAddress(rawValue: _buckets.count - _unusedIndices.count)
    }
    
    internal func address(after address: ComponentAddress) -> ComponentAddress {
        var nextIndex = ComponentAddress(rawValue: address.rawValue + 1)
        while _unusedIndices.contains(nextIndex.rawValue) {
            nextIndex = ComponentAddress(rawValue: address.rawValue + 1)
        }
        return nextIndex
    }
    
    internal func allocateCopmponent(_ component: Component, with entityID: EntityID) -> ComponentAddress {
        if let anyReusableIndex = _unusedIndices.first {
            _unusedIndices.remove(anyReusableIndex)
            _buckets[anyReusableIndex].component = component
            _buckets[anyReusableIndex].entity = entityID
            return ComponentAddress(rawValue: anyReusableIndex)
        } else {
            let index = _buckets.endIndex
            _buckets.append(_Bucket(entity: entityID, component: component))
            return ComponentAddress(rawValue: index)
        }
    }
    
    internal func deallocateCopmponent(at address: ComponentAddress) -> (entityID: EntityID, component: Component) {
        precondition(address.rawValue < _buckets.endIndex)
        let idx = address.rawValue
        _unusedIndices.insert(idx)
        return _buckets[idx].toTuple()
    }
    
    internal func entity(at address: ComponentAddress) -> EntityID {
        precondition(address.rawValue < _buckets.endIndex)
        let idx = address.rawValue
        return _buckets[idx].entity
    }
    
    internal func component(at address: ComponentAddress) -> Component {
        return _buckets[address.rawValue].component
    }
    
    internal func setComponent(_ component: Component, at address: ComponentAddress) {
        _buckets[address.rawValue].component = component
    }
    
    internal func withComponent<R>(at address: ComponentAddress, using closure: (Component) -> R) -> R {
        return closure(_buckets[address.rawValue].component)
    }
    
    internal func withMutableComponent<R>(at address: ComponentAddress, using closure: (inout Component) -> R) -> R {
        return closure(&_buckets[address.rawValue].component)
    }
}
