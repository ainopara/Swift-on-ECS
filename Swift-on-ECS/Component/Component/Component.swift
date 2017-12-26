//
//  Component.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 11/29/17.
//

// MARK: - Component
public protocol Component {
    static var signature: ComponentSignature { get }
}

extension Component {
    public static var signature: ComponentSignature {
        return ComponentSignature(self)
    }
}
