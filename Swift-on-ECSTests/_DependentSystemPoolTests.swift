//
//  _DependentSystemPoolTests.swift
//  Swift-on-ECSTests
//
//  Created by WeZZard on 11/29/17.
//

import XCTest

import SwiftExt

@testable
import ECS

class _DependentSystemPoolTests: XCTestCase {
    private var _pool: _DependentSystemPool<_DummySystemMetadata>!
    
    override func setUp() {
        super.setUp()
        _pool = _DependentSystemPool()
    }
    
    override func tearDown() {
        super.tearDown()
        _pool = nil
    }
    
    // MARK: Test Update
    internal func testTransactionBracket() {
        _pool.beginTransaction()
        XCTAssert(_pool.isInTransaction)
        _pool.endTransaction()
        XCTAssert(!_pool.isInTransaction)
    }
    
    internal func testInsertionWithRetaining() {
        let metadata = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [])
        
        XCTAssert(metadata.handler === _DummySystemHandler1)
        
        let owner = _pool.insertSystem(with: metadata)
        let index = owner.index
        
        XCTAssert(!_pool.isEmpty)
        XCTAssert(Array(_pool).map({$0.metadata}) == [metadata])
        XCTAssert(_pool.name(forSystemAt: index) == metadata.name)
        XCTAssert(_pool.isEnabled(forSystemAt: index) == metadata.isEnabled)
        XCTAssert(_pool.handlerIdentifier(forSystemAt: index) == FunctionIdentifier(_DummySystemHandler1))
    }
    
    internal func testInsertionWithoutRetaining() {
        let metadata = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [])
        
        XCTAssert(metadata.handler === _DummySystemHandler1)
        
        _ = _pool.insertSystem(with: metadata)
        
        XCTAssert(_pool.isEmpty)
        XCTAssert(Array(_pool).map({$0.metadata}) == [])
    }
    
    internal func testInsertionWithDuplicateValues() {
        let metadata = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [])
        
        let owner1 = _pool.insertSystem(with: metadata)
        let owner2 = _pool.insertSystem(with: metadata)
        
        XCTAssert(owner1 == owner2)
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [metadata])
    }
    
    internal func testInsertionWithIdenticalHashInequatableValues() {
        let metadata1 = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            extraIdentifier: "Metadata 1",
            handler: _DummySystemHandler1
        )
        
        let metadata2 = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            extraIdentifier: "Metadata 2",
            handler: _DummySystemHandler1
        )
        
        let owner1 = _pool.insertSystem(with: metadata1)
        let owner2 = _pool.insertSystem(with: metadata2)
        
        XCTAssert(owner1 !== owner2)
        XCTAssert(Array(_pool).map({$0.metadata}) == [metadata1, metadata2])
    }
    
    internal func testUnusing() {
        let metadata = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [])
        
        let insertedOwner = _pool.insertSystem(with: metadata)
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [metadata])
        
        _pool.unuseSystem(at: insertedOwner.index)
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [])
        
        XCTAssert(_pool.isEmpty)
    }
    
    internal func testUnusingWithTransaction() {
        let metadata = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [])
        
        _pool.beginTransaction()
        
        let insertedOwner = _pool.insertSystem(with: metadata)
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [metadata])
        
        _pool.unuseSystem(at: insertedOwner.index)
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [])
        
        XCTAssert(_pool.isEmpty)
        
        _pool.endTransaction()
        XCTAssert(_pool.isEmpty)
    }
    
    // MARK: Test Iteration
    internal func testIteratingEmptyGraph() {
        XCTAssert(Array(_pool).map({$0.metadata}) == [])
    }
    
    internal func testIteratingConcreteGraph() {
        let metadata1 = _DummySystemMetadata(
            name: "Test1",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        let metadata2 = _DummySystemMetadata(
            name: "Test2",
            isEnabled: true,
            handler: _DummySystemHandler2
        )
        let metadata3 = _DummySystemMetadata(
            name: "Test3",
            isEnabled: true,
            handler: _DummySystemHandler3
        )
        
        _pool.beginTransaction()
        let owner1 = _pool.insertSystem(with: metadata1)
        let owner2 = _pool.insertSystem(with: metadata2)
        let owner3 = _pool.insertSystem(with: metadata3)
        _pool.endTransaction()
        
        // suppress unused variable warnings.
        _ = [owner1, owner2, owner3]
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [metadata1, metadata2, metadata3])
    }
    
    // MARK: Test Dependency Setup
    internal func testSettingSystemRequiringAnother() {
        let metadata1 = _DummySystemMetadata(
            name: "Test1",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        let metadata2 = _DummySystemMetadata(
            name: "Test2",
            isEnabled: true,
            handler: _DummySystemHandler2
        )
        
        _pool.beginTransaction()
        let owner1 = _pool.insertSystem(with: metadata1)
        let owner2 = _pool.insertSystem(with: metadata2)
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [])
        
        _pool.setSystem(at: owner1.index, requiresSystemAt: owner2.index)
        _pool.endTransaction()
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [metadata2, metadata1])
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [owner1.index])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [owner2.index])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [])
        
    }
    
    internal func testSettingSystemNotRequiringAnother() {
        let metadata1 = _DummySystemMetadata(
            name: "Test1",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        let metadata2 = _DummySystemMetadata(
            name: "Test2",
            isEnabled: true,
            handler: _DummySystemHandler2
        )
        
        _pool.beginTransaction()
        let owner1 = _pool.insertSystem(with: metadata1)
        let owner2 = _pool.insertSystem(with: metadata2)
        _pool.setSystem(at: owner1.index, requiresSystemAt: owner2.index)
        _pool.endTransaction()
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [owner1.index])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [owner2.index])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [])
        
        _pool.beginTransaction()
        _pool.setSystem(at: owner1.index, doesNotRequireSystemAt: owner2.index)
        _pool.endTransaction()
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
    }
    
    internal func testSettingSystemBeingRequiredByAnother() {
        let metadata1 = _DummySystemMetadata(
            name: "Test1",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        let metadata2 = _DummySystemMetadata(
            name: "Test2",
            isEnabled: true,
            handler: _DummySystemHandler2
        )
        
        _pool.beginTransaction()
        let owner1 = _pool.insertSystem(with: metadata1)
        let owner2 = _pool.insertSystem(with: metadata2)
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [])
        
        _pool.setSystem(at: owner1.index, isRequiredBySystemAt: owner2.index)
        
        _pool.endTransaction()
        
        XCTAssert(Array(_pool).map({$0.metadata}) == [metadata1, metadata2])
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [owner2.index])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [owner1.index])
    }
    
    internal func testSettingSystemBeingNotRequiredByAnother() {
        let metadata1 = _DummySystemMetadata(
            name: "Test1",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        let metadata2 = _DummySystemMetadata(
            name: "Test2",
            isEnabled: true,
            handler: _DummySystemHandler2
        )
        
        _pool.beginTransaction()
        let owner1 = _pool.insertSystem(with: metadata1)
        let owner2 = _pool.insertSystem(with: metadata2)
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [])
        
        _pool.setSystem(at: owner1.index, isRequiredBySystemAt: owner2.index)
        
        _pool.endTransaction()
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [owner2.index])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [owner1.index])
        
        _pool.beginTransaction()
        _pool.setSystem(at: owner1.index, isNotRequiredBySystemAt: owner2.index)
        _pool.endTransaction()
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [])
    }
    
    func testRevokingSystemRequiringAnotherWithUnusing() {
        let metadata1 = _DummySystemMetadata(
            name: "Test1",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        let metadata2 = _DummySystemMetadata(
            name: "Test2",
            isEnabled: true,
            handler: _DummySystemHandler2
        )
        
        _pool.beginTransaction()
        let owner1 = _pool.insertSystem(with: metadata1)
        let owner2 = _pool.insertSystem(with: metadata2)
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [])
        
        _pool.setSystem(at: owner1.index, requiresSystemAt: owner2.index)
        _pool.endTransaction()
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [owner1.index])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [owner2.index])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [])
        
        _pool.beginTransaction()
        _pool.unuseSystem(at: owner2.index)
        _pool.endTransaction()
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
    }
    
    func testRevokingSystemBeingRequiredByAnotherWithUnusing() {
        let metadata1 = _DummySystemMetadata(
            name: "Test1",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        let metadata2 = _DummySystemMetadata(
            name: "Test2",
            isEnabled: true,
            handler: _DummySystemHandler2
        )
        
        _pool.beginTransaction()
        let owner1 = _pool.insertSystem(with: metadata1)
        let owner2 = _pool.insertSystem(with: metadata2)
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [])
        
        _pool.setSystem(at: owner1.index, isRequiredBySystemAt: owner2.index)
        
        _pool.endTransaction()
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [owner2.index])
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner2.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner2.index) == [owner1.index])
        
        _pool.beginTransaction()
        _pool.unuseSystem(at: owner2.index)
        _pool.endTransaction()
        
        XCTAssert(_pool.indicesForSystemsRequiring(systemAt: owner1.index) == [])
        XCTAssert(_pool.indicesForSystemsRequired(bySystemAt: owner1.index) == [])
    }
    
    // MARK: Test System Member Setup
    func testGettingSystemName() {
        let metadata = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        _pool.beginTransaction()
        let owner = _pool.insertSystem(with: metadata)
        let index = owner.index
        XCTAssert(_pool.name(forSystemAt: index) == metadata.name)
        _pool.endTransaction()
    }
    
    func testSettingSystemName() {
        let metadata = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        _pool.beginTransaction()
        let owner = _pool.insertSystem(with: metadata)
        let index = owner.index
        XCTAssert(_pool.name(forSystemAt: index) == metadata.name)
        _pool.setName("Test System", forSystemAt: index)
        XCTAssert(_pool.name(forSystemAt: index) == "Test System")
        _pool.endTransaction()
    }
    
    func testGettingSystemIsEnabled() {
        let metadata = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        _pool.beginTransaction()
        let owner = _pool.insertSystem(with: metadata)
        let index = owner.index
        XCTAssert(_pool.isEnabled(forSystemAt: index))
        _pool.endTransaction()
    }
    
    func testSettingSystemEnabled() {
        let metadata = _DummySystemMetadata(
            name: "Test",
            isEnabled: true,
            handler: _DummySystemHandler1
        )
        
        _pool.beginTransaction()
        let owner = _pool.insertSystem(with: metadata)
        let index = owner.index
        XCTAssert(_pool.isEnabled(forSystemAt: index))
        _pool.setEnabled(false, forSystemAt: index)
        XCTAssert(!_pool.isEnabled(forSystemAt: index))
        _pool.endTransaction()
    }
}

// MARK: - Dummies
private func _DummySystemHandler1() {}
private func _DummySystemHandler2() {}
private func _DummySystemHandler3() {}

private struct _DummySystemMetadata: _VariantSystemMetadata {
    var name: String
    
    var isEnabled: Bool
    
    let extraIdentifier: String?
    
    let handler: () -> Void
    
    let handlerIdentifier: FunctionIdentifier
    
    init(
        name: String,
        isEnabled: Bool,
        extraIdentifier: String? = nil,
        handler: @escaping () -> Void
        )
    {
        self.name = name
        self.isEnabled = isEnabled
        self.extraIdentifier = extraIdentifier
        self.handler = handler
        self.handlerIdentifier = FunctionIdentifier(handler)
    }
    
    var hashValue: Int {
        return handlerIdentifier.hashValue
    }
    
    static func == (lhs: _DummySystemMetadata, rhs: _DummySystemMetadata) -> Bool {
        return lhs.handlerIdentifier == rhs.handlerIdentifier && lhs.extraIdentifier == rhs.extraIdentifier
    }
}
