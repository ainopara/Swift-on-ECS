//
//  ManagedComponent.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 11/30/17.
//

public protocol ManagedComponent: Component, _DegeneratedManagedComponent
    where Self == Allocator.Component
{
    associatedtype Allocator: ComponentAllocator
}
