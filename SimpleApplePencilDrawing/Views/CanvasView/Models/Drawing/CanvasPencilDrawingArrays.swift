//
//  CanvasPencilDrawingArrays.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/08/31.
//

import UIKit
/// https://developer.apple.com/documentation/uikit/apple_pencil_interactions/handling_input_from_apple_pencil/
/// Since an Apple Pencil is a separate device from an iPad,
/// `UIGestureRecognizer` initially sends estimated values and then sends the actual values shortly after.
///  This class is a model that combines estimated and actual values to create an array of `CanvasTouchPoint`.
///  It stores the estimated values in `estimatedTouchPointArray` and then combines them with the actual values received later
///  to create the values for `actualTouchPointArray`.
final class CanvasPencilDrawingArrays {

    /// An array that holds elements combining actualTouches, where the force values are accurate, and estimatedTouchPointArray.
    private (set) var actualTouchPointArray: [CanvasTouchPoint] = []

    /// An array that holds estimated values where the TouchPhase values are accurate.
    private (set) var estimatedTouchPointArray: [CanvasTouchPoint] = []

    /// An `estimationUpdateIndex` to determine whether the drawing has completed
    private (set) var lastEstimationUpdateIndex: NSNumber? = nil

    /// An element processed in `actualTouchPointArray`
    private var latestActualTouchPoint: CanvasTouchPoint? = nil

    /// An index of the processed elements in `estimatedTouchPointArray`
    private var latestEstimatedTouchArrayIndex = 0

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

extension CanvasPencilDrawingArrays {

    var isEstimatedTouchPointArrayCreationComplete: Bool {
        [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(estimatedTouchPointArray.last?.phase)
    }

    var isActualTouchPointArrayCreationComplete: Bool {
        actualTouchPointArray.last?.estimationUpdateIndex == lastEstimationUpdateIndex
    }

    /// Use the elements of `actualTouchPointArray` after `latestActualTouchPoint` for line drawing
    var latestActualTouchPoints: [CanvasTouchPoint] {
        actualTouchPointArray.elements(after: latestActualTouchPoint) ?? actualTouchPointArray
    }

    func appendEstimatedValue(_ touchPoint: CanvasTouchPoint) {
        estimatedTouchPointArray.append(touchPoint)

        if isEstimatedTouchPointArrayCreationComplete {
            setSecondLastEstimationUpdateIndex()
        }
    }

    /// Combine `actualTouches` with the estimated values to create elements and append them to `actualTouchPointArray`
    func appendActualValueWithEstimatedValue(_ actualTouch: UITouch) {
        for i in latestEstimatedTouchArrayIndex ..< estimatedTouchPointArray.count {
            let estimatedTouchPoint = estimatedTouchPointArray[i]

            // Find the one that matches `estimationUpdateIndex`
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

    func appendLastEstimatedValueIfProcessCompleted() {
        if isActualTouchPointArrayCreationComplete {
            appendLastEstimatedTouchPointToActualTouchPointArray()
        }
    }

    /// Add an element with `UITouch.Phase.ended` to the end of `actualTouchPointArray`
    func appendLastEstimatedTouchPointToActualTouchPointArray() {
        guard let point = estimatedTouchPointArray.last else { return }
        actualTouchPointArray.append(point)
    }

    /// After using the array, update `latestActualTouchPoint` with the last element of `actualTouchPointArray` and use it for the next drawing.
    func updateLatestActualTouchPoint() {
        latestActualTouchPoint = actualTouchPointArray.last
    }

    // When drawing ends with Apple Pencil, the `estimationUpdateIndex` of `UITouch` becomes nil,
    // so the `estimationUpdateIndex` from the previous `UITouch` is retained.
    func setSecondLastEstimationUpdateIndex() {
        lastEstimationUpdateIndex = estimatedTouchPointArray.dropLast().last?.estimationUpdateIndex
    }

    func reset() {
        actualTouchPointArray = []
        estimatedTouchPointArray = []
        latestEstimatedTouchArrayIndex = 0
        latestActualTouchPoint = nil
        lastEstimationUpdateIndex = nil
    }

}
