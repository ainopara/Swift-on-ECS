//
//  Entity.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 11/29/17.
//

/// `Entity`
///
open class Entity {
    public let id: EntityID
    
    internal unowned let _space: ComponentSpace
    
    internal var _components: UnorderedMap<ComponentSignature, ComponentAddress>
    
    internal var _signatures: ComponentSignatureSet
    
    internal init(space: ComponentSpace, id: EntityID) {
        self.id = id
        _space = space
        _components = [:]
        _signatures = []
    }
    
    deinit {
        for (signature, address) in _components {
            _deallocateComponent(with: signature, at: address)
        }
    }
    
    internal func _deallocateComponent(with signature: ComponentSignature, at address: ComponentAddress) {
        if let ptr = UnsafeRawPointer(bitPattern: signature._objectIdentifier.hashValue) {
            let componentTypePtr = ptr.bindMemory(to: _DegeneratedManagedComponent.Type.self, capacity: 1)
            componentTypePtr[0]._deallocator._deallocateComponent(address, _space)
        }
    }
    
    public func contains<C: ManagedComponent>(componentOf type: C.Type) -> Bool {
        return _signatures.contains(type.signature)
    }
    
    public func contains(componentOf signature: ComponentSignature) -> Bool {
        return _signatures.contains(signature)
    }
    
    // MARK: Subscripting
    public subscript<C: ManagedComponent>(_ componentType: C.Type) -> C? {
        get { return component(of: componentType) }
        set { setComponent(newValue) }
    }
    
    // MARK: Managing Components
    public func component<C>(of type: C.Type) -> C? where C: ManagedComponent {
        let key = C.signature
        if let address = _components[key] {
            return C.Allocator.component(at: address, in: _space)
        } else {
            return nil
        }
    }
    
    @discardableResult
    public func setComponent<C>(_ component: C?) -> C? where C: ManagedComponent {
        let key = C.signature
        if let component = component {
            // Setting non-nil
            if let address = _components[key] {
                let old = C.Allocator.component(at: address, in: _space)
                C.Allocator.setComponent(component, at: address, in: _space)
                return old
            } else {
                let address = C.Allocator.allocateComponent(component, with: id, in: _space)
                _components[key] = address
                _signatures.insert(key)
                return nil
            }
        } else {
            // Setting nil
            if let address = _components[key] {
                let old = C.Allocator.deallocateComponent(at: address, in: _space)
                _components[key] = nil
                _signatures.insert(key)
                return old.component
            } else {
                return nil
            }
        }
    }
    
    // MARK: Continuously Composing
    @discardableResult
    open func with<C>(component: C) -> Entity where C: ManagedComponent {
        setComponent(component)
        return self
    }
}
