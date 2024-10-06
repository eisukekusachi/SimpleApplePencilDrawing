//
//  CanvasGrayscaleDotPointTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/10/05.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class CanvasGrayscaleDotPointTests: XCTestCase {
    /// Confirm that the average can be calculated
    func testAverage() {
        let result = CanvasGrayscaleDotPoint.average(
            .generate(location: .init(x: 1, y: 1), diameter: 1, brightness: 1, blurSize: 1),
            .generate(location: .init(x: 2, y: 2), diameter: 2, brightness: 2, blurSize: 2)
        )
        XCTAssertEqual(
            result,
            .generate(location: .init(x: 1.5, y: 1.5), diameter: 1.5, brightness: 1.5, blurSize: 1.5)
        )
    }

}
