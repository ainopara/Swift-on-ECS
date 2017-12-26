//
//  _GroupCore.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/12/17.
//

import SwiftExt

internal protocol _GroupingContext: class {
    
}

/// `_GroupCore`
///
internal class _GroupCore {
    internal unowned let context: _GroupingContext
    
    internal let signature: BitString
    
    internal var anonymousGroup: Group {
        if _anonymousGroup_ == nil {
            _anonymousGroup_ = Group(name: "", core: self)
        }
        return _anonymousGroup_
    }
    
    internal var nominalGroups: [String: Group]
    
    internal init(context: _GroupingContext, signature: BitString) {
        self.context = context
        self.signature = signature
        nominalGroups = [:]
    }
    
    internal var _anonymousGroup_: Group!
}

extension _GroupCore {
    @discardableResult
    internal func addReactiveSystem(
        with handler: ReactiveHandler,
        for events: GroupEventOptions,
        qos: SystemQoS,
        enabled: Bool
        ) -> ReactiveSystem
    {
        fatalError()
    }
    
    internal func removeReactiveSystem(_ system: ReactiveSystem)
        -> ReactiveSystem?
    {
        fatalError()
    }
}

extension _GroupCore: Equatable {
    internal static func == (lhs: _GroupCore, rhs: _GroupCore) -> Bool {
        fatalError()
    }
}
