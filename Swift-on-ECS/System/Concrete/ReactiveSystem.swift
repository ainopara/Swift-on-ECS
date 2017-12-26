//
//  ReactiveSystem.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/12/17.
//

public final class ReactiveSystem {
    internal typealias _Metadata = _ReactiveSystemMetadata
    
    internal init() {
        _unimplemented()
    }
    
    public var group: Group {
        fatalError()
    }
    
    public var qualityOfService: SystemQoS {
        get { _unimplemented() }
        set { _unimplemented() }
    }
    
    public var events: GroupEventOptions {
        get { _unimplemented() }
        set { _unimplemented() }
    }
}

extension ReactiveSystem: System {
    public var name: String {
        get { _unimplemented() }
        set { _unimplemented() }
    }
    
    public var isEnabled: Bool {
        get { _unimplemented() }
        set { _unimplemented() }
    }
}

extension ReactiveSystem: Equatable {
    public static func == (lhs: ReactiveSystem, rhs: ReactiveSystem)
        -> Bool
    {
        _unimplemented()
    }
}

extension ReactiveSystem: Hashable {
    public var hashValue: Int {
        _unimplemented()
    }
}
