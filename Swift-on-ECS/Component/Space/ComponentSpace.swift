//
//  ComponentSpace.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 11/29/17.
//

/// `ComponentSpace` offers fundamental infrustracture to manage
/// components.
///
public protocol ComponentSpace: class {
    func componentContext<C: ComponentContext>() -> C?
    
    func addComponentContext<C: ComponentContext>(_ context: C)
    
    func removeComponentContext<C: ComponentContext>(_ context: C) -> C?
}
