//
//  _DependentSystemPool.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/13/17.
//

import SwiftExt

/// `_DependentSystemPool` pools metadata of a kind of systems.
///
/// Computational Complexity
/// ========================
/// The system metadata can be modified or queried at any time either
/// frequently, any operation except searching shall be O(1).
/// ```
/// +------------+-----------+---------+-----------+--------------------+
/// | Operation  | Insertion | Removal | Searching | Setting Dependency |
/// +------------+-----------+---------+-----------+--------------------+
/// | Complexity | O(1)      | O(1)    | O(n)      | O(1)               |
/// +------------+-----------+---------+-----------+--------------------+
/// ```
///
/// As a Sequence
/// =============
/// The pool can be used as of type of `Sequence` to iterate the index and
/// metadata of the stored systems.
///
/// Spatial Locality
/// ================
/// Since system's metadata is merely changed after it got setup, and most
/// of the time, the pool is used for scheduling systems, it shall keep a
/// good locality with systems' metadatas.
///
/// Data Layout
/// ===========
/// ```
/// +----------------------+
/// | _DependentSystemPool |
/// |  ^                   |
/// +--|-------------------+
///    |
///    |
/// +--|--------------------------------------------------------+
/// | _systems                                                  |
/// | +---------------+ +---------------+ +---------------+     |
/// | | System        | | System        | | System        |     |
/// | | +-----------+ | | +-----------+ | | +-----------+ |     |
/// | | | requires  | | | | requires  | | | | requires  | |     |
/// | | +-----------+ | | +-----------+ | | +-----------+ |     |
/// | | | required  | | | | required  | | | | required  | | ... |
/// | | +-----------+ | | +-----------+ | | +-----------+ |     |
/// | | | metadata  | | | | metadata  | | | | metadata  | |     |
/// | | +-----------+ | | +-----------+ | | +-----------+ |     |
/// | |  ^            | |  ^            | |  ^            |     |
/// | +--|------------+ +--|------------+ +--|------------+     |
/// +----|-----------------|-----------------|------------------+
///      |                 |                 |
/// +----|--------+   +----|--------+   +----|--------+
/// | SystemOwner |   | SystemOwner |   | SystemOwner |
/// +-------------+   +-------------+   +-------------+
/// ```
///
/// Stages of System's Life-Cycle
/// =============================
/// Technically, a system is allocated by the pool. Thus its life-cycle
/// shall also be managed by the pool. But since the pool's callee-side
/// returns a wrapper object when adding a system, and this object can be
/// captured by users, it requires that this object to hold the system's
/// life-cycle instead of the pool. Thus, there is four stages in a
/// system's life-cycle.
///
/// ```
///                         Managed by owner
///           +-----------------------------------------+
///           |                                         |
///           |                                         |
///     +-----------+    +------+    +--------+    +----------+
/// +-> | Allocated | -> | Used | -> | Unused | -> | Recycled | -+
/// |   +-----------+    +------+    +--------+    +----------+  |
/// +------------------------------------------------------------+
/// ```
///
/// - Allocation:
/// Allocates a piece of memory which is contiguous to the previous
/// allocated systems in the system's container. And returns the owner of
/// the system.
///
/// - Using:
/// The system is allocated to be being used if the callee-side retains
/// the owner returned by the stage.
///
/// - Unusing:
/// Unuses the system, removes it from the pool's iteration. Since there
/// might be multiple user codes retained the owner at the same time, the
/// recycling might not happened immediately.
///
/// - Recycling:
/// Recycles the system, takes the allocated memory into the reuse pool.
/// This is caused by the `deinit` phase of the owner object.
///
/// Thread Safety
/// =============
/// Since the pool can be iterated and atomic iteration is very difficult
/// to support at callee-side(the pool itself) but easy to support at
/// caller-side, this class is not thread safe.
///
/// Handling Duplicate
/// ==================
/// Systems with their metadata having the same hash value are allowed.
/// But since the metadata is `Equatable`, equal metadata would be
/// considered as a duplicate.
///
/// When inserting a system with duplicate metadata, you always gets the
/// owner of the system metadata which previously inserted.
///
/// Feature Improvement
/// ===================
/// A poolical editor might need to filter the system dependency pool
/// by names. So there shall be a post-fixed tree or AC automaton to help
/// with it.
///
internal class _DependentSystemPool<M: _VariantSystemMetadata> {
    internal typealias Metadata = M
    
    internal typealias Handler = Metadata.Handler
    
    internal typealias System = _DependentSystemBucket<Metadata>
    
    internal typealias SystemOwner = _DependentSystemOwner<Metadata>
    
    internal var _systems: [System]
    
    internal var _indicesForMetadataHash: [Int : Set<Int>]
    
    internal var _unusedIndices: Set<Int>
    
    internal var _unusedOwners: Set<Unowned<SystemOwner>>
    
    /// Indices reusable in total.
    internal var _reusableIndices: Set<Int>
    
    /// Active transaction count.
    ///
    /// - Note:
    /// This is how a system pool typically participate in a transaction:
    /// ```
    /// +----------------------------------------------------------------+
    /// | _DependentSystemManager                                        |
    /// | |                 |                  |                 |       |
    /// +-|-----------------|------------------|-----------------|-------+
    ///   |init             |Transaction Begin |Transaction End  |deinit
    ///   |                 |                  |                 |
    ///   |                 |                  |                 |
    ///   |                 |                  |                 |
    ///   |beginTransaction |endTransaction    |beginTransaction |endTransaction
    /// +-|-----------------|------------------|-----------------|-------+
    /// | ˅                 ˅                  ˅                 ˅       |
    /// | _DependentSystemPool                                           |
    /// +----------------------------------------------------------------+
    /// ```
    internal var _activeTransactionCount: Int
    
    internal var _needsSort: Bool
    
    internal init() {
        _systems = []
        _indicesForMetadataHash = [:]
        _unusedIndices = []
        _unusedOwners = []
        _reusableIndices = []
        _activeTransactionCount = 0
        _needsSort = false
    }
    
    deinit {
        for index in _systems.indices {
            _systems[index].prepareForStorageDeallocation()
        }
    }
}

// MARK: Update
extension _DependentSystemPool {
    /// Begins a transaction.
    ///
    internal func beginTransaction() {
        _activeTransactionCount += 1
    }
    
    internal var isInTransaction: Bool {
        return _activeTransactionCount != 0
    }
    
    /// Ends a transaction.
    ///
    internal func endTransaction() {
        _activeTransactionCount -= 1
        if _activeTransactionCount == 0 { _commit() }
    }
    
    /// Commits the transation.
    ///
    internal func _commit() {
        _updateDependenciesIfNeeded()
        _sortIfNeeded()
    }
    
    internal func _updateDependenciesIfNeeded() {
        if !_unusedOwners.isEmpty {
            
            for systemIndex in _systems.indices {
                _systems[systemIndex].required.subtract(_unusedOwners)
                _systems[systemIndex].requires.subtract(_unusedOwners)
            }
            
            _unusedOwners.removeAll()
        }
    }
    
    internal func _setNeedsSort() { _needsSort = true }
    
    internal func _sortIfNeeded() {
        if _needsSort {
            _sort()
        }
        assert(!_needsSort)
    }
    
    internal func _sort() {
        
        // Getting root indices
        var rootIndices = [Int]()
        
        for index in _systems.indices {
            if _systems[index].state == .valid {
                // When a system requires no system, it is a root system.
                if _systems[index].requires.isEmpty {
                    rootIndices.append(index)
                }
            }
        }
        
        // Setting system's order
        var order = 0
        var rawDependencyIdentifier: UInt = 0
        var processedIndices = Set<Int>()
        
        for rootIndex in rootIndices {
            // Per-root-per-denpendency-identifeir
            let dependencyIdentifier = _SystemDependencyIdentifier(
                rawValue: rawDependencyIdentifier
            )
            
            // Breadth-first iterate dependency
            var unprocessedIndices = [rootIndex]
            while !unprocessedIndices.isEmpty {
                let nextIndex = unprocessedIndices.removeFirst()
                
                guard !processedIndices.contains(nextIndex) else {
                    // A system might be required by multiple systems.
                    continue
                }
                
                _systems[nextIndex].order = order
                _systems[nextIndex].dependencyID = dependencyIdentifier
                
                order += 1
                processedIndices.insert(nextIndex)
                unprocessedIndices.append(
                    contentsOf: _systems[nextIndex].required.map({$0.value.index})
                )
            }
            
            rawDependencyIdentifier += 1
        }
        
        // Sort
        _systems.sort { (s1, s2) -> Bool in
            switch (s1.state, s2.state) {
            case (.valid, .valid):
                return s1.order < s2.order
            case (.valid, .unused), (.valid, .recycled):
                return true
            case (.unused, .valid), (.recycled, .valid):
                return false
            default:
                return s1.order < s2.order
            }
        }
        
        // Update owner's index
        for index in _systems.indices {
            if _systems[index].hasOwner {
                _systems[index].owner.index = index
            }
        }
        
        _needsSort = false
    }
}

// MARK: Utilities
extension _DependentSystemPool {
    /// Dequeues a reusable index. Returns `_systems.endIndex` if no
    /// reusable indices exist.
    ///
    @_transparent
    internal func _dequeueReusableIndex() -> Int {
        if _reusableIndices.isEmpty {
            return _systems.endIndex
        } else {
            return _reusableIndices.removeFirst()
        }
    }
    
    @_transparent
    internal func _assertValidIndex(_ index: Int) {
        if _systems[index].state == .unused {
            fatalError("Unused system at: \(index)")
        }
        
        if _systems[index].state == .recycled {
            fatalError("Recycled system at: \(index)")
        }
    }
}

// MARK: System Level Abstraction
extension _DependentSystemPool {
    internal func insertSystem(with metadata: Metadata) -> SystemOwner {
        // Check redundant
        let metadataHash = metadata.hashValue
        if let existed = _indicesForMetadataHash[metadataHash] {
            if let index = existed.map({_systems[$0].metadata})
                .index(of: metadata)
            {
                return _systems[index].owner
            }
        }
        
        let index = _dequeueReusableIndex()
        
        let owner = SystemOwner(pool: self, index: index)
        
        let system = System(owner: owner, metadata: metadata)
        _systems.insert(system, at: index)
        
        if var existed = _indicesForMetadataHash[metadataHash] {
            existed.insert(index)
            _indicesForMetadataHash[metadataHash] = existed
        } else {
            _indicesForMetadataHash[metadataHash] = [index]
        }
        
        _setNeedsSort()
        
        return owner
    }
    
    internal func unuseSystem(at index: Int) {
        precondition(_systems[index].state == .valid, "Invalid unusing.")
        let owner = _systems[index].owner
        _systems[index].state = .unused
        _unusedOwners.insert(Unowned(owner))
        _unusedIndices.insert(index)
        _setNeedsSort()
    }
    
    internal func _removeSystem(at index: Int) {
        precondition(
            _systems[index].state != .recycled,
            "Invalid removal."
        )
        _systems[index].state = .recycled
        _unusedIndices.remove(index)
        _reusableIndices.insert(index)
    }
    
    internal var isEmpty: Bool {
        return _systems.count
            - _unusedIndices.count
            - _reusableIndices.count == 0
    }
}

extension _DependentSystemPool {
    internal func name(forSystemAt index: Int) -> String {
        _assertValidIndex(index)
        return _systems[index].metadata.name
    }
    
    internal func setName(_ name: String, forSystemAt index: Int) {
        _assertValidIndex(index)
        _systems[index].metadata.name = name
    }
    
    internal func isEnabled(forSystemAt index: Int) -> Bool {
        _assertValidIndex(index)
        return _systems[index].metadata.isEnabled
    }
    
    internal func setEnabled(_ enabled: Bool, forSystemAt index: Int) {
        _assertValidIndex(index)
        _systems[index].metadata.isEnabled = enabled
    }
    
    internal func handler(forSystemAt index: Int) -> Handler {
        _assertValidIndex(index)
        return _systems[index].metadata.handler
    }
    
    internal func handlerIdentifier(forSystemAt index: Int)
        -> FunctionIdentifier
    {
        _assertValidIndex(index)
        return _systems[index].metadata.handlerIdentifier
    }
    
    internal func indicesForSystemsRequiring(systemAt index: Int)
        -> Set<Int>
    {
        _assertValidIndex(index)
        _updateDependenciesIfNeeded()
        return Set(_systems[index].required.map({$0.value.index}))
    }
    
    internal func setSystem(
        at index: Int,
        requiresSystemAt requiredSystemIndex: Int
        )
    {
        _assertValidIndex(index)
        _systems[index].requires.insert(Unowned(_systems[requiredSystemIndex].owner))
        _systems[requiredSystemIndex].required.insert(Unowned(_systems[index].owner))
        _setNeedsSort()
    }
    
    internal func setSystem(
        at index: Int,
        doesNotRequireSystemAt requiredSystemIndex: Int
        )
    {
        _assertValidIndex(index)
        _systems[index].requires.remove(Unowned(_systems[requiredSystemIndex].owner))
        _systems[requiredSystemIndex].required.remove(Unowned(_systems[index].owner))
        _setNeedsSort()
    }
    
    internal func indicesForSystemsRequired(bySystemAt index: Int)
        -> Set<Int>
    {
        _assertValidIndex(index)
        _updateDependenciesIfNeeded()
        return Set(_systems[index].requires.map({$0.value.index}))
    }
    
    internal func setSystem(
        at index: Int,
        isRequiredBySystemAt requiringSystemIndex: Int
        )
    {
        _assertValidIndex(index)
        _systems[requiringSystemIndex].requires.insert(Unowned(_systems[index].owner))
        _systems[index].required.insert(Unowned(_systems[requiringSystemIndex].owner))
        _setNeedsSort()
    }
    
    internal func setSystem(
        at index: Int,
        isNotRequiredBySystemAt requiringSystemIndex: Int
        )
    {
        _assertValidIndex(index)
        _systems[requiringSystemIndex].requires.remove(Unowned(_systems[index].owner))
        _systems[index].required.remove(Unowned(_systems[requiringSystemIndex].owner))
        _setNeedsSort()
    }
}

extension _DependentSystemPool where M: _FlexibleSystemMetadata {
    internal func qualityOfServiceForSystem(at index: Int) -> SystemQoS {
        _assertValidIndex(index)
        return _systems[index].metadata.qualityOfService
    }
    
    internal func setSystem(at index: Int, qualityOfService: SystemQoS) {
        _assertValidIndex(index)
        _systems[index].metadata.qualityOfService = qualityOfService
    }
}

extension _DependentSystemPool where M == _ReactiveSystemMetadata {
    internal func eventsForSystem(at index: Int) -> GroupEventOptions {
        _assertValidIndex(index)
        return _systems[index].metadata.events
    }
    
    internal func setSystem(at index: Int, events: GroupEventOptions) {
        _assertValidIndex(index)
        _systems[index].metadata.events = events
    }
}

// MARK: Sequence
extension _DependentSystemPool: Sequence {
    internal typealias Iterator = _DependentSystemIterator<Metadata>
    
    internal func makeIterator() -> Iterator { return .init(pool: self) }
}

// MARK: - _DependentSystemIterator
internal struct _DependentSystemIterator<M: _VariantSystemMetadata>:
    IteratorProtocol
{
    internal typealias Metadata = M
    
    internal typealias Element = (
        dependencyID: _SystemDependencyIdentifier,
        metadata: Metadata
    )
    
    internal let pool: _DependentSystemPool<Metadata>
    
    internal var index: Int = 0
    
    internal init(pool: _DependentSystemPool<Metadata>) {
        self.pool = pool
    }
    
    internal mutating func next() -> Element? {
        var nextIndex = index
        if nextIndex < pool._systems.endIndex {
            
            while pool._systems[nextIndex].isInvalid {
                nextIndex += 1
                
                if nextIndex >= pool._systems.endIndex {
                    return nil
                }
            }
            
            let element = pool._systems[nextIndex]
            
            index = nextIndex + 1
            
            return (element.dependencyID, element.metadata)
        }
        return nil
    }
}

// MARK: - _ImplicitSystemIterator

// MARK: - _DependentSystemBucket
internal enum _DependentSystemBucketState: UInt8 {
    case valid
    case unused
    case recycled
}

/// `_DependentSystemBucket` is the base of contiguous allocation for
/// `_DependentSystemPool`.
///
internal struct _DependentSystemBucket<M: _VariantSystemMetadata> {
    internal typealias Metadata = M
    
    internal typealias Owner = _DependentSystemOwner<Metadata>
    
    internal typealias State = _DependentSystemBucketState
    
    internal var state: State
    
    @_transparent
    internal var isInvalid: Bool { return state != .valid }
    
    @_transparent
    internal var hasOwner: Bool { return state != .recycled }
    
    /// The owner to the system.
    ///
    /// - Note:
    /// A `_DependentSystemPool` instance is just a storage, it doesn't
    /// manage the life-cycle of the system stored in it. The `owner`
    /// shall be retained by caller-side code.
    ///
    internal unowned let owner: Owner
    
    internal var requires: Set<Unowned<Owner>>
    
    internal var required: Set<Unowned<Owner>>
    
    internal var order: Int
    
    internal var dependencyID: _SystemDependencyIdentifier
    
    internal var metadata: Metadata
    
    internal init(owner: Owner, metadata: Metadata) {
        self.state = .valid
        self.owner = owner
        self.requires = Set()
        self.required = Set()
        self.metadata = metadata
        self.order = 0
        self.dependencyID = _SystemDependencyIdentifier(rawValue: 0)
    }
    
    internal func prepareForStorageDeallocation() {
        if hasOwner {
            owner.isPoolDeallocated = true
        }
    }
}

// MARK: - _DependentSystemOwner
/// `_DependentSystemOwner` owns a piece of memory which is allocated by
/// the `_DependentSystemPool`. It holds the memory until it get released.
///
internal class _DependentSystemOwner<M: _VariantSystemMetadata> {
    internal typealias Metadata = M
    
    internal typealias Pool = _DependentSystemPool<Metadata>
    
    /// The pool stores system system.
    ///
    /// - Note:
    /// Since the system shall exist when the owner exist, holding a
    /// strong relationship to the pool seems to be a neccessary. But
    /// since the wapper object holds a strong relationship to the owner
    /// and the pool, the `pool` here can be `unowned`.
    /// ```
    /// +-------------------+
    /// | DependentSystem <------------------------------------+
    /// | ^                 |                                  | strong
    /// +-|-----------------+                                  |
    ///   | strong                                             |
    ///   |                                                    |
    /// +-|-----------------------+                            |
    /// | _DependentSystemManager |                            |
    /// | ^                       |                            |
    /// +-|-----------------------+                            |
    ///   | strong                                             |
    ///   |                                                    |
    /// +-|--------------------+ unowned +---------------------|-+
    /// | _DependentSystemPool------------>_DependentSystemOwner |
    /// |                      | unowned |                       |
    /// |                     <------------                      |
    /// +----------------------+         +-----------------------+
    /// ```
    ///
    internal unowned let pool: Pool
    
    /// Indicates that the pool is being deallocated.
    internal var isPoolDeallocated: Bool
    
    internal var index: Int
    
    internal init(pool: Pool, index: Int) {
        self.pool = pool
        self.index = index
        isPoolDeallocated = false
    }
    
    deinit {
        if !isPoolDeallocated {
            // Recycle the owned system from the pool before deinit.
            pool._removeSystem(at: index)
        }
    }
}

extension _DependentSystemOwner: Equatable {
    internal static func == (
        lhs: _DependentSystemOwner,
        rhs: _DependentSystemOwner
        ) -> Bool
    {
        return lhs === rhs
    }
}

extension _DependentSystemOwner: Hashable {
    internal var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

// MARK: - _SystemDependencyIdentifier
internal struct _SystemDependencyIdentifier: RawRepresentable {
    internal typealias RawValue = UInt
    internal var rawValue: UInt
    internal init(rawValue: RawValue) { self.rawValue = rawValue }
}

extension _SystemDependencyIdentifier: Equatable {
    internal static func == (
        lhs: _SystemDependencyIdentifier,
        rhs: _SystemDependencyIdentifier
        ) -> Bool
    {
        return lhs.rawValue == rhs.rawValue
    }
}

extension _SystemDependencyIdentifier: Hashable {
    internal var hashValue: Int { return rawValue.hashValue }
}
