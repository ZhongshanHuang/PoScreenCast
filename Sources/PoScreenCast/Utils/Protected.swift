//
//  Protected.swift
//  position
//
//  Created by zhongshan on 2023/4/21.
//

import Foundation

protocol Lock {
    func lock()
    func unlock()
}

extension Lock {
    
    func around<T>(_ closure: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try closure()
    }
    
    func around(_ closure: () throws -> Void) rethrows {
        lock()
        defer { unlock() }
        try closure()
    }
    
}

final class UnfairLock: Lock {
    private let unfairLock: os_unfair_lock_t
    
    init() {
        unfairLock = .allocate(capacity: 1)
        unfairLock.initialize(to: os_unfair_lock_s())
    }
    
    deinit {
        unfairLock.deinitialize(count: 1)
        unfairLock.deallocate()
    }
    
    func lock() {
        os_unfair_lock_lock(unfairLock)
    }
    
    func unlock() {
        os_unfair_lock_unlock(unfairLock)
    }
}

@dynamicMemberLookup
public final class Protected<T> {
    private let lock = UnfairLock()
    private var value: T
    
    public init(_ value: T) {
        self.value = value
    }
    
    public func read<U>(_ closure: (T) throws -> U) rethrows -> U {
        try lock.around { try closure(value) }
    }
    
    @discardableResult
    public func write<U>(_ closure: (inout T) throws -> U) rethrows -> U {
        try lock.around { try closure(&value) }
    }
    
    public func write(_ value: T) {
        write { $0 = value }
    }
    
    public subscript<Property>(dynamicMember keyPath: WritableKeyPath<T, Property>) -> Property {
        get { lock.around { value[keyPath: keyPath] } }
        set { lock.around { value[keyPath: keyPath] = newValue } }
    }
    
    public subscript<Property>(dynamicMember keyPath: ReferenceWritableKeyPath<T, Property>) -> Property {
        get { lock.around { value[keyPath: keyPath] } }
        set { lock.around { value[keyPath: keyPath] = newValue } }
    }
    
    public subscript<Property>(dynamicMember keyPath: KeyPath<T, Property>) -> Property {
        lock.around { value[keyPath: keyPath] }
    }
}
