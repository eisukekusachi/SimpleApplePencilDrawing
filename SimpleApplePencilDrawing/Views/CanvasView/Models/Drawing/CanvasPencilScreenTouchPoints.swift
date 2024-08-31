//
//  CanvasPencilScreenTouchPoints.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/08/31.
//

import UIKit
/// Since Apple Pencil is a separate device from iPad,
/// UIKit returns estimated values first, followed by the actual values after a short delay within touch events.
/// In this class, estimated values are stored in `estimatedTouchPointArray`.
/// When the actual values are received, they are combined with the estimated values to create accurate elements,
/// which are then stored in `actualTouchPointArray`.
final class CanvasPencilScreenTouchPoints {

    /// An array that holds elements combining actualTouches, where the force values are accurate, and estimatedTouchPointArray.
    private (set) var actualTouchPointArray: [CanvasTouchPoint] = []

    /// An array that holds estimated values where the TouchPhase values are accurate.
    private (set) var estimatedTouchPointArray: [CanvasTouchPoint] = []

    /// An index of the processed elements in `estimatedTouchPointArray`
    private (set) var latestEstimatedTouchArrayIndex = 0

    /// An element processed in `actualTouchPointArray`
    private (set) var latestActualTouchPoint: CanvasTouchPoint? = nil

    private var lastEstimationUpdateIndex: NSNumber?

    init(
        actualTouchPointArray: [CanvasTouchPoint] = [],
        estimatedTouchPointArray: [CanvasTouchPoint] = [],
        latestEstimatedTouchArrayIndex: Int = 0,
        latestActualTouchPoint: CanvasTouchPoint? = nil
    ) {
        self.actualTouchPointArray = actualTouchPointArray
        self.estimatedTouchPointArray = estimatedTouchPointArray
        self.latestEstimatedTouchArrayIndex = latestEstimatedTouchArrayIndex
        self.latestActualTouchPoint = latestActualTouchPoint
    }

}

extension CanvasPencilScreenTouchPoints {

    /// Use the elements of `actualTouchPointArray` after `startAfterActualTouchPoint` for line drawing.
    /// After using the array, update `startAfterActualTouchPoint` with the last element of `actualTouchPointArray` and use it for the next drawing.
    var latestActualTouchPoints: [CanvasTouchPoint] {
        actualTouchPointArray.elements(after: latestActualTouchPoint) ?? actualTouchPointArray
    }

    var hasDrawingFinished: Bool {
        [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(actualTouchPointArray.currentTouchPhase)
    }
    var hasActualValueReplacementCompleted: Bool {
        actualTouchPointArray.last?.estimationUpdateIndex == lastEstimationUpdateIndex
    }

    /// Checks if the time difference between when the end of the line was drawn
    /// and when the latest point was created is within the allowed difference in seconds
    func hasSufficientTimeElapsedSincePreviousProcess(allowedDifferenceInSeconds seconds: TimeInterval) -> Bool {
        guard
            let latestActualTouchPointTimestamp = actualTouchPointArray.last?.timestamp
        else { return false }

        if let endLineTimestamp = latestActualTouchPoint?.timestamp {
            return endLineTimestamp.isTimeDifferenceExceeding(latestActualTouchPointTimestamp, allowedDifferenceInSeconds: seconds)
        } else {
            return true
        }
    }

    func appendEstimatedValue(_ touchPoint: CanvasTouchPoint) {
        estimatedTouchPointArray.append(touchPoint)

        // When the touch ends, the `estimationUpdateIndex` of UITouch becomes nil,
        // so the `estimationUpdateIndex` of the previous UITouch is retained.
        if [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(estimatedTouchPointArray.last?.phase) {
            lastEstimationUpdateIndex = estimatedTouchPointArray.dropLast().last?.estimationUpdateIndex
        }
    }

    /// Combine `actualTouches` with the estimated values to create elements and append them to `actualTouchPointArray`
    func appendActualValueWithEstimatedValue(_ actualTouch: UITouch) {
        for i in latestEstimatedTouchArrayIndex ..< estimatedTouchPointArray.count {
            let estimatedTouchPoint = estimatedTouchPointArray[i]

            // Find the one that matches `latestEstimatedTouchArrayIndex`
            if actualTouch.estimationUpdateIndex == estimatedTouchPoint.estimationUpdateIndex,
               ![UITouch.Phase.ended, UITouch.Phase.cancelled].contains(estimatedTouchPoint.phase) {

                actualTouchPointArray.append(
                    .init(
                        location: estimatedTouchPoint.location,
                        phase: estimatedTouchPoint.phase,
                        force: actualTouch.force,
                        maximumPossibleForce: actualTouch.maximumPossibleForce,
                        estimationUpdateIndex: actualTouch.estimationUpdateIndex,
                        timestamp: actualTouch.timestamp
                    )
                )

                latestEstimatedTouchArrayIndex = i
            }
        }
    }

    /// Add an element with `UITouch.Phase.ended` to the end of `actualTouchPointArray`
    /// since `UITouchPhase.ended` is not included in actual values.
    func appendLastEstimatedTouchPointToActualTouchPointArray() {
        guard let point = estimatedTouchPointArray.last else { return }
        actualTouchPointArray.append(point)
    }

    func updateLatestActualTouchPoint() {
        latestActualTouchPoint = actualTouchPointArray.last
    }

    func reset() {
        actualTouchPointArray = []
        estimatedTouchPointArray = []
        latestEstimatedTouchArrayIndex = 0
        latestActualTouchPoint = nil
        lastEstimationUpdateIndex = nil
    }

}
