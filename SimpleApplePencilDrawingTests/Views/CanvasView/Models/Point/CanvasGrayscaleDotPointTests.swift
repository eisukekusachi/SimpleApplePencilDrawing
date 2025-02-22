//
//  GrayscaleDotPointTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/10/05.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class GrayscaleDotPointTests: XCTestCase {
    /// Confirm that the average can be calculated
    func testAverage() {
        let result = GrayscaleDotPoint.average(
            .generate(location: .init(x: 1, y: 1), diameter: 1, brightness: 1, blurSize: 1),
            .generate(location: .init(x: 2, y: 2), diameter: 2, brightness: 2, blurSize: 2)
        )
        XCTAssertEqual(
            result,
            .generate(location: .init(x: 1.5, y: 1.5), diameter: 1.5, brightness: 1.5, blurSize: 1.5)
        )
    }

    func testInterpolateAndMatchArraySizes() {
        struct Condition {
            let shouldIncludeEndPoint: Bool
            let targetPoints: [CGPoint]
            let startPoint: GrayscaleDotPoint
            let endPoint: GrayscaleDotPoint
        }
        struct Expectation {
            let result: [GrayscaleDotPoint]
        }

        let testCases: [(condition: Condition, expectation: Expectation)] = [
            (
                /// Interpolate to match `targetPoints`, including `endPoint` values
                condition: .init(
                    shouldIncludeEndPoint: true,
                    targetPoints: [
                        .init(x: 0, y: 0),
                        .init(x: 10, y: 10),
                        .init(x: 20, y: 20),
                        .init(x: 30, y: 30),
                        .init(x: 40, y: 40)
                    ],
                    startPoint: .generate(location: .init(x: 9999, y: 9999), diameter: 0, brightness: 0),
                    endPoint: .generate(location: .init(x: 9999, y: 9999), diameter: 1.0, brightness: 1.0)
                ),
                /// `location` of `startPoint` and `endPoint` are ignored,
                /// and `location` of `targetPoints` is used instead.
                expectation: .init(result: [
                    .generate(location: .init(x: 0, y: 0), diameter: 0.0, brightness: 0.0),
                    .generate(location: .init(x: 10, y: 10), diameter: 0.25, brightness: 0.25),
                    .generate(location: .init(x: 20, y: 20), diameter: 0.5, brightness: 0.5),
                    .generate(location: .init(x: 30, y: 30), diameter: 0.75, brightness: 0.75),
                    .generate(location: .init(x: 40, y: 40), diameter: 1.0, brightness: 1.0)
                ])
            ),
            (
                /// Interpolate to match `targetPoints`, excluding `endPoint` values
                condition: .init(
                    shouldIncludeEndPoint: false,
                    targetPoints: [
                        .init(x: 0, y: 0),
                        .init(x: 10, y: 10),
                        .init(x: 20, y: 20),
                        .init(x: 30, y: 30)
                    ],
                    startPoint: .generate( location: .init(x: 9999, y: 9999), diameter: 0, brightness: 0),
                    endPoint: .generate( location: .init(x: 9999, y: 9999), diameter: 1.0, brightness: 1.0)
                ),
                /// `location` of `startPoint` and `endPoint` are ignored,
                /// and `location` of `targetPoints` is used instead.
                expectation: .init(result: [
                    .generate(location: .init(x: 0, y: 0), diameter: 0.0, brightness: 0.0),
                    .generate(location: .init(x: 10, y: 10), diameter: 0.25, brightness: 0.25),
                    .generate(location: .init(x: 20, y: 20), diameter: 0.5, brightness: 0.5),
                    .generate(location: .init(x: 30, y: 30), diameter: 0.75, brightness: 0.75
                    )
                ])
            )
        ]

        for testCase in testCases {
            let condition = testCase.condition
            let expectation = testCase.expectation

            let result = GrayscaleDotPoint.interpolateToMatchPointCount(
                targetPoints: condition.targetPoints,
                interpolationStart: condition.startPoint,
                interpolationEnd: condition.endPoint,
                shouldIncludeEndPoint: condition.shouldIncludeEndPoint
            )
            XCTAssertEqual(result, expectation.result)
        }
    }

}
