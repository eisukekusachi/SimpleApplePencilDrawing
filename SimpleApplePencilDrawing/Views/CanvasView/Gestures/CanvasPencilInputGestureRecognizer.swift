//
//  CanvasPencilInputGestureRecognizer.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import UIKit

protocol CanvasPencilInputGestureSender {
    func sendPencilTouches(_ touches: Set<UITouch>, with event: UIEvent?, on view: UIView)
}

final class CanvasPencilInputGestureRecognizer: UIGestureRecognizer {

    private var gestureDelegate: CanvasPencilInputGestureSender?

    init(_ view: CanvasPencilInputGestureSender) {
        super.init(target: nil, action: nil)
        allowedTouchTypes = [UITouch.TouchType.pencil.rawValue as NSNumber]

        gestureDelegate = view
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view else { return }
        gestureDelegate?.sendPencilTouches(touches, with: event, on: view)
    }
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view else { return }
        gestureDelegate?.sendPencilTouches(touches, with: event, on: view)
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view else { return }
        gestureDelegate?.sendPencilTouches(touches, with: event, on: view)
    }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let view else { return }
        gestureDelegate?.sendPencilTouches(touches, with: event, on: view)
    }

    // MARK TODO: Use actual values instead of estimates
    override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {

    }

}
