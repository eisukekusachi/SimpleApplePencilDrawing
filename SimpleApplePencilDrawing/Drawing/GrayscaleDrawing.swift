//
//  GrayscaleDrawing.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import Foundation

final class GrayscaleDrawing: GrayscaleDrawingProtocol {

    let iterator = GrayscaleDrawingIterator()

    func appendToIterator(_ element: T) {
        iterator.append(element)
    }
    func appendToIterator(_ elements: [T]) {
        iterator.append(elements)
    }
    func clearIterator() {
        iterator.clear()
    }

    func makeCurvePointsFromIterator(atEnd isDrawingFinished: Bool) -> [T] {
        iterator.makeCurvePoints(
            isDrawingFinished: isDrawingFinished
        )
    }

}
