//
//  _EntityManager.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/6/17.
//

import SwiftExt

internal struct _Entity {
    internal var entitySignature: BitString
    
    internal var components: [ComponentSignature : ComponentAddress]
    
    internal var isValid: Bool { return _isValid_ }
    
    internal mutating func invalidate() {
        if _isValid_ {
            _isValid_ = false
        }
    }
    
    internal init() {
        entitySignature = BitString()
        _isValid_ = true
        components = [:]
    }
    
    internal var _isValid_: Bool
}

internal class _EntityManager {
    internal unowned let runtime: _Runtime
    
    internal unowned let componentSpace: ComponentSpace
    
    internal var _reusableEntityIDs: Set<EntityID>
    
    // Currently a very naïve contiguous array implementation. The
    // capacity increment strategy needs discussion.
    internal var _entities: [_Entity]
    
    internal init(runtime: _Runtime, componentSpace: ComponentSpace) {
        self.runtime = runtime
        self.componentSpace = componentSpace
        _reusableEntityIDs = []
        _entities = []
    }
    
    internal func createPreparedEntityID() -> EntityID {
        let entityID = _dequeueReusableEntityID()
        if entityID._value >= _entities.endIndex {
            _entities.insert(_Entity(), at: entityID._value)
        }
        return entityID
    }
    
    internal func removeEntity(with entityID: EntityID) -> Bool {
        if _entities[entityID._value].isValid {
            for (signature, address) in _entities[entityID._value].components {
                if let deallocator = signature._aseertingGetDeneratedManagedComponentDeallocator {
                    deallocator._deallocateComponent(address, componentSpace)
                }
            }
            _entities[entityID._value].invalidate()
            _reusableEntityIDs.insert(entityID)
            return true
        }
        return false
    }
    
    internal func isValidEntityID(_ entityID: EntityID) -> Bool {
        return entityID._value >= 0
            && entityID._value < _entities.endIndex
            && !_reusableEntityIDs.contains(entityID)
    }
    
    internal func signature(forEntityWith entityID: EntityID) -> BitString {
        return _entities[entityID._value].entitySignature
    }
}

extension _EntityManager {
    @inline(__always)
    internal func _dequeueReusableEntityID() -> EntityID {
        if _reusableEntityIDs.isEmpty {
            let first = _reusableEntityIDs.removeFirst()
            return first
        }
        return EntityID(_entities.endIndex)
    }
}

extension _EntityManager {
    internal func willSetComponent<C>(_ component: C?, forEntityWith entityID: EntityID) where C : ManagedComponent {
        
    }
    
    internal func didSetComponent<C>(_ component: C?, forEntityWith entityID: EntityID) where C : ManagedComponent {
        
    }
}

extension _EntityManager: _EntityComposing {
    internal func component<C>(forEntityWith entityID: EntityID) -> C? where C : ManagedComponent {
        let key = C.signature
        if let address = _entities[entityID._value].components[key] {
            return C.Allocator.component(at: address, in: componentSpace)
        } else {
            return nil
        }
    }
    
    internal func setComponent<C>(_ component: C?, forEntityWith entityID: EntityID) -> C? where C : ManagedComponent {
        typealias ComponentAllocator = C.Allocator
        let index = runtime.componentIndex(for: C.self)
        let signature = C.signature
        if let component = component {
            if let address = _entities[entityID._value].components[signature] {
                // Setting non-nil with non-nil
                let old = C.Allocator.component(at: address, in: componentSpace)
                willSetComponent(component, forEntityWith: entityID)
                C.Allocator.setComponent(component, at: address, in: componentSpace)
                didSetComponent(component, forEntityWith: entityID)
                return old
            } else {
                // Setting non-nil with nil
                willSetComponent(component, forEntityWith: entityID)
                let address = ComponentAllocator.allocateComponent(component, with: entityID, in: componentSpace)
                _entities[entityID._value].components[signature] = address
                _entities[entityID._value].entitySignature[index] = true
                didSetComponent(component, forEntityWith: entityID)
                return nil
            }
        } else {
            if let address = _entities[entityID._value].components[signature] {
                // Setting nil with non-nil
                willSetComponent(component, forEntityWith: entityID)
                let oldValue = ComponentAllocator.deallocateComponent(at: address, in: componentSpace)
                _entities[entityID._value].components[signature] = nil
                _entities[entityID._value].entitySignature[index] = false
                didSetComponent(component, forEntityWith: entityID)
                return oldValue.component
            } else {
                // Setting nil with nil
                return nil
            }
        }
    }
}
