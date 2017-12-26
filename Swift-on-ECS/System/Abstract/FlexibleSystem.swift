//
//  FlexibleSystem.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/12/17.
//

/// `FlexibleSystem` can be scheduled by the `Manager` flexibly by
/// offering wanted quality-of-service.
///
public protocol FlexibleSystem: System {
    var qualityOfService: SystemQoS { get set }
}

