//
//  Sequence+Async.swift
//  Wallet (iOS)
//
//  Created by Stefano on 18.01.22.
//

import Foundation

extension Sequence {
    
    func asyncMap<T>(_ transform: (Element) async throws -> T) async rethrows -> [T] {
        var values = [T]()

        for element in self {
            try await values.append(transform(element))
        }

        return values
    }
    
    func asyncForEach(_ operation: (Element) async throws -> Void) async rethrows {
        for element in self {
            try await operation(element)
        }
    }
    
    func concurrentForEach(_ operation: @escaping (Element) async -> Void) async {
        // A task group automatically waits for all of its
        // sub-tasks to complete, while also performing those
        // tasks in parallel:
        await withTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    await operation(element)
                }
            }
        }
    }
    
    func concurrentForEach(_ operation: @escaping (Element) async throws -> Void) async throws {
        // A task group automatically waits for all of its
        // sub-tasks to complete, while also performing those
        // tasks in parallel:
        await withThrowingTaskGroup(of: Void.self) { group in
            for element in self {
                group.addTask {
                    try await operation(element)
                }
            }
        }
    }
}
