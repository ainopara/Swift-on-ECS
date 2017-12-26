//
//  MutableTupleProtocol.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/2/17.
//

public protocol MutableTupleProtocol {
    var required: TupleRequiredMemberAccessor { get nonmutating set }
    var optional: TupleOptionalMemberAccessor { get nonmutating set }
}
