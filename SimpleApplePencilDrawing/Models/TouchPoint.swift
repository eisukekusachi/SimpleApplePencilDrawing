//
//  TouchPoint.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import UIKit

struct TouchPoint: Equatable {

    let location: CGPoint
    let force: CGFloat
    let maximumPossibleForce: CGFloat
    let phase: UITouch.Phase
    let frameSize: CGSize

    init(
        location: CGPoint,
        force: CGFloat,
        maximumPossibleForce: CGFloat,
        phase: UITouch.Phase,
        frameSize: CGSize
    ) {
        self.location = location
        self.force = force
        self.maximumPossibleForce = maximumPossibleForce
        self.phase = phase
        self.frameSize = frameSize
    }

    init(
        touch: UITouch,
        view: UIView
    ) {
        self.location = touch.preciseLocation(in: view)
        self.force = touch.force
        self.maximumPossibleForce = touch.maximumPossibleForce
        self.phase = touch.phase
        self.frameSize = view.frame.size
    }

    func getScaledTouchPoint(
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
            frameSize: frameSize
        )
    }

}

extension Array where Element == TouchPoint {

    var phase: UITouch.Phase {
        guard !isEmpty else { return .cancelled }

        for touch in self {
            switch touch.phase {
            case .cancelled:
                return .cancelled
            case .ended:
                return .ended
            case .began:
                return .began
            default:
                continue
            }
        }

        return .moved
    }

}
