//
//  UITouchExtensions.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2025/02/22.
//

import UIKit

extension UITouch {

    static func isTouchCompleted(_ touchPhase: UITouch.Phase) -> Bool {
        [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(touchPhase)
    }

}
