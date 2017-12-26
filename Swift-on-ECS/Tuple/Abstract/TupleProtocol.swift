//
//  TupleProtocol.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/2/17.
//

public protocol TupleProtocol {
    var required: TupleRequiredMemberAccessor { get }
    var optional: TupleOptionalMemberAccessor { get }
}
