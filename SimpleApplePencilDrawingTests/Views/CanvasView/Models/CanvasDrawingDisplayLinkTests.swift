//
//  CanvasDrawingDisplayLinkTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2025/02/20.
//

import XCTest
import Combine
@testable import SimpleApplePencilDrawing

final class CanvasDrawingDisplayLinkTests: XCTestCase {
    var commandBuffer: MTLCommandBuffer!
    let device = MTLCreateSystemDefaultDevice()!

    var cancellables = Set<AnyCancellable>()

    override func setUp() {
        commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!
    }

    /// Confirms that the displayLink is running and `requestDrawingOnCanvasPublisher` emits `Void`
    func testEmitRequestDrawingOnCanvasPublisherWhenTouchingScreen() {
        let subject = CanvasDrawingDisplayLink()

        let publisherExpectation = XCTestExpectation()

        // Confirm that `canvasDrawingPublisher` emits `Void`
        subject.canvasDrawingPublisher
            .sink {
                publisherExpectation.fulfill()
            }
            .store(in: &cancellables)

        subject.updateCanvasWithDrawing(isCurrentlyDrawing: true)

        XCTAssertEqual(subject.displayLink?.isPaused, false)

        wait(for: [publisherExpectation], timeout: 1.0)
    }

    /// Confirms that the displayLink stops and `requestDrawingOnCanvasPublisher` emits `Void` once
    func testEmitRequestDrawingOnCanvasPublisherWhenFingerIsLifted() {
        let subject = CanvasDrawingDisplayLink()

        let publisherExpectation = XCTestExpectation()

        // `canvasDrawingPublisher` emits `Void` to perform the final processing
        subject.canvasDrawingPublisher
            .sink {
                publisherExpectation.fulfill()
            }
            .store(in: &cancellables)

        subject.updateCanvasWithDrawing(isCurrentlyDrawing: false)

        XCTAssertEqual(subject.displayLink?.isPaused, true)

        wait(for: [publisherExpectation], timeout: 1.0)
    }

}
