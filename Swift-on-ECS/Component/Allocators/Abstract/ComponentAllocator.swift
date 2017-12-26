//
//  ComponentAllocator.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 11/30/17.
//

public protocol ComponentAllocator where
    PoolType.Element == (EntityID, Component),
    PoolType.Index == ComponentAddress,
    MutablePoolType.Element == (EntityID, Component),
    MutablePoolType.Index == ComponentAddress
{
    associatedtype Component
    
    associatedtype PoolType: Collection
    
    associatedtype MutablePoolType: MutableCollection
    
    static func allocateComponent(_ component: Component, with entityID: EntityID, in space: ComponentSpace) -> ComponentAddress
    
    @discardableResult
    static func deallocateComponent(at address: ComponentAddress, in space: ComponentSpace) -> (entityID: EntityID, component: Component)
    
    static func entityID(at address: ComponentAddress, in space: ComponentSpace) -> EntityID
    
    static func component(at address: ComponentAddress, in space: ComponentSpace) -> Component
    
    static func setComponent(_ component: Component, at address: ComponentAddress, in space: ComponentSpace)
    
    static func pool(in space: ComponentSpace) -> PoolType
    
    static func mutablePool(in space: ComponentSpace) -> MutablePoolType
}
