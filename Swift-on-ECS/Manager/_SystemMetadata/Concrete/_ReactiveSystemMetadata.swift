//
//  _ReactiveSystemMetadata.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/19/17.
//

import SwiftExt

internal struct _ReactiveSystemMetadata: _FlexibleSystemMetadata {
    internal var name: String
    
    internal var isEnabled: Bool
    
    internal var qualityOfService: SystemQoS
    
    internal var events: GroupEventOptions
    
    internal let handler: ReactiveHandler
    
    internal let handlerIdentifier: FunctionIdentifier
    
    internal init(
        name: String,
        isEnabled: Bool,
        handler: @escaping Handler,
        events: GroupEventOptions,
        qualityOfService: SystemQoS
        )
    {
        self.name = name
        self.isEnabled = isEnabled
        self.handler = handler
        self.events = events
        self.qualityOfService = qualityOfService
        self.handlerIdentifier = FunctionIdentifier(handler)
    }
}
