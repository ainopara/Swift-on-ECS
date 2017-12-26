//
//  Operators.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/13/17.
//

/// All of
prefix operator ∀

/// Any of
prefix operator ∈

/// None of
prefix operator ∉

/// Union
infix operator ∪

/// Intersect
infix operator ∩

/// Make a component slice predicate which predicates all of the
/// `components`.
public prefix func ∀ (components: [Component.Type])
    -> ComponentSlicePredicate
{
    return .init(allOf: .init(components: components))
}

/// Make a component slice predicate which predicates any of the
/// `components`.
public prefix func ∈ (components: [Component.Type])
    -> ComponentSlicePredicate
{
    return .init(anyOf: .init(components: components))
}

/// Make a component slice predicate which predicates none of the
/// `components`.
public prefix func ∉ (components: [Component.Type])
    -> ComponentSlicePredicate
{
    return .init(noneOf: .init(components: components))
}

public func ∪ (lhs: ComponentSlicePredicate, rhs: ComponentSlicePredicate)
    -> ComponentSlicePredicate
{
    fatalError()
}

public func ∩ (lhs: ComponentSlicePredicate, rhs: ComponentSlicePredicate)
    -> ComponentSlicePredicate
{
    fatalError()
}

