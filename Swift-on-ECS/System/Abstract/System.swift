//
//  System.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/15/17.
//

// MARK: - System

/// `System` represents a system stored in `Manager`.
///
/// Reference Semantic
/// ==================
/// An instance of the type of `System` shall be a reference, which to
/// reflect the fact that
///
public protocol System: class, Hashable {
    var name: String { get set }
    
    var isEnabled: Bool { get set }
}
