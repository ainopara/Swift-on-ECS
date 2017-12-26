//
//  ContiguousComponentCollection.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 11/30/17.
//

public struct ContiguousComponentPool<C: ManagedComponent>:
    Collection
{
    public typealias Component = C
    
    public typealias Index = ComponentAddress
    
    public typealias Element = (EntityID, Component)
    
    public var startIndex: ComponentAddress {
        return _context.startAddress
    }
    
    public var endIndex: ComponentAddress {
        return _context.endAddress
    }
    
    public var count: ComponentAddress {
        return _context.componentCount
    }
    
    public subscript(index: Index) -> Element {
        return (_context.entity(at: index), _context.component(at: index))
    }
    
    public func index(after i: Index) -> Index {
        return _context.address(after: i)
    }
    
    internal let _context: _ContiguousComponentPool<C>
    
    internal init(context: _ContiguousComponentPool<C>) {
        _context = context
    }
}
