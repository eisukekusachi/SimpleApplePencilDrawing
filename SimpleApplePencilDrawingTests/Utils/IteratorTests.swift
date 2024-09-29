//
//  IteratorTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/09/29.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class IteratorTests: XCTestCase {

    func testNext() {
        let iterator = Iterator<Int>()
        iterator.append([0, 1, 2])

        XCTAssertEqual(iterator.next(), 0)
        XCTAssertEqual(iterator.next(), 1)
        XCTAssertEqual(iterator.next(), 2)
        XCTAssertEqual(iterator.next(), nil)
    }

    func testNextWithRange0() {
        let range = 0
        let iterator = Iterator<Int>()
        iterator.append([0, 1])

        XCTAssertEqual(iterator.next(range: range), nil)
    }

    func testNextWithRange1() {
        let range = 1
        let iterator = Iterator<Int>()
        iterator.append([0, 1, 2])

        XCTAssertEqual(iterator.next(range: range), [0])
        XCTAssertEqual(iterator.next(range: range), [1])
        XCTAssertEqual(iterator.next(range: range), [2])
        XCTAssertEqual(iterator.next(range: range), nil)
    }

    func testNextWithRange4() {
        let range = 4
        let iterator = Iterator<Int>()
        iterator.append([0, 1, 2, 3, 4, 5])

        XCTAssertEqual(iterator.next(range: range), [0, 1, 2, 3])
        XCTAssertEqual(iterator.next(range: range), [1, 2, 3, 4])
        XCTAssertEqual(iterator.next(range: range), [2, 3, 4, 5])
        XCTAssertEqual(iterator.next(range: range), nil)
    }

}
