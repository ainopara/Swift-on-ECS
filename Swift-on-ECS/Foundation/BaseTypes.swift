//
//  BaseTypes.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/1/17.
//

// MARK: - TimeInterval
public typealias TimeInterval = Double

// MARK: - EntityID
public struct EntityID {
    internal var _value: Int
    
    internal init(_ value: Int) {
        _value = value
    }
}

extension EntityID: Equatable {
    public static func ==(lhs: EntityID, rhs: EntityID) -> Bool {
        return lhs._value == rhs._value
    }
}

extension EntityID: Hashable {
    public var hashValue: Int { return _value.hashValue }
}

// MARK: - _EntityComposing
/// `_EntityComposing` offers a chained callable API for entity composing
///
internal protocol _EntityComposing: class {
    func component<C: ManagedComponent>(forEntityWith entityID: EntityID) -> C?
    
    @discardableResult
    func setComponent<C: ManagedComponent>(_ component: C?, forEntityWith entityID: EntityID) -> C?
}

// MARK: - UnescapableEntityBuilder
/// `UnescapableEntityBuilder` offers a chained callable API for entity
/// composing.
///
/// - Note:
/// This value is unescapable because it maintains a weak relation with
/// the entity pool. Any compose action happened in the escaped context
/// doesn't have any work.
///
/// Since users can use a `Unmanaged` struct to make a class reference
/// escaped without retaining the reference, we wraps the proxy with a
/// struct to make the escaping always keeps a weak relationship to the
/// proxy.
///
public struct UnescapableEntityBuilder {
    internal weak var _proxy: _EntityComposing?
    
    internal let _entityID_: EntityID
    
    public var id: EntityID { return _entityID_ }
    
    internal init(
        proxy: _EntityComposing,
        entityID: EntityID
        )
    {
        _proxy = proxy
        _entityID_ = entityID
    }
    
    @discardableResult
    public func with<C>(component: C) -> UnescapableEntityBuilder where C: ManagedComponent {
        if let proxy = _proxy {
            proxy.setComponent(component, forEntityWith: _entityID_)
        }
        
        return self
    }
    
    public var entityID: EntityID { return _entityID_ }
}


// MARK: - ComponentContext
/// `ComponentContext` defines the basic requirements for component
/// pooling.
///
public protocol ComponentContext: class {}

// MARK: - ComponentSignature

/// `ComponentSignature` identifies different kinds of components in a
/// collection of components.
///
public struct ComponentSignature {
    internal var _objectIdentifier: ObjectIdentifier
    
    internal init(_ type: Component.Type) {
        _objectIdentifier = ObjectIdentifier(type)
    }
    
    @_transparent
    internal func _toOpaquePointer() -> UnsafeRawPointer? {
        return UnsafeRawPointer(bitPattern: _objectIdentifier.hashValue)
    }
    
    @_transparent
    internal func _toComponentType() -> Component.Type? {
        if let ptr = _toOpaquePointer() {
            let componentTypePtr = ptr.bindMemory(to: Component.Type.self, capacity: 1)
            return componentTypePtr[0]
        }
        return nil
    }
    
    @_transparent
    internal var _aseertingGetDeneratedManagedComponentDeallocator: _DegeneratedManagedComponentDeallcator? {
        if let ptr = _toOpaquePointer() {
            let componentTypePtr = ptr.bindMemory(to: _DegeneratedManagedComponent.Type.self, capacity: 1)
            return componentTypePtr[0]._deallocator
        }
        return nil
    }
}

extension ComponentSignature: Equatable {
    public static func == (lhs: ComponentSignature, rhs: ComponentSignature) -> Bool {
        return lhs._objectIdentifier == rhs._objectIdentifier
    }
}

extension ComponentSignature: Hashable {
    public var hashValue: Int { return _objectIdentifier.hashValue }
}

extension ComponentSignature: Comparable {
    public static func < (lhs: ComponentSignature, rhs: ComponentSignature) -> Bool {
        return lhs._objectIdentifier < rhs._objectIdentifier
    }
}

// MARK: - ComponentSignatureSet

/// `ComponentSignatureSet` helps predicates collections of components.
///
public struct ComponentSignatureSet {
    public typealias Element = ComponentSignature
    
    internal var _signatures: Set<ComponentSignature>
    
    internal init (signatures: Set<ComponentSignature>) {
        _signatures = signatures
    }
}

extension ComponentSignatureSet {
    public init<S: Sequence>(components: S) where S.Element == Component.Type {
        _signatures = Set(components.map({$0.signature}))
    }
    
    public init(components: Component.Type...) {
        _signatures = Set(components.map({$0.signature}))
    }
}

extension ComponentSignatureSet: SetAlgebra {
    public init () {
        _signatures = []
    }
    
    public init<S: Sequence>(_ signatures: S) where S.Element == ComponentSignature {
        _signatures = Set(signatures)
    }
    
    public func contains(_ member: ComponentSignature) -> Bool {
        return _signatures.contains(member)
    }
    
    public func union(_ other: ComponentSignatureSet) -> ComponentSignatureSet {
        return .init(signatures: _signatures.union(other._signatures))
    }
    
    public func intersection(_ other: ComponentSignatureSet) -> ComponentSignatureSet {
        return .init(signatures: _signatures.intersection(other._signatures))
    }
    
    public func symmetricDifference(_ other: ComponentSignatureSet) -> ComponentSignatureSet {
        return .init(signatures: _signatures.symmetricDifference(other._signatures))
    }
    
    @discardableResult
    public mutating func insert(_ newMember: ComponentSignature) -> (inserted: Bool, memberAfterInsert: ComponentSignature) {
        return _signatures.insert(newMember)
    }
    
    @discardableResult
    public mutating func remove(_ member: ComponentSignature) -> ComponentSignature? {
        return _signatures.remove(member)
    }
    
    @discardableResult
    public mutating func update(with newMember: ComponentSignature) -> ComponentSignature? {
        return _signatures.update(with: newMember)
    }
    
    public mutating func formUnion(_ other: ComponentSignatureSet) {
        _signatures.formUnion(other._signatures)
    }
    
    public mutating func formIntersection(_ other: ComponentSignatureSet) {
        _signatures.formIntersection(other._signatures)
    }
    
    public mutating func formSymmetricDifference(_ other: ComponentSignatureSet) {
        _signatures.formSymmetricDifference(other._signatures)
    }
}

extension ComponentSignatureSet: Equatable {
    public static func == (lhs: ComponentSignatureSet, rhs: ComponentSignatureSet) -> Bool {
        if lhs._signatures.count == rhs._signatures.count {
            return lhs._signatures == rhs._signatures
        } else {
            return false
        }
    }
}

extension ComponentSignatureSet: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Component.Type
    
    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(elements.map({$0.signature}))
    }
}

// MARK: - ComponentAddress
public struct ComponentAddress: RawRepresentable {
    public typealias RawValue = Int
    public var rawValue: RawValue
    
    public init(rawValue: RawValue) { self.rawValue = rawValue }
}

extension ComponentAddress: Equatable {
    public static func ==(lhs: ComponentAddress, rhs: ComponentAddress) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
}

extension ComponentAddress: Hashable {
    public var hashValue: Int { return rawValue }
}

extension ComponentAddress: Comparable {
    public static func <(lhs: ComponentAddress, rhs: ComponentAddress) -> Bool {
        return lhs.rawValue < rhs.rawValue
    }
}

// MARK: - ComponentSlicePredicate
public struct ComponentSlicePredicate {
    internal let _storage: _ComponentSlicePredicateStorage
    
    public func requires(_ signature: ComponentSignature) -> Bool {
        return _storage.requires(signature)
    }
    
    public func allows(_ signature: ComponentSignature) -> Bool {
        return _storage.allows(signature)
    }
    
    public func excludes(_ signature: ComponentSignature) -> Bool {
        return _storage.excludes(signature)
    }
    
    public init(allOf required: ComponentSignatureSet) {
        _storage = .init(allOf: required, anyOf: [], noneOf: [])
    }
    
    public init(anyOf optional: ComponentSignatureSet) {
        _storage = .init(allOf: [], anyOf: optional, noneOf: [])
    }
    
    public init(noneOf excluded: ComponentSignatureSet) {
        _storage = .init(allOf: [], anyOf: [], noneOf: excluded)
    }
    
    public init(
        allOf required: ComponentSignatureSet,
        anyOf optional: ComponentSignatureSet
        )
    {
        _storage = .init(allOf: required, anyOf: optional, noneOf: [])
    }
    
    public init(
        anyOf optional: ComponentSignatureSet,
        noneOf excluded: ComponentSignatureSet
        )
    {
        _storage = .init(allOf: [], anyOf: optional, noneOf: excluded)
    }
    
    public init(
        allOf required: ComponentSignatureSet,
        noneOf excluded: ComponentSignatureSet
        )
    {
        _storage = .init(allOf: required, anyOf: [], noneOf: excluded)
    }
    
    public init(
        allOf required: ComponentSignatureSet,
        anyOf optional: ComponentSignatureSet,
        noneOf excluded: ComponentSignatureSet
        )
    {
        _storage = .init(allOf: required, anyOf: optional, noneOf: excluded)
    }
    
    public init<S: Sequence>(_ sequenceOfPredicate: S) where
        S.Element == ComponentSlicePredicate
    {
        _storage = .init(storages: sequenceOfPredicate.map({$0._storage}))
    }
}

extension ComponentSlicePredicate: Equatable {
    public static func == (
        lhs: ComponentSlicePredicate,
        rhs: ComponentSlicePredicate
        ) -> Bool
    {
        return lhs._storage == rhs._storage
    }
}

extension ComponentSlicePredicate: Hashable {
    public var hashValue: Int {
        return _storage.hashValue
    }
}

extension ComponentSlicePredicate: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = ComponentSlicePredicate
    
    public init(arrayLiteral elements: ArrayLiteralElement...) {
        self.init(elements)
    }
}

internal class _ComponentSlicePredicateStorage {
    internal let required: ComponentSignatureSet
    
    internal let optional: ComponentSignatureSet
    
    internal let excluded: ComponentSignatureSet
    
    internal var identifier: String {
        if _identifier_ == nil {
            _identifier_ =
            """
            required: \(required._signatures.sorted());
            optional: \(optional._signatures.sorted());
            excluded: \(excluded._signatures.sorted())
            """
        }
        return _identifier_
    }
    
    internal var _identifier_: String!
    
    internal init(storages: [_ComponentSlicePredicateStorage]) {
        var required: ComponentSignatureSet = []
        var optional: ComponentSignatureSet = []
        var excluded: ComponentSignatureSet = []
        for each in storages {
            required.formUnion(each.required)
            optional.formUnion(each.optional)
            excluded.formUnion(each.excluded)
        }
        self.required = required
        self.optional = optional
        self.excluded = excluded
    }
    
    internal init(
        allOf required: ComponentSignatureSet,
        anyOf optional: ComponentSignatureSet,
        noneOf excluded: ComponentSignatureSet
        )
    {
        self.required = required
        self.optional = optional
        self.excluded = excluded
    }
    
    internal func predicates(_ entity: Entity) -> Bool {
        for signature in required._signatures {
            if entity.contains(componentOf: signature) == false {
                return false
            }
        }
        
        for signature in excluded._signatures {
            if entity.contains(componentOf: signature) == true {
                return false
            }
        }
        
        guard !optional.isEmpty else { return true }
        
        for signature in optional._signatures {
            if entity.contains(componentOf: signature) == true {
                return true
            }
        }
        
        return false
    }
    
    internal func requires(_ signature: ComponentSignature) -> Bool {
        return required.contains(signature)
    }
    
    internal func allows(_ signature: ComponentSignature) -> Bool {
        return required.contains(signature) || optional.contains(signature)
    }
    
    internal func excludes(_ signature: ComponentSignature) -> Bool {
        return excluded.contains(signature)
    }
}

extension _ComponentSlicePredicateStorage: Equatable {
    internal static func == (lhs: _ComponentSlicePredicateStorage, rhs: _ComponentSlicePredicateStorage) -> Bool {
        return lhs.identifier == rhs.identifier
    }
}

extension _ComponentSlicePredicateStorage: Hashable {
    internal var hashValue: Int {
        return identifier.hashValue
    }
}

// MARK: - GroupEventOptions
public struct GroupEventOptions: OptionSet {
    public typealias RawValue = UInt8
    public let rawValue: RawValue
    public init(rawValue : RawValue) { self.rawValue = rawValue }
    
    public static let add       = GroupEventOptions(rawValue:1 << 0)
    public static let update    = GroupEventOptions(rawValue:1 << 1)
    public static let remove    = GroupEventOptions(rawValue:1 << 2)
    
    public static let all       = [add, update, remove] as GroupEventOptions
    public static let `default` = all
}

// MARK: - GroupEvent
public enum GroupEvent: UInt8 {
    case add
    case update
    case remove
}

// MARK: - SystemQoS
/// `SystemQoS` represents a quality-of-service for a system.
///
/// You can specify a quality-of-service to each system to help with the
/// intrinsic parallelism. Specially, the `.userInteractive` quality-of-
/// service forces the system to be scheduled on the main thread.
///
public enum SystemQoS: UInt8, Hashable, CustomDebugStringConvertible {
    case userInteractive
    case userInitiated
    case utility
    case background
    
    public var hashValue: Int { return rawValue.hashValue }
    
    public static func == (lhs: SystemQoS, rhs: SystemQoS) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    
    public var debugDescription: String {
        switch self {
        case .userInteractive:  return "User Interactive"
        case .userInitiated:    return "User Initiated"
        case .utility:          return "Utility"
        case .background:       return "Background"
        }
    }
}

// MARK: - _LogSubsystem
internal struct _LogSubsystem: RawRepresentable {
    internal typealias RawValue = String
    internal var rawValue: RawValue
    internal init(rawValue: RawValue) { self.rawValue = rawValue }
    
    internal static let `default` = _LogSubsystem(rawValue: "")
}

// MARK: - _LogCategory
internal struct _LogCategory: RawRepresentable {
    internal typealias RawValue = String
    internal var rawValue: RawValue
    internal init(rawValue: RawValue) { self.rawValue = rawValue }
    
    internal static let `default` = _LogCategory(rawValue: "")
}
