//
//  DependentSystem.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/23/17.
//

public protocol DependentSystem: System {
    var required: Set<Self> { get }
    
    @discardableResult
    func setRequired(by systems: Set<Self>) -> Self
    
    @discardableResult
    func setNotRequired(by systems: Set<Self>) -> Self
    
    var requires: Set<Self> { get }
    
    @discardableResult
    func setRequires(_ systems: Set<Self>) -> Self
    
    @discardableResult
    func setNotRequires(_ systems: Set<Self>) -> Self
}

extension DependentSystem {
    @discardableResult
    public func setRequired(by systems: Self...) -> Self {
        return setRequired(by: Set(systems))
    }
    
    @discardableResult
    public func setNotRequired(by systems: Self...) -> Self {
        return setNotRequired(by: Set(systems))
    }
    
    @discardableResult
    public func setRequires(_ systems: Self...) -> Self {
        return setRequires(Set(systems))
    }
    
    @discardableResult
    public func setNotRequires(_ systems: Self...) -> Self {
        return setNotRequires(Set(systems))
    }
}
