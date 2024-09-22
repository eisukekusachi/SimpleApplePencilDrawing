//
//  InterpolatorTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/09/22.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class InterpolatorTests {

    func testGetCubicCurvePoints() {
        let movePoint: CGPoint = .init(x: 0.0, y: 0.0)
        let controlPoint1: CGPoint = .init(x: 0.0, y: 1.0)
        let controlPoint2: CGPoint = .init(x: 1.0, y: 1.0)
        let endPoint: CGPoint = .init(x: 1.0, y: 0.0)

        let testCases: [(result: [CGPoint], expectedValues: [CGPoint])] = [
            /// If `duration` is `0`
            (
                Interpolator.getCubicCurvePoints(
                    movePoint: movePoint,
                    controlPoint1: controlPoint1,
                    controlPoint2: controlPoint2,
                    endPoint: endPoint,
                    duration: 0,
                    addLastPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `0`, the last value is added to the array, so the array count will be `1`.
                [
                    .init(x: 1.0, y: 0.0)
                ]
            ),
            (
                Interpolator.getCubicCurvePoints(
                    movePoint: movePoint,
                    controlPoint1: controlPoint1,
                    controlPoint2: controlPoint2,
                    endPoint: endPoint,
                    duration: 0,
                    addLastPoint: false
                ),
                []
            ),
            /// If `duration` is `1`
            (
                Interpolator.getCubicCurvePoints(
                    movePoint: movePoint,
                    controlPoint1: controlPoint1,
                    controlPoint2: controlPoint2,
                    endPoint: endPoint,
                    duration: 1,
                    addLastPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `1`, the last value is added to the array, so the array count will be `2`.
                [
                    .init(x: 0.0, y: 0.0),
                    .init(x: 1.0, y: 0.0)
                ]
            ),
            (
                Interpolator.getCubicCurvePoints(
                    movePoint: movePoint,
                    controlPoint1: controlPoint1,
                    controlPoint2: controlPoint2,
                    endPoint: endPoint,
                    duration: 1,
                    addLastPoint: false
                ),
                [
                    .init(x: 0.0, y: 0.0)
                ]
            ),
            /// If `duration` is `4`
            (
                Interpolator.getCubicCurvePoints(
                    movePoint: movePoint,
                    controlPoint1: controlPoint1,
                    controlPoint2: controlPoint2,
                    endPoint: endPoint,
                    duration: 4,
                    addLastPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `4`, the last value is added to the array, so the array count will be `5`.
                [
                    CGPoint(x: 0.0, y: 0.0),
                    CGPoint(x: 0.15625, y: 0.5625),
                    CGPoint(x: 0.5, y: 0.75),
                    CGPoint(x: 0.84375, y: 0.5625),
                    CGPoint(x: 1.0, y: 1.0)
                ]
            ),
            (
                Interpolator.getCubicCurvePoints(
                    movePoint: movePoint,
                    controlPoint1: controlPoint1,
                    controlPoint2: controlPoint2,
                    endPoint: endPoint,
                    duration: 4,
                    addLastPoint: false
                ),
                /// Confirm that the last value is not included.
                [
                    CGPoint(x: 0.0, y: 0.0),
                    CGPoint(x: 0.15625, y: 0.5625),
                    CGPoint(x: 0.5, y: 0.75),
                    CGPoint(x: 0.84375, y: 0.5625)
                ]
            )
        ]

        for testCase in testCases {
            for (index, result) in testCase.result.enumerated() {
                XCTAssertEqual(
                    result,
                    testCase.expectedValues[index]
                )
            }
        }
    }

    func testGetLinearGradientValues() {
        let begin: CGFloat = 0.0
        let change: CGFloat = 1.0

        let testCases: [(result: [CGFloat], expectedValues: [CGFloat])] = [
            /// If `duration` is `0`
            (
                Interpolator.getLinearInterpolationValues(
                    begin: begin,
                    change: change,
                    duration: 0,
                    addLastPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `0`, the last value is added to the array, so the array count will be `1`.
                [
                    1.0
                ]
            ),
            (
                Interpolator.getLinearInterpolationValues(
                    begin: begin,
                    change: change,
                    duration: 0,
                    addLastPoint: false
                ),
                /// Confirm that the last value is not included.
                [

                ]
            ),
            /// If `duration` is `1`
            (
                Interpolator.getLinearInterpolationValues(
                    begin: begin,
                    change: change,
                    duration: 1,
                    addLastPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `1`, the last value is added to the array, so the array count will be `2`.
                [
                    0.0,
                    1.0
                ]
            ),
            (
                Interpolator.getLinearInterpolationValues(
                    begin: begin,
                    change: change,
                    duration: 1,
                    addLastPoint: false
                ),
                /// Confirm that the last value is not included.
                [
                    0.0
                ]
            ),
            /// If `duration` is `5`
            (
                Interpolator.getLinearInterpolationValues(
                    begin: begin,
                    change: change,
                    duration: 5,
                    addLastPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `5`, the last value is added to the array, so the array count will be `6`.
                [
                    0.0,
                    0.2,
                    0.4,
                    0.6,
                    0.8,
                    1.0
                ]
            ),
            (
                Interpolator.getLinearInterpolationValues(
                    begin: begin,
                    change: change,
                    duration: 5,
                    addLastPoint: false
                ),
                /// Confirm that the last value is not included.
                [
                    0.0,
                    0.2,
                    0.4,
                    0.6,
                    0.8
                ]
            )
        ]

        for testCase in testCases {
            for (index, result) in testCase.result.enumerated() {
                XCTAssertEqual(
                    result,
                    testCase.expectedValues[index]
                )
            }
        }
    }

}
