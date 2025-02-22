//
//  CanvasDrawingTextureSetTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2025/02/22.
//

import XCTest
import Combine
@testable import SimpleApplePencilDrawing

final class CanvasDrawingTextureSetTests: XCTestCase {

    var subject: CanvasDrawingTextureSet!

    var commandBuffer: MTLCommandBuffer!
    let device = MTLCreateSystemDefaultDevice()!

    var backgroundTexture: MTLTexture!
    var destinationTexture: MTLTexture!

    var renderer = MockMTLRenderer()

    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!
        commandBuffer.label = "commandBuffer"

        subject = CanvasDrawingTextureSet(renderer: renderer)
        subject.initTextures(.init(width: 1, height: 1))
        renderer.callHistory.removeAll()

        backgroundTexture = MTLTextureCreator.makeBlankTexture(
            size: .init(width: MTLRenderer.threadGroupLength, height: MTLRenderer.threadGroupLength),
            with: device
        )!
        backgroundTexture.label = "backgroundTexture"

        destinationTexture = MTLTextureCreator.makeBlankTexture(
            size: .init(width: MTLRenderer.threadGroupLength, height: MTLRenderer.threadGroupLength),
            with: device
        )!
        destinationTexture.label = "destinationTexture"
    }

    func testDrawCurvePoints() {
        struct Condition: Hashable {
            let touchPhase: UITouch.Phase
        }
        struct Expectation {
            let result: [String]
            let isDrawingFinished: Bool
        }

        // Draw the point buffers in opaque grayscale with the max blend mode on grayscaleTexture.
        // Draw the color-applied `grayscaleTexture` on `drawingTexture`.
        let drawingCurve: [String] = [
        "drawGrayPointBuffersWithMaxBlendMode(buffers: buffers, onGrayscaleTexture: grayscaleTexture, with: commandBuffer)",
        "drawTexture(grayscaleTexture: grayscaleTexture, color: (0, 0, 0), on: drawingTexture, with: commandBuffer)"
        ]

        // `backgroundTexture` and `drawingTexture` are layered and drawn on `destinationTexture`.
        let drawingTexture: [String] = [
        "drawTexture(texture: backgroundTexture, buffers: buffers, withBackgroundColor: (255, 255, 255, 255), on: destinationTexture, with: commandBuffer)",
        "mergeTexture(texture: drawingTexture, into: destinationTexture, with: commandBuffer)"
        ]

        // Merge `drawingTexture` on `backgroundTexture`.
        // Clear the textures used for drawing to prepare for the next drawing.
        let drawingCompletionProcess: [String] = [
        "mergeTexture(texture: drawingTexture, into: backgroundTexture, with: commandBuffer)",
        "clearTextures(textures: [drawingTexture, grayscaleTexture], with: commandBuffer)"
        ]

        let testCases: [Condition: Expectation] = [
            .init(touchPhase: .began): .init(result: drawingCurve + drawingTexture, isDrawingFinished: false),
            .init(touchPhase: .moved): .init(result: drawingCurve + drawingTexture, isDrawingFinished: false),
            .init(touchPhase: .ended): .init(result: drawingCurve + drawingTexture + drawingCompletionProcess, isDrawingFinished: true),
            .init(touchPhase: .cancelled): .init(result: drawingCurve + drawingTexture + drawingCompletionProcess, isDrawingFinished: true)
        ]

        testCases.forEach { testCase in
            let drawingCurveIterator = DrawingCurveIterator()
            drawingCurveIterator.append(points: [], touchPhase: testCase.key.touchPhase)

            let publisherExpectation = XCTestExpectation()
            if !testCase.value.isDrawingFinished {
                publisherExpectation.isInverted = true
            }

            // Confirm that `canvasDrawFinishedPublisher` emits `Void` at the end of the drawing process
            subject.canvasDrawFinishedPublisher
                .sink {
                    publisherExpectation.fulfill()
                }
                .store(in: &cancellables)

            subject.drawCurvePoints(
                drawingCurveIterator: drawingCurveIterator,
                withBackgroundTexture: backgroundTexture,
                withBackgroundColor: .white,
                on: destinationTexture,
                with: commandBuffer
            )

            XCTAssertEqual(renderer.callHistory, testCase.value.result)
            renderer.callHistory.removeAll()

            wait(for: [publisherExpectation], timeout: 1.0)
        }
    }

}
