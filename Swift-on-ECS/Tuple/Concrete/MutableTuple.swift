//
//  MutableTuple.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/1/17.
//

public struct MutableTuple: MutableTupleProtocol {
    internal let _core: _TupleCore
    
    internal init(signature: _TupleSignature, manager: Manager, entityID: EntityID) {
        _core = .init(signature: signature, manager: manager, entityID: entityID)
    }
    
    internal init(observationCache: _TupleObservationCache, entityID: EntityID) {
        _core = .init(observationCache: observationCache, entityID: entityID)
    }
    
    public var required: TupleRequiredMemberAccessor {
        get { return .init(core: _core) }
        nonmutating set { }
    }
    
    public var optional: TupleOptionalMemberAccessor {
        get { return .init(core: _core) }
        nonmutating set { }
    }
}
