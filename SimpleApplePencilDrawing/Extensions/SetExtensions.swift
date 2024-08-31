//
//  SetExtensions.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/08/24.
//

import UIKit

extension Set where Element == UITouch {

    func containsPhases(_ phases: [UITouch.Phase]) -> Bool {
        contains { touch in
            phases.contains(touch.phase)
        }
    }

}
