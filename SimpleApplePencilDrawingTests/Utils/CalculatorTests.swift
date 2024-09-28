//
//  CalculatorTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/09/28.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class CalculatorTests: XCTestCase {

    func testGetTotalLength() {
        struct Condition {
            let points: [CGPoint]
        }
        struct Expectation {
            let result: CGFloat
        }

        let expectation = sqrt(pow(50, 2) + pow(50, 2))

        let testCases: [(condition: Condition, expectation: Expectation)] = [
            (
                condition: .init(points: [
                    .zero,
                    .init(x: 50, y: 50),
                ]),
                expectation: .init(
                    result: expectation
                )
            ),
            (
                condition: .init(points: [
                    .zero,
                    .init(x: 10, y: 10),
                    .init(x: 20, y: 20),
                    .init(x: 30, y: 30),
                    .init(x: 40, y: 40),
                    .init(x: 50, y: 50),
                ]),
                expectation: .init(
                    result: expectation
                )
            )
        ]
        for testCase in testCases {
            let condition = testCase.condition
            let expectation = testCase.expectation

            let result = Calculator.getTotalLength(points: condition.points)

            XCTAssertEqual(
                result,
                expectation.result
            )
        }

    }

}
