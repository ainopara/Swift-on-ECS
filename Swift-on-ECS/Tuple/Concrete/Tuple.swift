//
//  Tuple.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/1/17.
//

public struct Tuple: TupleProtocol {
    internal let _core: _TupleCore
    
    internal init(signature: _TupleSignature, manager: Manager, entityID: EntityID) {
        _core = .init(signature: signature, manager: manager, entityID: entityID)
    }
    
    internal init(observationCache: _TupleObservationCache, entityID: EntityID) {
        _core = .init(observationCache: observationCache, entityID: entityID)
    }
    
    public var required: TupleRequiredMemberAccessor {
        return .init(core: _core)
    }
    
    public var optional: TupleOptionalMemberAccessor {
        return .init(core: _core)
    }
}
