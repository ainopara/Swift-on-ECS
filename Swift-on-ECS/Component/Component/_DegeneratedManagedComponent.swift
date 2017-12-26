//
//  _DegeneratedManagedComponent.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/5/17.
//

public protocol _DegeneratedManagedComponent {
    static var _deallocator: _DegeneratedManagedComponentDeallcator { get }
}


extension _DegeneratedManagedComponent where Self: ManagedComponent {
    public static var _deallocator: _DegeneratedManagedComponentDeallcator {
        return _DegeneratedManagedComponentDeallcator(Allocator.self)
    }
}

public class _DegeneratedManagedComponentDeallcator {
    internal let _deallocateComponent: (ComponentAddress, ComponentSpace) -> Void
    
    internal init<A: ComponentAllocator>(_ allocator: A.Type) {
        _deallocateComponent = { (a, s) in _ = allocator._deallocateComponent(at: a, in: s)}
    }
}

extension ComponentAllocator {
    internal static func _deallocateComponent(at address: ComponentAddress, in space: ComponentSpace) {
        _ = deallocateComponent(at: address, in: space)
    }
}
