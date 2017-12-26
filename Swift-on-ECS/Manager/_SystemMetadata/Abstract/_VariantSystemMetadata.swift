//
//  _VariantSystemMetadata.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/17/17.
//

import SwiftExt

/// `_VariantSystemMetadata` represents the metadata of a system.
///
internal protocol _VariantSystemMetadata: Hashable {
    associatedtype Handler
    
    var name: String { get set }
    
    var isEnabled: Bool { get set }
    
    var handler: Handler { get }
    
    var handlerIdentifier: FunctionIdentifier { get }
}

extension _VariantSystemMetadata {
    internal static func == (lhs: Self, rhs: Self) -> Bool {
        return lhs.handlerIdentifier == rhs.handlerIdentifier
    }
    
    internal var hashValue: Int { return handlerIdentifier.hashValue }
}
