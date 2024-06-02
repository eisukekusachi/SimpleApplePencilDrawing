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

}
