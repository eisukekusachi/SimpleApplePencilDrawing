//
//  CanvasPencilScreenTouch.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2025/02/22.
//

import UIKit

/// A class that manages the pen position information sent from the Apple Pencil
final class CanvasPencilScreenTouch {

    /// An array that stores real values.
    /// https://developer.apple.com/documentation/uikit/apple_pencil_interactions/handling_input_from_apple_pencil/
    /// The values sent from the Apple Pencil include both estimated values and real values, but only the real values are used.
    private(set) var actualTouchPointArray: [CanvasTouchPoint] = []

    /// A variable that stores the latest real value, used to retrieve the latest values array from `actualTouchPointArray`
    private(set) var latestActualTouchPoint: CanvasTouchPoint?

    /// A variable that stores the latest estimated value, used for determining touch end
    private(set) var latestEstimatedTouchPoint: CanvasTouchPoint?

    /// A variable that stores the latest estimationUpdateIndex, used for determining touch end
    private(set) var latestEstimationUpdateIndex: NSNumber?

    init(
        actualTouchPointArray: [CanvasTouchPoint] = [],
        latestEstimatedTouchPoint: CanvasTouchPoint? = nil,
        latestActualTouchPoint: CanvasTouchPoint? = nil
    ) {
        self.actualTouchPointArray = actualTouchPointArray.sorted { $0.timestamp < $1.timestamp }
        self.latestEstimatedTouchPoint = latestEstimatedTouchPoint
        self.latestActualTouchPoint = latestActualTouchPoint
    }

}

extension CanvasPencilScreenTouch {

    /// Uses the elements of `actualTouchPointArray` after `latestActualTouchPoint` for line drawing.
    var latestActualTouchPoints: [CanvasTouchPoint] {
        let touchPoints = actualTouchPointArray.elements(after: latestActualTouchPoint) ?? actualTouchPointArray
        latestActualTouchPoint = actualTouchPointArray.last
        return touchPoints
    }

    func isPenOffScreen(actualTouches: [CanvasTouchPoint]) -> Bool {
        UITouch.isTouchCompleted(latestEstimatedTouchPoint?.phase ?? .cancelled) &&
        actualTouches.contains(where: { $0.estimationUpdateIndex == latestEstimationUpdateIndex })
    }

    func setLatestEstimatedTouchPoint(_ estimatedTouchPoint: CanvasTouchPoint?) {
        latestEstimatedTouchPoint = estimatedTouchPoint

        if let estimationUpdateIndex = estimatedTouchPoint?.estimationUpdateIndex {
            latestEstimationUpdateIndex = estimationUpdateIndex
        }
    }

    func appendActualTouches(actualTouches: [CanvasTouchPoint]) {
        actualTouchPointArray.append(contentsOf: actualTouches)

        if isPenOffScreen(actualTouches: actualTouches),
           let latestEstimatedTouchPoint {
            self.actualTouchPointArray.append(latestEstimatedTouchPoint)
        }
    }

    func reset() {
        actualTouchPointArray = []
        latestActualTouchPoint = nil
        latestEstimatedTouchPoint = nil
        latestEstimationUpdateIndex = nil
    }

}
