//
//  _FlexibleSystemMetadata.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/19/17.
//

internal protocol _FlexibleSystemMetadata: _VariantSystemMetadata {
    var qualityOfService: SystemQoS { get set }
}
