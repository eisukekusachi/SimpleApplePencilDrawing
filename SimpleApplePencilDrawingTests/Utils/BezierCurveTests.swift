//
//  BezierCurveTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/09/23.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class BezierCurveTests: XCTestCase {
    /// Confirms that appropriate values are returned based on the angles of the three points.
    func testHandleLengthRatioBasedOnRadian() {
        struct Condition {
            let firstPoint: CGPoint
            let secondPoint: CGPoint
            let endPoint: CGPoint
        }
        struct Expectation {
            let result: CGFloat
        }

        let testCases: [(condition: Condition, expectation: Expectation)] = [
            (
                /// When `firstPoint` and `endPoint` overlap, the ratio becomes `0.0`.
                condition: .init(
                    firstPoint: .zero,
                    secondPoint: .init(x: 10, y: 10),
                    endPoint: .zero
                ),
                expectation: .init(
                    result: 0.0
                )
            ),
            (
                /// When `firstPoint`, `secondPoint`, and `endPoint` form a right angle, the ratio becomes `0.5`.
                condition: .init(
                    firstPoint: .init(x: 0, y: 0),
                    secondPoint: .init(x: 10, y: 10),
                    endPoint: .init(x: 20, y: 0)
                ),
                expectation: .init(
                    result: 0.5
                )
            ),
            (
                /// When `firstPoint`, `secondPoint`, and `endPoint` form a right angle, the ratio becomes `0.5`.
                condition: .init(
                    firstPoint: .init(x: 0, y: 0),
                    secondPoint: .init(x: 10, y: 10),
                    endPoint: .init(x: 0, y: 20)
                ),
                expectation: .init(
                    result: 0.5
                )
            ),
            (
                /// When `firstPoint`, `secondPoint`, and `endPoint` are aligned in a straight line, the ratio becomes `1.0`
                condition: .init(
                    firstPoint: .init(x: 0, y: 0),
                    secondPoint: .init(x: 10, y: 10),
                    endPoint: .init(x: 20, y: 20)
                ),
                expectation: .init(
                    result: 1.0
                )
            )
        ]

        for testCase in testCases {
            let condition = testCase.condition
            let expectation = testCase.expectation

            let result = BezierCurve.handleLengthRatioBasedOnRadian(
                pointA: condition.firstPoint,
                pointB: condition.secondPoint,
                pointC: condition.endPoint
            )
            XCTAssertEqual(result, expectation.result, accuracy: 0.0001)
        }
    }

    /// Confirms that the handle positions for the first Bézier curve are returned from the three points.
    func testGetFirstBezierCurveHandlePoints() {
        struct Condition {
            let firstPoint: CGPoint
            let secondPoint: CGPoint
            let endPoint: CGPoint
        }
        struct Expectation {
            let handleA: CGPoint
            let handleB: CGPoint
        }

        let condition: Condition = .init(
            firstPoint: .init(x: 0, y: 0),
            secondPoint: .init(x: 10, y: 10),
            endPoint: .init(x: 20, y: 0)
        )

        /// In this case, `handleLengthRatio` is set to `0.5`, meaning `handleLength` is half the distance between `firstPoint` and `secondPoint`.
        /// `HandleA` is positioned at the midpoint between `firstPoint` and `secondPoint.
        /// `HandleB` is positioned to the left of `secondPoint.x` by a distance of `handleLength`.
        let handleLengthRatio: CGFloat = 0.5
        let handleLength = Calculator.getLength(condition.firstPoint, to: condition.secondPoint) * handleLengthRatio
        let expectation: Expectation = .init(
            handleA: Calculator.getCenterPoint(condition.firstPoint, condition.secondPoint),
            handleB: .init(x: condition.secondPoint.x - handleLength, y: condition.secondPoint.y)
        )

        let result = BezierCurve.getFirstBezierCurveHandlePoints(
            pointA: condition.firstPoint,
            pointB: condition.secondPoint,
            pointC: condition.endPoint,
            handleLengthRatio: handleLengthRatio
        )
        XCTAssertEqual(result.handleA, expectation.handleA)
        XCTAssertEqual(result.handleB, expectation.handleB)
    }

    /// Confirms that the handle positions for the Bézier curve are returned from the four points.
    func testGetBezierCurveIntermediateHandlePoints() {
        struct Condition {
            let previousPoint: CGPoint
            let startPoint: CGPoint
            let endPoint: CGPoint
            let nextPoint: CGPoint
        }
        struct Expectation {
            let handleA: CGPoint
            let handleB: CGPoint
        }

        let points: [CGPoint] = [
            .init(x: 0, y: 0),
            .init(x: 10, y: 10),
            .init(x: 20, y: 0),
            .init(x: 30, y: 10),
            .init(x: 40, y: 0)
        ]

        /// In this case, an array of `CGPoint` is used where the x-coordinates shift positively by `10`, and the y-coordinates alternate in height.
        /// `func getBezierCurveIntermediateHandlePoints` uses four points, with `previousPoint` and `endPoint` at the same height, as well as `startPoint` and `nextPoint`.
        /// Therefore, the expected result is that `handleA` will be `startPoint.x` plus `handleLength`, `handleB` will be `endPoint.x` minus `handleLength`.
        let handleLengthRatio = 0.5
        let handleLength0 = Calculator.getLength(points[1], to: points[2]) * handleLengthRatio
        let handleLength1 = Calculator.getLength(points[2], to: points[3]) * handleLengthRatio
        let testCases: [(condition: Condition, expectation: Expectation)] = [
            (
                condition: .init(
                    previousPoint: points[0],
                    startPoint: points[1],
                    endPoint: points[2],
                    nextPoint: points[3]
                ),
                expectation: .init(
                    handleA: .init(x: points[1].x + handleLength0, y: points[1].y),
                    handleB: .init(x: points[2].x - handleLength0, y: points[2].y)
                )
            ),
            (
                condition: .init(
                    previousPoint: points[1],
                    startPoint: points[2],
                    endPoint: points[3],
                    nextPoint: points[4]
                ),
                expectation: .init(
                    handleA: .init(x: points[2].x + handleLength1, y: points[2].y),
                    handleB: .init(x: points[3].x - handleLength1, y: points[3].y)
                )
            )
        ]

        for testCase in testCases {
            let condition = testCase.condition
            let expectation = testCase.expectation

            let handlePoints = BezierCurve.getBezierCurveIntermediateHandlePoints(
                previousPoint: condition.previousPoint,
                startPoint: condition.startPoint,
                endPoint: condition.endPoint,
                nextPoint: condition.nextPoint,
                handleLengthRatioA: handleLengthRatio,
                handleLengthRatioB: handleLengthRatio
            )

            XCTAssertEqual(handlePoints.handleA, expectation.handleA)
            XCTAssertEqual(handlePoints.handleB, expectation.handleB)
        }
    }

    /// Confirms that the handle positions for the last Bézier curve are returned from the three points.
    func testGetLastBezierCurveHandlePoints() {
        struct Condition {
            let firstPoint: CGPoint
            let secondPoint: CGPoint
            let endPoint: CGPoint
        }
        struct Expectation {
            let handleA: CGPoint
            let handleB: CGPoint
        }

        let condition: Condition = .init(
            firstPoint: .init(x: 0, y: 0),
            secondPoint: .init(x: 10, y: 10),
            endPoint: .init(x: 20, y: 0)
        )

        /// In this case, `handleLengthRatio` is set to `0.5`, meaning `handleLength` is half the distance between `secondPoint` and `endPoint`.
        /// `HandleA` is positioned to the right of `secondPoint.x` by a distance of `handleLength`.
        /// `HandleB` is positioned at the midpoint between `secondPoint` and `endPoint.
        let handleLengthRatio: CGFloat = 0.5
        let handleLength = Calculator.getLength(condition.secondPoint, to: condition.endPoint) * handleLengthRatio
        let expectation: Expectation = .init(
            handleA: .init(x: condition.secondPoint.x + handleLength, y: condition.secondPoint.y),
            handleB: Calculator.getCenterPoint(condition.secondPoint, condition.endPoint)
        )

        let result = BezierCurve.getLastBezierCurveHandlePoints(
            pointA: condition.firstPoint,
            pointB: condition.secondPoint,
            pointC: condition.endPoint,
            handleLengthRatio: handleLengthRatio
        )

        XCTAssertEqual(result.handleA, expectation.handleA)
        XCTAssertEqual(result.handleB, expectation.handleB)
    }

}
