//
//  ViewSize.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import Foundation

enum ViewSize {

    static func getScaleToFit(_ source: CGSize, to destination: CGSize) -> CGFloat {

        let ratioWidth = destination.width / source.width
        let ratioHeight = destination.height / source.height

        return ratioWidth < ratioHeight ? ratioWidth : ratioHeight
    }

}
