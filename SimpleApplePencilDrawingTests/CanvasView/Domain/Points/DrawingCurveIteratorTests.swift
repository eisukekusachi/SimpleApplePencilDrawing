//
//  DrawingCurveIteratorTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2025/02/22.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class DrawingCurveIteratorTests: XCTestCase {

    func testIsDrawingFinished() {
        let subject = DrawingCurveIterator()

        subject.touchPhase = .began
        XCTAssertFalse(subject.isDrawingFinished)
        XCTAssertTrue(subject.isCurrentlyDrawing)

        subject.touchPhase = .moved
        XCTAssertFalse(subject.isDrawingFinished)
        XCTAssertTrue(subject.isCurrentlyDrawing)

        subject.touchPhase = .ended
        XCTAssertTrue(subject.isDrawingFinished)
        XCTAssertFalse(subject.isCurrentlyDrawing)

        subject.touchPhase = .cancelled
        XCTAssertTrue(subject.isDrawingFinished)
        XCTAssertFalse(subject.isCurrentlyDrawing)
    }

    func testShouldDrawFirstCurve() {
        let subject = DrawingCurveIterator()

        subject.append([
            .generate(),
            .generate()
        ])
        XCTAssertFalse(subject.shouldDrawFirstCurve)

        // After creating the instance, it becomes `true` when three elements are stored in the array.
        subject.append([
            .generate()
        ])
        XCTAssertTrue(subject.shouldDrawFirstCurve)

        // Once it is true, calling `getPoints()` sets it to false.
        _ = subject.getPoints()
        XCTAssertFalse(subject.shouldDrawFirstCurve)
    }

}
