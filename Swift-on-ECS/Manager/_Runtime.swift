//
//  _Runtime.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/7/17.
//

import SwiftExt

/// `_Runtime` registered the id of the components which used
/// for generating entity's signature.
internal class _Runtime {
    internal static let shared = _Runtime()
    
    internal var _lock: UnfairLock
    internal var _indexForComponent: [ObjectIdentifier : Int]
    internal var _components: [Component.Type]
    
    internal init() {
        _lock = UnfairLock()
        _indexForComponent = [:]
        _components = []
    }
    
    @inline(__always)
    internal func _santityCheck() {
        assert(_indexForComponent.count == _components.count)
    }
    
    @discardableResult
    internal func registerComponentType(_ componentType: Component.Type) -> Int {
        return componentIndex(for: componentType)
    }
    
    @discardableResult
    internal func componentIndex(for componentType: Component.Type) -> Int {
        return _lock.waitToAcquireAndPerform {
            _santityCheck(); defer { _santityCheck() }
            
            let key = ObjectIdentifier(componentType)
            if let index = _indexForComponent[key] {
                return index
            } else {
                let index = _components.endIndex
                _components.append(componentType)
                _indexForComponent[key] = index
                return index
            }
        }
    }
    
    internal func componentType(at index: Int) -> Component.Type {
        return _lock.waitToAcquireAndPerform {
            _santityCheck()
            precondition(index < _components.count, "Invalid component-id: \(index)")
            return _components[index]
        }
    }
}

extension _Runtime {
    /// Registers a component to the shared `ComponentCenter`.
    ///
    @discardableResult
    internal static func componentIndex(for componentType: Component.Type) -> Int {
        return shared.componentIndex(for: componentType)
    }
    
    /// Gets a component type for the `index` if the component was
    /// registered in shared `ComponentCenter`.
    ///
    internal static func componentType(at index: Int) -> Component.Type {
        return shared.componentType(at: index)
    }
}
