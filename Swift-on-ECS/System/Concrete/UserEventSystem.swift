//
//  UserEventSystem.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/12/17.
//

public final class UserEventSystem: _DependentSystem {
    internal typealias _Manager = _UserEventSystemManager
    
    internal typealias _Metadata = _UserEventSystemMetadata
    
    internal let _owner: _DependentSystemOwner<_Metadata>
    
    internal let _manager: _Manager
    
    internal init(owner: _DependentSystemOwner<_Metadata>, manager: _Manager) {
        _owner = owner
        _manager = manager
    }
}

extension UserEventSystem: ImplicitSystem {
    public var name: String {
        get { return _manager.name(forSystem: self) }
        set { _manager.setName(newValue, forSystem: self) }
    }
    
    public var isEnabled: Bool {
        get { return _manager.isEnabled(forSystem: self) }
        set { _manager.setEnabled(newValue, forSystem: self) }
    }
    
    public var qualityOfService: SystemQoS {
        get { return _manager.qualityOfService(forSystem: self) }
        set { _manager.setQualityOfService(newValue, forSystem: self) }
    }
}

extension UserEventSystem: DependentSystem {
    public var required: Set<UserEventSystem> {
        return _manager.systems(requiringSystem: self)
    }
    
    public var requires: Set<UserEventSystem> {
        return _manager.systems(requiredBySystem: self)
    }
    
    @discardableResult
    public func setRequired(by systems: Set<UserEventSystem>)
        -> UserEventSystem
    {
        for each in systems {
            _manager.setSystem(self, isRequiredBySystem: each)
        }
        return self
    }
    
    @discardableResult
    public func setNotRequired(by systems: Set<UserEventSystem>)
        -> UserEventSystem
    {
        for each in systems {
            _manager.setSystem(self, isNotRequiredBySystem: each)
        }
        return self
    }
    
    @discardableResult
    public func setRequires(_ systems: Set<UserEventSystem>)
        -> UserEventSystem
    {
        for each in systems {
            _manager.setSystem(self, requiresSystem: each)
        }
        return self
    }
    
    @discardableResult
    public func setNotRequires(_ systems: Set<UserEventSystem>)
        -> UserEventSystem
    {
        for each in systems {
            _manager.setSystem(self, doesNotRequireSystem: each)
        }
        return self
    }
}

extension UserEventSystem: Equatable {
    public static func == (lhs: UserEventSystem, rhs: UserEventSystem)
        -> Bool
    {
        return lhs._manager === rhs._manager && lhs._owner === rhs._owner
    }
}

extension UserEventSystem: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(_owner).hashValue
    }
}
