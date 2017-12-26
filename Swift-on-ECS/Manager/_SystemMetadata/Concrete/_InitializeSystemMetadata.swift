//
//  _InitializeSystemMetadata.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/19/17.
//

import SwiftExt

internal struct _InitializeSystemMetadata: _VariantSystemMetadata {
    internal var name: String
    
    internal var isEnabled: Bool
    
    internal let handler: InitializeHandler
    
    internal let handlerIdentifier: FunctionIdentifier
    
    internal init(
        name: String,
        isEnabled: Bool,
        handler: @escaping Handler
        )
    {
        self.name = name
        self.isEnabled = isEnabled
        self.handler = handler
        self.handlerIdentifier = FunctionIdentifier(handler)
    }
}
