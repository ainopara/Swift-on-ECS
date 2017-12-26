//
//  _UserEventSystemMetadata.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/19/17.
//

import SwiftExt

internal struct _UserEventSystemMetadata: _ImplicitSystemMetadata {
    internal var name: String
    
    internal var isEnabled: Bool
    
    internal var qualityOfService: SystemQoS
    
    internal let handler: UserEventHandler
    
    internal let handlerIdentifier: FunctionIdentifier
    
    internal init(
        name: String,
        isEnabled: Bool,
        handler: @escaping Handler,
        qualityOfService: SystemQoS
        )
    {
        self.name = name
        self.isEnabled = isEnabled
        self.handler = handler
        self.qualityOfService = qualityOfService
        self.handlerIdentifier = FunctionIdentifier(handler)
    }
}
