//
//  Iterator.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import Foundation

class Iterator<T: Equatable>: IteratorProtocol {

    typealias Element = T

    private(set) var array: [Element] = []
    private(set) var index: Int = 0

    /// Retrieve a element sequentially
    func next() -> Element? {
        if index < array.count {
            let element = array[index]
            index += 1

            return element
        } else {
            return nil
        }
    }

    /// Retrieve elements sequentially by specifying a range of 1 or more
    func next(range: Int) -> [Element]? {
        guard range > 0 else { return nil }

        if (index + range) <= array.count {
            let elements = array[index ..< index + range]
            index += 1

            return Array(elements)
        } else {
            return nil
        }
    }

    func append(_ element: Element) {
        array.append(element)
    }
    func append(_ elements: [Element]) {
        array.append(contentsOf: elements)
    }

    func replace(index: Int, element: Element) {
        array[index] = element
    }

    func reset() {
        index = 0
        array = []
    }

}
