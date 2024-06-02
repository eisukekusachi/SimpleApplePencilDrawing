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

    var count: Int {
        return array.count
    }
    var currentIndex: Int {
        return index - 1
    }
    var isFirstProcessing: Bool {
        return index == 1
    }

    func next() -> Element? {
        if index < array.count {
            let elem = array[index]
            index += 1
            return elem
        } else {
            return nil
        }
    }

    func next(range: Int = 1, _ results: ([Element]) -> Void) {
        if range <= 0 { return }

        while (index + range) <= array.count {
            results(Array(array[index ..< index + range]))
            index += 1
        }
    }
    func next(range: Int) -> [Element]? {
        if range <= 0 { return nil }

        if (index + range) <= array.count {

            let elems = array[index ..< index + range]
            index += 1

            return Array(elems)

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

    func clear() {
        index = 0
        array = []
    }

}
