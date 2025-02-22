//
//  PencilScreenStrokeDataTests.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2025/02/22.
//

import XCTest
@testable import SimpleApplePencilDrawing

final class PencilScreenStrokeDataTests: XCTestCase {

    func testIsPenOffScreen() {
        let subject = PencilScreenStrokeData()

        subject.setLatestEstimatedTouchPoint(
            .generate(phase: .began, estimationUpdateIndex: 0)
        )

        XCTAssertFalse(
            subject.isPenOffScreen(actualTouchPoints: [
                .generate(estimationUpdateIndex: 0)
            ])
        )

        subject.setLatestEstimatedTouchPoint(
            .generate(phase: .moved, estimationUpdateIndex: 1)
        )
        subject.setLatestEstimatedTouchPoint(
            .generate(phase: .moved, estimationUpdateIndex: 2)
        )

        subject.setLatestEstimatedTouchPoint(
            .generate(phase: .ended, estimationUpdateIndex: nil)
        )

        XCTAssertFalse(
            subject.isPenOffScreen(actualTouchPoints: [
                .generate(estimationUpdateIndex: 1)
            ])
        )

        // It becomes true when the `touchPhase` of the latest `estimatedTouchPoint` is ended,
        // and the `estimationUpdateIndex` of `actualTouchPoint` matches the `estimationUpdateIndex` of `estimatedTouchPoint`
        XCTAssertTrue(
            subject.isPenOffScreen(actualTouchPoints: [
                .generate(estimationUpdateIndex: 2)
            ])
        )
    }

    func testLatestTouchPoints() {
        let subject = PencilScreenStrokeData()

        subject.appendActualTouches(actualTouchPoints: [
            .generate(location: .init(x: 0, y: 0), phase: .began, estimationUpdateIndex: 0)
        ])

        XCTAssertEqual(
            subject.latestActualTouchPoints.map { $0.location },
            [
                .init(x: 0, y: 0)
            ]
        )

        // After `latestTouchPoints` is called once, it returns empty.
        XCTAssertEqual(subject.latestActualTouchPoints, [])

        subject.appendActualTouches(actualTouchPoints: [
            .generate(location: .init(x: 1, y: 1), phase: .moved, estimationUpdateIndex: 1),
            .generate(location: .init(x: 2, y: 2), phase: .moved, estimationUpdateIndex: 2)
        ])

        XCTAssertEqual(
            subject.latestActualTouchPoints.map { $0.location },
            [
                .init(x: 1, y: 1),
                .init(x: 2, y: 2)
            ]
        )

        subject.setLatestEstimatedTouchPoint(
            .generate(location: .init(x: 3, y: 3), phase: .moved, estimationUpdateIndex: 3)
        )
        subject.setLatestEstimatedTouchPoint(
            .generate(location: .init(x: 4, y: 4), phase: .ended, estimationUpdateIndex: nil)
        )

        // When values are sent from the Apple Pencil,
        // when the `phase` is `ended`, `estimationUpdateIndex` becomes `nil`,
        // so the previous `estimationUpdateIndex` is retained.
        XCTAssertEqual(subject.latestEstimationUpdateIndex, 3)
        XCTAssertEqual(subject.latestEstimatedTouchPoint?.phase, .ended)

        // Since the phase of `actualTouches` does not become `ended`,
        // the pen is considered to have left
        // when `latestEstimatedTouchPoint?.phase` is `ended`,
        // `latestEstimationUpdateIndex` matches the `estimationUpdateIndex` of `actualTouches`.
        subject.appendActualTouches(actualTouchPoints: [
            .generate(location: .init(x: 3, y: 3), phase: .moved, estimationUpdateIndex: 3)
        ])

        // When the pen leaves the screen,
        // `latestEstimatedTouchPoint` is added to `actualTouchPointArray`,
        // and the drawing termination process is executed.
        XCTAssertEqual(
            subject.latestActualTouchPoints.map { $0.location },
            [
                .init(x: 3, y: 3),
                .init(x: 4, y: 4)
            ]
        )
    }

}
