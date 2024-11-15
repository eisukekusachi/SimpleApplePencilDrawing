//
//  TimeIntervalExtensions.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/08/31.
//

import Foundation

extension TimeInterval {
    /// Checks if the difference between two TimeIntervals exceeds the allowed range
    func isTimeDifferenceExceeding(_ otherInterval: TimeInterval, allowedDifferenceInSeconds: TimeInterval) -> Bool {
        abs(self - otherInterval) >= allowedDifferenceInSeconds
    }

}
