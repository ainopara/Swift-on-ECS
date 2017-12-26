//
//  Group.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/5/17.
//

// MARK: - Group

/// `Group`
///
public class Group {
    internal let name: String
    
    internal let core: _GroupCore
    
    internal init(name: String, core: _GroupCore) {
        self.name = name
        self.core = core
    }
}

extension Group {
    public var reactiveSystems: [ReactiveSystem] {
        fatalError()
    }
    
    @discardableResult
    public func addReactiveSystem(
        withHandler handler: @escaping ReactiveHandler,
        name: String,
        isEnabled: Bool = true,
        events: GroupEventOptions,
        qualityOfService: SystemQoS
        ) -> ReactiveSystem
    {
        fatalError()
    }
    
    public func removeReactiveSystem(_ system: ReactiveSystem)
        -> ReactiveSystem?
    {
        fatalError()
    }
}

// MARK: Equatable
extension Group: Equatable {
    public static func == (lhs: Group, rhs: Group) -> Bool {
        return lhs === rhs
    }
}

// MARK: Hashable
extension Group: Hashable {
    public var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}
