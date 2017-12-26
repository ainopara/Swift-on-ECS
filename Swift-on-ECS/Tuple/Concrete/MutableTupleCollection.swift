//
//  MutableTupleCollection.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 12/5/17.
//

public struct MutableTupleCollection: MutableCollection {
    public typealias Element = Tuple
    
    public typealias Index = Int
    
    public typealias IndexDistance = Int
    
    public var startIndex: Index { fatalError() }
    
    public var endIndex: Index { fatalError() }
    
    public var count: IndexDistance { fatalError() }
    
    public subscript(index: Index) -> Element {
        get { fatalError() }
        set { fatalError() }
    }
    
    public func index(after i: Index) -> Index {
        fatalError()
    }
}
