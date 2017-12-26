//
//  OrderedSet.swift
//  Swift-on-ECS
//
//  Created by WeZZard on 11/30/17.
//

/// A naïve implementation to OrderedSet
public struct OrderedSet<E: Hashable & Comparable> {
    public typealias Element = E
    
    internal var _order: [Element]
    internal var _set: Set<Element>
}

// MARK: SetAlgebra
extension OrderedSet: SetAlgebra {
    public init() {
        _order = []
        _set = Set()
    }
    
    /// Returns a Boolean value that indicates whether the given element
    /// exists in the set.
    public func contains(_ item: Element) -> Bool {
        return _set.contains(item)
    }
    
    /// Returns a new set with the elements of both this and the given
    /// set.
    ///
    public func union(_ other: OrderedSet) -> OrderedSet {
        return _copy(self) { $0.formUnion(other) }
    }
    
    /// Returns a new set with the elements that are common to both this
    /// set and the given set.
    public func intersection(_ other: OrderedSet) -> OrderedSet {
        return _copy(self) { $0.formIntersection(other) }
    }
    
    /// Returns a new set with the elements that are either in this set or
    /// in the given set, but not in both.
    ///
    public func symmetricDifference(_ other: OrderedSet) -> OrderedSet {
        return _copy(self) { $0.formSymmetricDifference(other) }
    }
    
    /// Inserts the given element in the set if it is not already present.
    ///
    @discardableResult
    public mutating func insert(_ item: Element)
        -> (inserted: Bool, memberAfterInsert: Element)
    {
        let (inserted, element) = _set.insert(item)
        if inserted {
            _order.append(item)
        }
        return (inserted, element)
    }
    
    /// Removes the given element and any elements subsumed by the given
    /// element.
    ///
    @discardableResult
    public mutating func remove(_ item: Element) -> Element? {
        let element = _set.remove(item)
        if element != nil {
            let index = _order.index(of: item)
            _order.remove(at: index!)
        }
        return element
    }
    
    /// Inserts the given element into the set unconditionally.
    ///
    @discardableResult
    public mutating func update(with item: Element) -> Element? {
        guard let existingItem = _set.update(with: item) else {
            _order.append(item)
            return nil
        }
        return existingItem
    }
    
    /// Adds the elements of the given set to the set.
    ///
    public mutating func formUnion(_ other: OrderedSet) {
        for item in other {
            insert(item)
        }
    }
    
    /// Removes the elements of this set that aren't also in the given
    /// set.
    ///
    public mutating func formIntersection(_ other: OrderedSet) {
        for item in self {
            if !other.contains(item) {
                _set.remove(item)
            }
        }
        _order = _order.filter({ _set.contains($0) })
    }
    
    /// Removes the elements of the set that are also in the given set and
    /// adds the members of the given set that are not already in the set.
    ///
    public mutating func formSymmetricDifference(_ other: OrderedSet) {
        for element in other {
            if contains(element) {
                _set.remove(element)
            } else {
                update(with: element)
            }
        }
        _order = _order.filter({ _set.contains($0) })
    }
    
    /// Returns a new set containing the elements of this set that do not
    /// occur in the given set.
    ///
    public func subtracting(_ other: OrderedSet) -> OrderedSet {
        return _copy(self) { $0.subtract(other) }
    }
    
    /// Returns a Boolean value that indicates whether the set is a subset
    /// of another set.
    public mutating func subtract(_ other: OrderedSet) {
        for element in other {
            _set.remove(element)
        }
        _order = _order.filter({ _set.contains($0) })
    }
}

// MARK: - MutableCollection
extension OrderedSet: MutableCollection {
    public typealias Iterator = IndexingIterator<[Element]>
    
    /// Returns an iterator over the elements of the collection.
    public func makeIterator() -> Iterator {
        return _order.makeIterator()
    }
    
    /// The position of the first element in a nonempty collection.
    ///
    /// If the collection is empty, `startIndex` is equal to `endIndex`.
    public var startIndex: Int {
        return _order.startIndex
    }
    
    /// The collection's "past the end" position---that is, the position
    /// one greater than the last valid subscript argument.
    ///
    public var endIndex: Int {
        return _order.endIndex
    }
    
    /// Returns the position immediately after the given index.
    ///
    public func index(after: Int) -> Int {
        return _order.index(after: after)
    }
    
    /// A Boolean value indicating whether the collection is empty.
    ///
    public var isEmpty: Bool {
        return _order.isEmpty
    }
    
    /// Accesses the element at the specified position.
    ///
    public subscript(index: Int) -> Element {
        get {
            return _order[index]
        }
        set {
            let oldIndex = _order.index(of: newValue)
            
            _set.remove(_order[index])
            
            _order[index] = newValue
            _set.update(with: newValue)
            
            if oldIndex != nil && oldIndex! != index {
                _order.remove(at: oldIndex!)
            }
        }
    }
    
    /// Exchanges the values at the specified indices of the collection.
    ///
    public mutating func swapAt(_ i: Int, _ j: Int) {
        guard i != j else {
            return
        }
        let tmp = _order[i]
        _order[i] = _order[j]
        _order[j] = tmp
    }
    
    /// Sorts the collection ascendingly, in place.
    public mutating func sort() {
        _order.sort()
    }
    
    /// Sorts the collection in place, using given comparison predicate.
    public mutating func sort(
        by predicate: (Element, Element) throws -> Bool
        ) rethrows
    {
        try _order.sort(by: predicate)
    }
}

extension OrderedSet: RandomAccessCollection {}

extension OrderedSet: Equatable {
    /// Checks whether two OrderedSets are equal.
    /// Note that this follows Array semantics, not Set ones, i.e
    /// OrderedSets with the same items, but at different positions are
    /// reported as different.
    ///
    /// - Parameters:
    ///   - lhs: First OrderedSet to compare.
    ///   - rhs: Second OrderedSet to compare.
    /// - Returns: `true` if OrderedSets are equal, `false` otherwise.
    public static func == (lhs: OrderedSet, rhs: OrderedSet) -> Bool {
        return lhs._order == rhs._order
    }
}

extension OrderedSet: CustomStringConvertible {
    public var description: String {
        let details = _order.map({"\($0)"}).joined(separator: ", ")
        return "<OrderedSet: Elements-with-Order = \"\(details)\">"
    }
}

internal func _copy<Element>(
    _ orderedSet: OrderedSet<Element>,
    using closure: (inout OrderedSet<Element>) -> Void
    ) -> OrderedSet<Element>
{
    var copy = orderedSet
    closure(&copy)
    return copy
}
