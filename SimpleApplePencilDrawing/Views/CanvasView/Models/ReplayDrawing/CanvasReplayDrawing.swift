//
//  CanvasReplayDrawing.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/09/21.
//

import Foundation

protocol CanvasDrawingReplayDelegate {
    func sendPointForReplayDrawing(
        touchPoint: CanvasTouchPoint,
        drawingTool: String,
        canvasView: CanvasViewProtocol?
    )
    func finishReplaying()
}

final class CanvasReplayDrawing {

    var delegate: CanvasDrawingReplayDelegate?

    var latestTouchPoint: CanvasTouchPoint?

    private (set) var replayDrawingDataArray: [CanvasReplayDrawingData] = []

    private (set) var replayDrawing: Bool = false
    private (set) var currentPointIndex: Int = 0
    private (set) var currentCurveIndex: Int = 0

    private var curvePointArray: [CanvasTouchPoint] = []

    private var currentCurvePointArray: [CanvasTouchPoint] = []

    private var timer: DispatchSourceTimer? = nil

}


extension CanvasReplayDrawing {
    func hasSufficientTimeElapsedSincePreviousProcess(_ touchPoint: CanvasTouchPoint, allowedDifferenceInSeconds: TimeInterval) -> Bool {
        guard
            let latestTimeStamp = latestTouchPoint?.timestamp
        else { return false }

        return latestTimeStamp.isTimeDifferenceExceeding(
            touchPoint.timestamp,
            allowedDifferenceInSeconds: allowedDifferenceInSeconds
        )
    }

    func appendPointsToCurvePointArray(_ points: [CanvasTouchPoint]) {
        curvePointArray.append(contentsOf: points)
    }

    func appendCurveToArrayAndReadyForNextDrawing() {
        replayDrawingDataArray.append(
            .init(
                drawingTool: "Brush",
                curvePoints: curvePointArray
            )
        )
        curvePointArray = []
    }

}

extension CanvasReplayDrawing {
    func drawCurveWhileReplaying(canvasView: CanvasViewProtocol?) {

        replayDrawing = true
        currentPointIndex = 0
        currentCurveIndex = 0

        let drawingTool = replayDrawingDataArray[currentCurveIndex].drawingTool
        currentCurvePointArray = replayDrawingDataArray[currentCurveIndex].curvePoints

        guard currentPointIndex < currentCurvePointArray.count else {
            finishReplayDrawing()
            return
        }

        self.currentCurveIndex += 1

        timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "array.timer.queue"))
        timer?.schedule(deadline: .now())

        timer?.setEventHandler { [weak self] in
            guard let `self` else { return }

            if self.currentPointIndex < currentCurvePointArray.count {

                let touchPoint = currentCurvePointArray[self.currentPointIndex]

                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.sendPointForReplayDrawing(
                        touchPoint: touchPoint,
                        drawingTool: drawingTool,
                        canvasView: canvasView
                    )
                }

                self.currentPointIndex += 1

                if self.currentPointIndex >= self.currentCurvePointArray.count &&
                    self.currentCurveIndex < self.replayDrawingDataArray.count
                {
                    self.currentCurvePointArray = self.replayDrawingDataArray[self.currentCurveIndex].curvePoints

                    self.currentPointIndex = 0
                    self.currentCurveIndex += 1
                }

                if self.currentPointIndex < currentCurvePointArray.count {
                    // TODO: Assign the difference from the previous timestamp
                    let anyIntervalTime: TimeInterval = 0.005
                    timer?.schedule(deadline: .now() + anyIntervalTime)

                } else {
                    self.finishReplayDrawing()
                }
            }
        }
        timer?.resume()
    }

    func finishReplayDrawing() {
        timer?.cancel()
        timer = nil

        replayDrawing = false
        currentCurveIndex = 0
        currentPointIndex = 0

        latestTouchPoint = nil

        delegate?.finishReplaying()
    }

}
