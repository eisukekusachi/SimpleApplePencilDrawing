//
//  IteratorExtensionsTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/10/13.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class IteratorExtensionsTests: XCTestCase {

    /// Confirms that the three `GrayscaleDotPoint` points needed to generate a first Bézier curve are retrieved from `GrayscaleDotPoint` array.
    func testGetFirstBezierCurvePoints() {
        struct Condition {
            let array: [GrayscaleDotPoint]
        }
        struct Expectation {
            let result: BezierCurveFirstPoints?
        }

        let testCases: [(condition: Condition, expectation: Expectation)] = [
            (
                /// If there are not 3 points, it returns nil.
                condition: .init(array: [
                    .generate(location: .init(x: 0, y: 0)),
                    .generate(location: .init(x: 1, y: 1)),
                ]),
                expectation: .init(result: nil)
            ),
            (
                /// If there are 3 points, it returns the 3 points.
                condition: .init(array: [
                    .generate(location: .init(x: 0, y: 0)),
                    .generate(location: .init(x: 1, y: 1)),
                    .generate(location: .init(x: 2, y: 2))
                ]),
                expectation: .init(result: .init(
                    previousPoint: .generate(location: .init(x: 0, y: 0)),
                    startPoint: .generate(location: .init(x: 1, y: 1)),
                    endPoint: .generate(location: .init(x: 2, y: 2))
                ))
            ),
            (
                /// If there are more than 3 points, it returns the first 3 points from the array.
                condition: .init(array: [
                    .generate(location: .init(x: 0, y: 0)),
                    .generate(location: .init(x: 1, y: 1)),
                    .generate(location: .init(x: 2, y: 2)),
                    .generate(location: .init(x: 3, y: 3)),
                ]),
                expectation: .init(result: .init(
                    previousPoint: .generate(location: .init(x: 0, y: 0)),
                    startPoint: .generate(location: .init(x: 1, y: 1)),
                    endPoint: .generate(location: .init(x: 2, y: 2))
                ))
            )
        ]

        for testCase in testCases {
            let condition = testCase.condition
            let expectation = testCase.expectation

            let iterator = Iterator<GrayscaleDotPoint>()
            iterator.append(condition.array)

            let result = iterator.getBezierCurveFirstPoints()

            if let result, let expectation = expectation.result {
                XCTAssertEqual(
                    [
                        result.previousPoint,
                        result.startPoint,
                        result.endPoint
                    ],
                    [
                        expectation.previousPoint,
                        expectation.startPoint,
                        expectation.endPoint
                    ]
                )
            } else {
                XCTAssertNil(result)
            }
        }
    }

    /// Confirms that the four `GrayscaleDotPoint` points needed to generate the Bézier curve are retrieved from `GrayscaleDotPoint` array.
    func testGetIntermediateBezierCurvePointsWithFixedRange4() {
        struct Condition {
            let array: [GrayscaleDotPoint]
        }
        struct Expectation {
            let result: [BezierCurveIntermediatePoints]
        }

        let testCases: [(condition: Condition, expectation: Expectation)] = [
            (
                /// If there are not 4 points, it returns [].
                condition: .init(array: [
                    .generate(location: .init(x: 0, y: 0)),
                    .generate(location: .init(x: 1, y: 1)),
                    .generate(location: .init(x: 2, y: 2)),
                ]),
                expectation: .init(result: [])
            ),
            (
                /// If there are 4 points, it returns the 4 points.
                condition: .init(array: [
                    .generate(location: .init(x: 0, y: 0)),
                    .generate(location: .init(x: 1, y: 1)),
                    .generate(location: .init(x: 2, y: 2)),
                    .generate(location: .init(x: 3, y: 3))
                ]),
                expectation: .init(result: [
                    .init(
                        previousPoint: .generate(location: .init(x: 0, y: 0)),
                        startPoint: .generate(location: .init(x: 1, y: 1)),
                        endPoint: .generate(location: .init(x: 2, y: 2)),
                        nextPoint: .generate(location: .init(x: 3, y: 3))
                    )
                ])
            ),
            (
                /// If there are more than 4 points, it returns an array of 4 points, shifting by one each step.
                /// The curve is drawn between `startPoint` and `endPoint`.
                /// As the points shift by one, a connected curve is drawn.
                condition: .init(array: [
                    .generate(location: .init(x: 0, y: 0)),
                    .generate(location: .init(x: 1, y: 1)),
                    .generate(location: .init(x: 2, y: 2)),
                    .generate(location: .init(x: 3, y: 3)),
                    .generate(location: .init(x: 4, y: 4)),
                    .generate(location: .init(x: 5, y: 5))
                ]),
                expectation: .init(result: [
                    .init(
                        previousPoint: .generate(location: .init(x: 0, y: 0)),
                        startPoint: .generate(location: .init(x: 1, y: 1)),
                        endPoint: .generate(location: .init(x: 2, y: 2)),
                        nextPoint: .generate(location: .init(x: 3, y: 3))
                    ),
                    .init(
                        previousPoint: .generate(location: .init(x: 1, y: 1)),
                        startPoint: .generate(location: .init(x: 2, y: 2)),
                        endPoint: .generate(location: .init(x: 3, y: 3)),
                        nextPoint: .generate(location: .init(x: 4, y: 4))
                    ),
                    .init(
                        previousPoint: .generate(location: .init(x: 2, y: 2)),
                        startPoint: .generate(location: .init(x: 3, y: 3)),
                        endPoint: .generate(location: .init(x: 4, y: 4)),
                        nextPoint: .generate(location: .init(x: 5, y: 5))
                    )
                ])
            )
        ]

        for testCase in testCases {
            let condition = testCase.condition
            let expectation = testCase.expectation

            let iterator = Iterator<GrayscaleDotPoint>()
            iterator.append(condition.array)

            let resultArray = iterator.getBezierCurveIntermediatePointsWithFixedRange4()
            let expectationArray = expectation.result

            XCTAssertEqual(resultArray.count, expectationArray.count)

            for i in 0 ..< resultArray.count {
                let result = resultArray[i]
                let expectation = expectationArray[i]
                XCTAssertEqual(
                    [
                        result.previousPoint,
                        result.startPoint,
                        result.endPoint,
                        result.nextPoint
                    ],
                    [
                        expectation.previousPoint,
                        expectation.startPoint,
                        expectation.endPoint,
                        expectation.nextPoint
                    ]
                )
            }
        }
    }

    /// Confirms that the three `GrayscaleDotPoint` points needed to generate a last Bézier curve are retrieved from  `GrayscaleDotPoint` array.
    func testGetLastBezierCurvePoints() {
        struct Condition {
            let array: [GrayscaleDotPoint]
        }
        struct Expectation {
            let result: BezierCurveLastPoints?
        }

        let testCases: [(condition: Condition, expectation: Expectation)] = [
            (
                /// If there are not 3 points, it returns nil.
                condition: .init(array: [
                    .generate(location: .init(x: 0, y: 0)),
                    .generate(location: .init(x: 1, y: 1)),
                ]),
                expectation: .init(result: nil)
            ),
            (
                /// If there are 3 points, it returns the 3 points.
                condition: .init(array: [
                    .generate(location: .init(x: 0, y: 0)),
                    .generate(location: .init(x: 1, y: 1)),
                    .generate(location: .init(x: 2, y: 2))
                ]),
                expectation: .init(result: .init(
                    previousPoint: .generate(location: .init(x: 0, y: 0)),
                    startPoint: .generate(location: .init(x: 1, y: 1)),
                    endPoint: .generate(location: .init(x: 2, y: 2))
                ))
            ),
            (
                /// If there are more than 3 points, it returns the last 3 points from the array.
                condition: .init(array: [
                    .generate(location: .init(x: 0, y: 0)),
                    .generate(location: .init(x: 1, y: 1)),
                    .generate(location: .init(x: 2, y: 2)),
                    .generate(location: .init(x: 3, y: 3)),
                ]),
                expectation: .init(result: .init(
                    previousPoint: .generate(location: .init(x: 1, y: 1)),
                    startPoint: .generate(location: .init(x: 2, y: 2)),
                    endPoint: .generate(location: .init(x: 3, y: 3))
                ))
            )
        ]

        for testCase in testCases {
            let condition = testCase.condition
            let expectation = testCase.expectation

            let iterator = Iterator<GrayscaleDotPoint>()
            iterator.append(condition.array)

            let result = iterator.getBezierCurveLastPoints()

            if let result, let expectation = expectation.result {
                XCTAssertEqual(
                    [
                        result.previousPoint,
                        result.startPoint,
                        result.endPoint
                    ],
                    [
                        expectation.previousPoint,
                        expectation.startPoint,
                        expectation.endPoint
                    ]
                )
            } else {
                XCTAssertNil(result)
            }
        }
    }

}
