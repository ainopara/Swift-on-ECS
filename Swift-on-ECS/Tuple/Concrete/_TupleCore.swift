//
//  _TupleCore.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/5/17.
//

// MARK: - _TupleSignature
internal struct _TupleSignature: Equatable {
    internal let requiredComponentsSignatures: ComponentSignatureSet
    internal let optionalComponentsSignatures: ComponentSignatureSet
    
    internal static func == (lhs: _TupleSignature, rhs: _TupleSignature) -> Bool {
        return lhs.requiredComponentsSignatures == rhs.requiredComponentsSignatures
            && lhs.optionalComponentsSignatures == rhs.optionalComponentsSignatures
    }
    
    internal func isCompatible(with signature: _TupleSignature) -> Bool {
        fatalError()
    }
}

// MARK: - _TupleCore
internal struct _TupleCore {
    internal let _variantCore: _VariantTupleCore
    
    internal init(signature: _TupleSignature, manager: Manager, entityID: EntityID) {
        _variantCore = .init(signature: signature, manager: manager, entityID: entityID)
    }
    
    internal init(observationCache: _TupleObservationCache, entityID: EntityID) {
        _variantCore = .init(observationCache: observationCache, entityID: entityID)
    }
    
    internal subscript<C: ManagedComponent>(_ componentType: C.Type) -> C? {
        get { return _variantCore[componentType] }
        nonmutating set { _variantCore[componentType] = newValue }
    }
    
    internal subscript<C: UniqueComponent>(_ componentType: C.Type) -> C? {
        get { return _variantCore[componentType] }
        nonmutating set { _variantCore[componentType] = newValue }
    }
}

// MARK: - _VariantTupleCore
internal enum _VariantTupleCore {
    case computed(_RealtimeTupleCore)
    case stored(_ObservedTupleCore)
    
    internal init(signature: _TupleSignature, manager: Manager, entityID: EntityID) {
        self = .computed(.init(signature: signature, manager: manager, entityID: entityID))
    }
    
    internal init(observationCache: _TupleObservationCache, entityID: EntityID) {
        self = .stored(.init(observationCache: observationCache, entityID: entityID))
    }
    
    internal subscript<C: ManagedComponent>(_ componentType: C.Type) -> C? {
        get {
            switch self {
            case let .computed(core):   return core[componentType]
            case let .stored(core):     return core[componentType]
            }
        }
        nonmutating set {
            switch self {
            case let .computed(core):   core[componentType] = newValue
            case let .stored(core):     core[componentType] = newValue
            }
        }
    }
    
    internal subscript<C: UniqueComponent>(_ componentType: C.Type) -> C? {
        get {
            switch self {
            case let .computed(core):   return core[componentType]
            case let .stored(core):     return core[componentType]
            }
        }
        nonmutating set {
            switch self {
            case let .computed(core):   core[componentType] = newValue
            case let .stored(core):     core[componentType] = newValue
            }
        }
    }
}

// MARK: - _ComputedTupleCore
internal struct _RealtimeTupleCore {
    internal let _signature: _TupleSignature
    internal unowned let _manager: Manager
    internal let _entityID: EntityID
    
    internal init(signature: _TupleSignature, manager: Manager, entityID: EntityID) {
        _signature = signature
        _manager = manager
        _entityID = entityID
    }
    
    internal subscript<C: ManagedComponent>(_ componentType: C.Type) -> C? {
        get { return _manager.component(forEntityWith: _entityID) }
        nonmutating set { _manager.setComponent(newValue, forEntityWith: _entityID) }
    }
    
    internal subscript<C: UniqueComponent>(_ componentType: C.Type) -> C? {
        get { return _manager.uniqueComponent(of: componentType) }
        nonmutating set { _manager.setUniqueComponent(newValue) }
    }
}

// MARK: - _ObservedTupleCore
internal struct _ObservedTupleCore {
    internal let _owner: UnsafePointer<_ObservedTupleOwner>
    
    internal init(observationCache: _TupleObservationCache, entityID: EntityID) {
        _owner = observationCache._observedTupleOwner(forEntityWith: entityID)
    }
    
    internal subscript<C: ManagedComponent>(_ componentType: C.Type) -> C? {
        get { return _owner[0][componentType] }
        nonmutating set { _owner[0][componentType] = newValue }
    }
    
    internal subscript<C: UniqueComponent>(_ componentType: C.Type) -> C? {
        get { fatalError() }
        nonmutating set { fatalError() }
    }
}

// MARK: - _PooledTuple
internal struct _ObservedTupleOwner {
    internal subscript<C: ManagedComponent>(_ componentType: C.Type) -> C? {
        get { fatalError() }
        nonmutating set { fatalError() }
    }
}

// MARK: - _TupleObservationCache
internal class _TupleObservationCache {
    internal var _tupleOffsetForEntityID: [EntityID: Int]
    
    internal var _buffer: UnsafeMutableRawPointer
    
    internal init(signature: _TupleSignature) {
        _tupleOffsetForEntityID = [:]
        _buffer = _TuplePool(mallocWith: signature)
    }
    
    deinit { _TuplePool(free: _buffer) }
    
    internal var _signature: _TupleSignature {
        return _TuplePoolGetSignature(_buffer)
    }
    
    internal func cache(_ entity: Entity) {
        let entityID = entity.id
        if let offset = _tupleOffsetForEntityID[entityID] {
            _TuplePool(_buffer, setTupleWith: entity, at: offset)
        } else {
            let offset = _TuplePool(_buffer, addTupleWith: entity)
            _tupleOffsetForEntityID[entityID] = offset
        }
    }
    
    internal func uncache(_ entity: Entity) {
        if let offset = _tupleOffsetForEntityID[entity.id] {
            _TuplePool(_buffer, removeTupleAt: offset)
        }
    }
    
    internal func _observedTupleOwner(forEntityWith entityID: EntityID) -> UnsafePointer<_ObservedTupleOwner> {
        fatalError()
    }
}

// MARK: - _TuplePool

/// Tuple Pool
///
/// Pool Layout
/// ===========
/// The tuple-pool is actually a heap allocated memory space like the
/// following C-struct.
///
/// ```
/// struct TuplePool {
///     Int tupleSize;
///     Int alignedTupleSize;
///
///     Int usedCount;
///     Int maxCount;
///
///     Int witnessCount;
///     Int witnessHashLoadFactor;
///     _TupleWitness witnessTable[...];
///
///     _Tuple tuples[...];
/// }
/// ```
///
/// Pool Alignment
/// ==============
/// Since the target to build a tuple-pool is to offer a high speed, good-
/// locality access pattern, it is necessary to align each tuple to be
/// integral times of the word-size.
///
/// Tuple Layout
/// ============
/// The tuple is a contiguous sequence of bool-component pair. `false`
/// `bool` value means the paired component is `nil`.
///
/// ```
/// struct Tuple {
///
///     Bool hasComponent1;
///
///     Component1 component1;
///
///     ...optional padding...
///
///     Bool hasComponent2;
///
///     Component2 component2;
///
///     ...optional padding...
///
/// }
/// ```
///

// MARK: _TupleWitness
internal struct _TupleWitness {
    /// Component signature
    internal let signature: ComponentSignature
    
    /// Preceeding content offset
    internal let preceedingOffset: Int
    
    /// Component's size with the signature
    internal let sizeWithNullability: Int
}

// MARK: Public
internal func _TuplePool(mallocWith tupleSignature: _TupleSignature) -> UnsafeMutableRawPointer {
    return __TuplePool(mallocWith: tupleSignature, capacityIncrementFactor: 1.3)
}

internal func _TuplePool(free pointer: UnsafeMutableRawPointer) {
    fatalError()
}

internal func _TuplePoolGetSignature(_ pointer: UnsafeMutableRawPointer) -> _TupleSignature {
    fatalError()
}

internal func _TuplePool(_ pointer: UnsafeMutableRawPointer, addTupleWith entity: Entity) -> Int {
    fatalError()
}

internal func _TuplePool(_ pointer: UnsafeMutableRawPointer, setTupleWith entity: Entity, at offset: Int) {
    fatalError()
}

internal func _TuplePool(_ pointer: UnsafeMutableRawPointer, removeTupleAt offset: Int) {
    fatalError()
}

internal func _TuplePool<C: ManagedComponent>(_ pointer: UnsafeMutableRawPointer, getComponentAt offset: Int) -> C? {
    fatalError()
}

internal func _TuplePool<C: ManagedComponent>(_ pointer: UnsafeMutableRawPointer, setComponent component: C?, at offset: Int) -> C? {
    fatalError()
}

// MARK: Private
internal func __TuplePool(mallocWith tupleSignature: _TupleSignature, capacityIncrementFactor: Float) -> UnsafeMutableRawPointer {
    fatalError()
}

internal func __TuplePoolGetCount(_ pointer: UnsafeMutableRawPointer) -> Int {
    fatalError()
}

internal func __TuplePoolGetMaxCount(_ pointer: UnsafeMutableRawPointer) -> Int {
    fatalError()
}

internal func __TuplePoolIncreaseCapacity(_ pointer: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
    fatalError()
}
