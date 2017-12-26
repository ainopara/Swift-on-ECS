//
//  TupleRequiredMemberAccessor.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/2/17.
//

public struct TupleRequiredMemberAccessor: _TupleMemberAccessing {
    internal var _core: _TupleCore
    
    internal init(core: _TupleCore) { _core = core }
    
    public subscript<C: ManagedComponent>(componentType: C.Type) -> C {
        get {
            if let c = _core[componentType] {
                return c
            } else {
                _warnComponentWasNotPredicated(componentType)
            }
        }
        set { _core[componentType] = newValue }
    }
    
    public subscript<C: UniqueComponent>(componentType: C.Type) -> C {
        get {
            if let c = _core[componentType] {
                return c
            } else {
                _warnComponentWasNotPredicated(componentType)
            }
        }
        set { _core[componentType] = newValue }
    }
}
