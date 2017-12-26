//
//  _TupleMemberAccessing.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/2/17.
//

internal protocol _TupleMemberAccessing {
    var _core: _TupleCore { get }
}

extension _TupleMemberAccessing {
    internal func _warnComponentWasNotPredicated(_ componentType: Component.Type) -> Never {
        // FIXME: Write a description
        fatalError()
    }
}
