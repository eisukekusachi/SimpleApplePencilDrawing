//
//  CanvasTouchPointDummy.swift
//  SimpleApplePencilDrawingTests
//
//  Created by Eisuke Kusachi on 2024/08/31.
//

import UIKit
@testable import SimpleApplePencilDrawing

extension CanvasTouchPoint {

    static func generate(
        location: CGPoint = .zero,
        phase: UITouch.Phase = .cancelled,
        force: CGFloat = 0,
        maximumPossibleForce: CGFloat = 0,
        estimationUpdateIndex: NSNumber? = nil,
        timestamp: TimeInterval = 0
    ) -> CanvasTouchPoint {
        .init(
            location: location,
            phase: phase,
            force: force,
            maximumPossibleForce: maximumPossibleForce,
            estimationUpdateIndex: estimationUpdateIndex,
            timestamp: timestamp
        )
    }

}
