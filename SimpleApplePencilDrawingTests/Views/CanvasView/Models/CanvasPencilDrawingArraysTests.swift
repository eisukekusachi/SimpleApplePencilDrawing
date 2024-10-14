//
//  CanvasPencilDrawingArraysTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/08/31.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class CanvasPencilDrawingArraysTests: XCTestCase {

    func testIsEstimatedTouchPointArrayCreationComplete() {
        let subject = CanvasPencilDrawingArrays()

        subject.appendEstimatedValue(.generate(phase: .began))
        XCTAssertEqual(subject.isEstimatedTouchPointArrayCreationComplete, false)

        subject.appendEstimatedValue(.generate(phase: .moved))
        XCTAssertEqual(subject.isEstimatedTouchPointArrayCreationComplete, false)

        subject.appendEstimatedValue(.generate(phase: .ended))
        XCTAssertEqual(subject.isEstimatedTouchPointArrayCreationComplete, true)

        subject.appendEstimatedValue(.generate(phase: .cancelled))
        XCTAssertEqual(subject.isEstimatedTouchPointArrayCreationComplete, true)
    }

    /// Confirms that the creation of `actualTouchPointArray` is complete
    func testIsActualTouchPointArrayCreationComplete() {
        let estimatedTouchPointArray: [CanvasTouchPoint] = [
            .generate(phase: .began, estimationUpdateIndex: 0),
            .generate(phase: .moved, estimationUpdateIndex: 1),
            .generate(phase: .ended, estimationUpdateIndex: nil)
        ]
        let actualTouches: [UITouch] = [
            UITouchDummy.init(phase: .began, estimationUpdateIndex: 0),
            UITouchDummy.init(phase: .moved, estimationUpdateIndex: 1)
        ]

        let subject = CanvasPencilDrawingArrays(
            estimatedTouchPointArray: estimatedTouchPointArray
        )

        /// Confirm that `lastEstimationUpdateIndex` contains `estimationUpdateIndex` of the second-to-last element of `estimatedTouchPointArray`
        subject.setSecondLastEstimationUpdateIndex()
        XCTAssertEqual(subject.lastEstimationUpdateIndex, 1)

        subject.appendActualValueWithEstimatedValue(actualTouches[0])
        XCTAssertEqual(subject.actualTouchPointArray.last?.estimationUpdateIndex, 0)

        XCTAssertFalse(subject.isActualTouchPointArrayCreationComplete)

        subject.appendActualValueWithEstimatedValue(actualTouches[1])
        XCTAssertEqual(subject.actualTouchPointArray.last?.estimationUpdateIndex, 1)

        /// Completion is determined when `lastEstimationUpdateIndex` matches `estimationUpdateIndex` of the last element in `actualTouchPointArray`
        XCTAssertTrue(subject.isActualTouchPointArrayCreationComplete)
    }

    func testAppendLastEstimatedTouchPointToActualTouchPointArray() {
        let estimatedTouches: [CanvasTouchPoint] = [
            .generate(phase: .ended, force: 0.0, estimationUpdateIndex: nil)
        ]

        let subject = CanvasPencilDrawingArrays(
            estimatedTouchPointArray: estimatedTouches
        )
        subject.appendLastEstimatedTouchPointToActualTouchPointArray()

        XCTAssertEqual(subject.actualTouchPointArray.last, subject.estimatedTouchPointArray.last)
    }

    /// Confirms that elements created by combining actual and estimated values are added to `actualTouchPointArray`
    func testAppendActualValueWithEstimatedValue() {
        let estimatedTouches: [CanvasTouchPoint] = [
            .generate(phase: .began, force: 1.0, estimationUpdateIndex: 0),
            .generate(phase: .moved, force: 1.0, estimationUpdateIndex: 1),
            .generate(phase: .moved, force: 1.0, estimationUpdateIndex: 2),
            .generate(phase: .ended, force: 0.0, estimationUpdateIndex: nil)
        ]

        let actualTouches: [UITouch] = [
            UITouchDummy.init(phase: .began, force: 0.3, estimationUpdateIndex: 0),
            UITouchDummy.init(phase: .moved, force: 0.2, estimationUpdateIndex: 1),
            UITouchDummy.init(phase: .moved, force: 0.1, estimationUpdateIndex: 2)
        ]

        let subject = CanvasPencilDrawingArrays(
            estimatedTouchPointArray: estimatedTouches
        )
        /// Since `.ended` event is not sent from the Apple Pencil,
        /// the last element of `estimatedTouchPointArray` is added to the end of `actualTouchPointArray` to finalize the process
        subject.setSecondLastEstimationUpdateIndex()

        actualTouches
            .sorted(by: { $0.timestamp < $1.timestamp })
            .forEach { value in
            subject.appendActualValueWithEstimatedValue(value)
        }
        subject.appendLastEstimatedValueIfProcessCompleted()

        /// Verifie that the estimated value is used for `UITouch.Phase` and the actual value is used for `force`
        XCTAssertEqual(subject.actualTouchPointArray[0].phase, estimatedTouches[0].phase)
        XCTAssertEqual(subject.actualTouchPointArray[0].force, actualTouches[0].force)

        XCTAssertEqual(subject.actualTouchPointArray[1].phase, estimatedTouches[1].phase)
        XCTAssertEqual(subject.actualTouchPointArray[1].force, actualTouches[1].force)

        XCTAssertEqual(subject.actualTouchPointArray[2].phase, estimatedTouches[2].phase)
        XCTAssertEqual(subject.actualTouchPointArray[2].force, actualTouches[2].force)

        /// Confirm that the last value used is an estimated value
        XCTAssertEqual(subject.actualTouchPointArray[3].phase, estimatedTouches[3].phase)
        XCTAssertEqual(subject.actualTouchPointArray[3].force, estimatedTouches[3].force)
    }

    /// Confirms that on `.ended`, `lastEstimationUpdateIndex` contains the `estimationUpdateIndex` from the second-to-last element of `estimatedTouchPointArray`
    func testUpdateLastEstimationUpdateIndexAtTouchEnded() {
        let subject = CanvasPencilDrawingArrays()

        /// When the phase is not `.ended`, `lastEstimationUpdateIndex` will be `nil`
        subject.appendEstimatedValue(.generate(phase: .began, estimationUpdateIndex: 0))
        XCTAssertNil(subject.lastEstimationUpdateIndex)

        subject.appendEstimatedValue(.generate(phase: .moved, estimationUpdateIndex: 1))
        XCTAssertNil(subject.lastEstimationUpdateIndex)

        subject.appendEstimatedValue(.generate(phase: .moved, estimationUpdateIndex: 2))
        XCTAssertNil(subject.lastEstimationUpdateIndex)

        /// When the `phase` is `.ended`, `lastEstimationUpdateIndex` will be `estimationUpdateIndex` of the element before the last element in `estimatedTouchPointArray`
        subject.appendEstimatedValue(.generate(phase: .ended, estimationUpdateIndex: nil))
        XCTAssertEqual(subject.lastEstimationUpdateIndex, 2)
    }

    /// Confirms that on `.cancelled`, `lastEstimationUpdateIndex` contains the `estimationUpdateIndex` from the second-to-last element of `estimatedTouchPointArray`
    func testUpdateLastEstimationUpdateIndexAtTouchCancelled() {
        let subject = CanvasPencilDrawingArrays()

        /// When the phase is not `.ended`, `lastEstimationUpdateIndex` will be `nil`
        subject.appendEstimatedValue(.generate(phase: .began, estimationUpdateIndex: 0))
        XCTAssertNil(subject.lastEstimationUpdateIndex)

        subject.appendEstimatedValue(.generate(phase: .moved, estimationUpdateIndex: 1))
        XCTAssertNil(subject.lastEstimationUpdateIndex)

        subject.appendEstimatedValue(.generate(phase: .moved, estimationUpdateIndex: 2))
        XCTAssertNil(subject.lastEstimationUpdateIndex)

        /// When the `phase` is `.cancelled`, `lastEstimationUpdateIndex` will be `estimationUpdateIndex` of the element before the last element in `estimatedTouchPointArray`
        subject.appendEstimatedValue(.generate(phase: .cancelled, estimationUpdateIndex: nil))
        XCTAssertEqual(subject.lastEstimationUpdateIndex, 2)
    }

}
