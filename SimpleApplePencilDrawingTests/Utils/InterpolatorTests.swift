//
//  InterpolatorTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/09/22.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class InterpolatorTests: XCTestCase {
    func testMakeCubicCurvePoints() {
        struct Condition {
            let movePoint: CGPoint
            let handlePoint1: CGPoint
            let handlePoint2: CGPoint
            let endPoint: CGPoint
            let duration: Int
            let shouldIncludeEndPoint: Bool
        }
        struct Expectation {
            let results: [CGPoint]
        }

        let testCases: [(condition: Condition, expectation: Expectation)] = [
            /// If `duration` is `0`, `shouldIncludeEndPoint` is `true`
            (
                condition: .init(
                    movePoint: .init(x: 0.0, y: 0.0),
                    handlePoint1: .init(x: 0.0, y: 1.0),
                    handlePoint2: .init(x: 1.0, y: 1.0),
                    endPoint: .init(x: 1.0, y: 0.0),
                    duration: 0,
                    shouldIncludeEndPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `0`, the last value is added to the array, so the array count will be `1`.
                expectation: .init(
                    results: [
                        .init(x: 1.0, y: 0.0)
                    ]
                )
            ),
            /// If `duration` is `0`, `shouldIncludeEndPoint` is `false`
            (
                condition: .init(
                    movePoint: .init(x: 0.0, y: 0.0),
                    handlePoint1: .init(x: 0.0, y: 1.0),
                    handlePoint2: .init(x: 1.0, y: 1.0),
                    endPoint: .init(x: 1.0, y: 0.0),
                    duration: 0,
                    shouldIncludeEndPoint: false
                ),
                /// Confirm that the last value is not included.
                /// If `duration` is `0`, the last value is not added to the array, so the array count will be `0`.
                expectation: .init(
                    results: []
                )
            ),

            /// If `duration` is `1`, `shouldIncludeEndPoint` is `true`
            (
                condition: .init(
                    movePoint: .init(x: 0.0, y: 0.0),
                    handlePoint1: .init(x: 0.0, y: 1.0),
                    handlePoint2: .init(x: 1.0, y: 1.0),
                    endPoint: .init(x: 1.0, y: 0.0),
                    duration: 1,
                    shouldIncludeEndPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `1`, the last value is added to the array, so the array count will be `2`.
                expectation: .init(
                    results: [
                        .init(x: 0.0, y: 0.0),
                        .init(x: 1.0, y: 0.0)
                    ]
                )
            ),
            /// If `duration` is `1`, `shouldIncludeEndPoint` is `false`
            (
                condition: .init(
                    movePoint: .init(x: 0.0, y: 0.0),
                    handlePoint1: .init(x: 0.0, y: 1.0),
                    handlePoint2: .init(x: 1.0, y: 1.0),
                    endPoint: .init(x: 1.0, y: 0.0),
                    duration: 1,
                    shouldIncludeEndPoint: false
                ),
                /// Confirm that the last value is not included.
                /// If `duration` is `1`, the last value is not added to the array, so the array count will be `1`.
                expectation: .init(
                    results: [
                        .init(x: 0.0, y: 0.0)
                    ]
                )
            ),

            /// If `duration` is `4`, `shouldIncludeEndPoint` is `true`
            (
                condition: .init(
                    movePoint: .init(x: 0.0, y: 0.0),
                    handlePoint1: .init(x: 0.0, y: 1.0),
                    handlePoint2: .init(x: 1.0, y: 1.0),
                    endPoint: .init(x: 1.0, y: 0.0),
                    duration: 4,
                    shouldIncludeEndPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `4`, the last value is added to the array, so the array count will be `5`.
                expectation: .init(
                    results: [
                        CGPoint(x: 0.0, y: 0.0),
                        CGPoint(x: 0.15625, y: 0.5625),
                        CGPoint(x: 0.5, y: 0.75),
                        CGPoint(x: 0.84375, y: 0.5625),
                        CGPoint(x: 1.0, y: 0.0)
                    ]
                )
            ),
            /// If `duration` is `4`, `shouldIncludeEndPoint` is `false`
            (
                condition: .init(
                    movePoint: .init(x: 0.0, y: 0.0),
                    handlePoint1: .init(x: 0.0, y: 1.0),
                    handlePoint2: .init(x: 1.0, y: 1.0),
                    endPoint: .init(x: 1.0, y: 0.0),
                    duration: 4,
                    shouldIncludeEndPoint: false
                ),
                /// Confirm that the last value is not included.
                /// If `duration` is `4`, the last value is not added to the array, so the array count will be `4`.
                expectation: .init(
                    results: [
                        CGPoint(x: 0.0, y: 0.0),
                        CGPoint(x: 0.15625, y: 0.5625),
                        CGPoint(x: 0.5, y: 0.75),
                        CGPoint(x: 0.84375, y: 0.5625)
                    ]
                )
            )
        ]

        for testCase in testCases {
            let condition = testCase.condition
            let expectation = testCase.expectation

            let resultPoints = Interpolator.makeCubicCurvePoints(
                movePoint: condition.movePoint,
                controlPoint1: condition.handlePoint1,
                controlPoint2: condition.handlePoint2,
                endPoint: condition.endPoint,
                duration: condition.duration,
                shouldIncludeEndPoint: condition.shouldIncludeEndPoint
            )

            for index in 0 ..< resultPoints.count {
                XCTAssertEqual(
                    resultPoints[index],
                    expectation.results[index]
                )
            }
        }

    }

    func testGetLinearGradientValues() {
        struct Condition {
            let begin: CGFloat
            let change: CGFloat
            let duration: Int
            let shouldIncludeEndPoint: Bool
        }
        struct Expectation {
            let results: [CGFloat]
        }

        let testCases: [(condition: Condition, expectation: Expectation)] = [
            /// If `duration` is `0`, `shouldIncludeEndPoint` is `true`
            (
                condition: .init(
                    begin: 0.0,
                    change: 1.0,
                    duration: 0,
                    shouldIncludeEndPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `0`, the last value is added to the array, so the array count will be `1`.
                expectation: .init(
                    results: [
                        1.0
                    ]
                )
            ),
            /// If `duration` is `0`, `shouldIncludeEndPoint` is `false`
            (
                condition: .init(
                    begin: 0.0,
                    change: 1.0,
                    duration: 0,
                    shouldIncludeEndPoint: false
                ),
                /// Confirm that the last value is not included.
                /// If `duration` is `0`, the last value is not added to the array, so the array count will be `0`.
                expectation: .init(
                    results: []
                )
            ),
            /// If `duration` is `1`, `shouldIncludeEndPoint` is `true`
            (
                condition: .init(
                    begin: 0.0,
                    change: 1.0,
                    duration: 1,
                    shouldIncludeEndPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `1`, the last value is added to the array, so the array count will be `2`.
                expectation: .init(
                    results: [
                        0.0,
                        1.0
                    ]
                )
            ),
            /// If `duration` is `1`, `shouldIncludeEndPoint` is `false`
            (
                condition: .init(
                    begin: 0.0,
                    change: 1.0,
                    duration: 1,
                    shouldIncludeEndPoint: false
                ),
                /// Confirm that the last value is not included.
                /// If `duration` is `1`, the last value is not added to the array, so the array count will be `1`.
                expectation: .init(
                    results: [
                        0.0
                    ]
                )
            ),
            /// If `duration` is `5`, `shouldIncludeEndPoint` is `true`
            (
                condition: .init(
                    begin: 0.0,
                    change: 1.0,
                    duration: 5,
                    shouldIncludeEndPoint: true
                ),
                /// Confirm that the last value is included.
                /// If `duration` is `5`, the last value is added to the array, so the array count will be `6`.
                expectation: .init(
                    results: [
                        0.0,
                        0.2,
                        0.4,
                        0.6,
                        0.8,
                        1.0
                    ]
                )
            ),
            /// If `duration` is `5`, `shouldIncludeEndPoint` is `false`
            (
                condition: .init(
                    begin: 0.0,
                    change: 1.0,
                    duration: 5,
                    shouldIncludeEndPoint: false
                ),
                /// Confirm that the last value is not included.
                /// If `duration` is `5`, the last value is not added to the array, so the array count will be `5`.
                expectation: .init(
                    results: [
                        0.0,
                        0.2,
                        0.4,
                        0.6,
                        0.8
                    ]
                )
            )
        ]

        for testCase in testCases {
            let condition = testCase.condition
            let expectation = testCase.expectation

            let resultPoints = Interpolator.getLinearInterpolationValues(
                begin: condition.begin,
                change: condition.change,
                duration: condition.duration,
                shouldIncludeEndPoint: condition.shouldIncludeEndPoint
            )

            for index in 0 ..< resultPoints.count {
                XCTAssertEqual(
                    resultPoints[index],
                    expectation.results[index],
                    accuracy: 0.000001
                )
            }
        }
    }

}
