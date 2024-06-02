//
//  GrayscaleDrawingProtocol.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import Foundation

protocol GrayscaleDrawingProtocol {

    typealias T = GrayscaleDotPoint

    func appendToIterator(_ element: T)
    func appendToIterator(_ elements: [T])

    func makeCurvePointsFromIterator(atEnd: Bool) -> [T]

    func clearIterator()

}
