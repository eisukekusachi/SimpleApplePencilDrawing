//
//  CanvasTouchPoint.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import UIKit

struct CanvasTouchPoint: Equatable {

    let location: CGPoint
    let force: CGFloat
    let maximumPossibleForce: CGFloat
    let phase: UITouch.Phase
    /// Index for identifying the estimated value
    var estimationUpdateIndex: NSNumber? = nil
}

extension CanvasTouchPoint {

    init(
        touch: UITouch,
        view: UIView
    ) {
        self.location = touch.preciseLocation(in: view)
        self.force = touch.force
        self.maximumPossibleForce = touch.maximumPossibleForce
        self.phase = touch.phase
        self.estimationUpdateIndex = touch.estimationUpdateIndex
    }

    func convertToTextureCoordinates(
        frameSize: CGSize,
        renderTextureSize: CGSize,
        drawableSize: CGSize
    ) -> Self {

        var locationOnDrawable: CGPoint = self.location
        locationOnDrawable = location.scale(frameSize, to: drawableSize)

        var locationOnTexture = locationOnDrawable

        if renderTextureSize != drawableSize {
            let widthRatio = renderTextureSize.width / drawableSize.width
            let heightRatio = renderTextureSize.height / drawableSize.height

            if widthRatio > heightRatio {
                locationOnTexture = .init(
                    x: locationOnDrawable.x * widthRatio + (renderTextureSize.width - drawableSize.width * widthRatio) * 0.5,
                    y: locationOnDrawable.y * widthRatio + (renderTextureSize.height - drawableSize.height * widthRatio) * 0.5
                )
            } else {
                locationOnTexture = .init(
                    x: locationOnDrawable.x * heightRatio + (renderTextureSize.width - drawableSize.width * heightRatio) * 0.5,
                    y: locationOnDrawable.y * heightRatio + (renderTextureSize.height - drawableSize.height * heightRatio) * 0.5
                )
            }
        }

        return .init(
            location: locationOnTexture,
            force: force,
            maximumPossibleForce: maximumPossibleForce,
            phase: phase,
            estimationUpdateIndex: estimationUpdateIndex
        )
    }

}

extension Array where Element == CanvasTouchPoint {

    var currentTouchPhase: UITouch.Phase {
        if self.last?.phase == .cancelled {
            .cancelled
        } else if self.last?.phase == .ended {
            .ended
        } else if self.first?.phase == .began {
            .began
        } else {
            .moved
        }
    }

}