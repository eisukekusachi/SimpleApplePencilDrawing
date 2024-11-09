//
//  MTLTextureNodes.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/11/09.
//

import Foundation

struct MTLTextureNodes {
    var vertices: MTLTextureVertices = MTLTextureVertices()
    var textureCoord: MTLTextureCoordinates = .screenTextureCoordinates
    var indices: MTLTextureIndices = MTLTextureIndices()
}

extension MTLTextureNodes {

    static let textureNodes: MTLTextureNodes = .init()

    static let flippedTextureNodes: MTLTextureNodes = .init(
        vertices: MTLTextureVertices(),
        textureCoord: .cartesianTextureCoordinates,
        indices: MTLTextureIndices()
    )

}

struct MTLTextureVertices {
    var LT: CGPoint = .init(x: -1.0, y: -1.0)
    var RT: CGPoint = .init(x:  1.0, y: -1.0)
    var RB: CGPoint = .init(x:  1.0, y:  1.0)
    var LB: CGPoint = .init(x: -1.0, y:  1.0)

    func getValues() -> [Float] {
        [
            Float(LB.x), Float(LB.y),
            Float(RB.x), Float(RB.y),
            Float(RT.x), Float(RT.y),
            Float(LT.x), Float(LT.y)
        ]
    }

    static func makeCenterAlignedTextureVertices(
        sourceSize: CGSize,
        destinationSize: CGSize
    ) -> Self {
        var leftTop: CGPoint = .init(
            x: destinationSize.width * 0.5 + sourceSize.width * 0.5 * -1,
            y: destinationSize.height * 0.5 + sourceSize.height * 0.5 * -1
        )
        var rightTop: CGPoint = .init(
            x: destinationSize.width * 0.5 + sourceSize.width * 0.5 * 1,
            y: destinationSize.height * 0.5 + sourceSize.height * 0.5 * -1
        )
        var rightBottom: CGPoint = .init(
            x: destinationSize.width * 0.5 + sourceSize.width * 0.5 * 1,
            y: destinationSize.height * 0.5 + sourceSize.height * 0.5 * 1
        )
        var leftBottom: CGPoint = .init(
            x: destinationSize.width * 0.5 + sourceSize.width * 0.5 * -1,
            y: destinationSize.height * 0.5 + sourceSize.height * 0.5 * 1
        )

        return .init(
            LT: .init(
                x: (leftTop.x / destinationSize.width) * 2.0 - 1.0,
                y: (leftTop.y / destinationSize.height) * 2.0 - 1.0
            ),
            RT: .init(
                x: (rightTop.x / destinationSize.width) * 2.0 - 1.0,
                y: (rightTop.y / destinationSize.height) * 2.0 - 1.0
            ),
            RB: .init(
                x: (rightBottom.x / destinationSize.width) * 2.0 - 1.0,
                y: (rightBottom.y / destinationSize.height) * 2.0 - 1.0
            ),
            LB: .init(
                x: (leftBottom.x / destinationSize.width) * 2.0 - 1.0,
                y: (leftBottom.y / destinationSize.height) * 2.0 - 1.0
            )
        )
    }

    static func makeTextureVertices(
        sourceFrame: CGRect,
        destinationSize: CGSize
    ) -> Self {
        .init(
            LT: .init(
                x: (sourceFrame.origin.x / destinationSize.width) * 2.0 - 1.0,
                y: (sourceFrame.origin.y / destinationSize.height) * 2.0 - 1.0
            ),
            RT: .init(
                x: ((sourceFrame.origin.x + sourceFrame.size.width) / destinationSize.width) * 2.0 - 1.0,
                y: (sourceFrame.origin.y / destinationSize.height) * 2.0 - 1.0
            ),
            RB: .init(
                x: ((sourceFrame.origin.x + sourceFrame.size.width) / destinationSize.width) * 2.0 - 1.0,
                y: ((sourceFrame.origin.y + sourceFrame.size.height) / destinationSize.height) * 2.0 - 1.0
            ),
            LB: .init(
                x: (sourceFrame.origin.x / destinationSize.width) * 2.0 - 1.0,
                y: ((sourceFrame.origin.y + sourceFrame.size.height) / destinationSize.height) * 2.0 - 1.0
            )
        )
    }

}

struct MTLTextureCoordinates {
    let LT: CGPoint
    let RT: CGPoint
    let RB: CGPoint
    let LB: CGPoint

    func getValues() -> [Float] {
        [
            Float(LB.x), Float(LB.y),
            Float(RB.x), Float(RB.y),
            Float(RT.x), Float(RT.y),
            Float(LT.x), Float(LT.y)
        ]
    }

    /// UV coordinates for a screen coordinate system with the origin at the top-left corner.
    /// This is typical in `UIKit`, where (0,0) represents the top-left of the screen.
    static let screenTextureCoordinates: Self = .init(
        LT: .init(x: 0.0, y: 0.0),
        RT: .init(x: 1.0, y: 0.0),
        RB: .init(x: 1.0, y: 1.0),
        LB: .init(x: 0.0, y: 1.0)
    )

    /// UV coordinates for a Cartesian coordinate system with the origin at the bottom-left corner
    /// Commonly used in `Metal` rendering, where the bottom-left is (0,0).
    static let cartesianTextureCoordinates: Self = .init(
        LT: .init(x: 0.0, y: 1.0),
        RT: .init(x: 1.0, y: 1.0),
        RB: .init(x: 1.0, y: 0.0),
        LB: .init(x: 0.0, y: 0.0)
    )

}

struct MTLTextureIndices {
    let LB: UInt16 = 0
    let RB: UInt16 = 1
    let RT: UInt16 = 2
    let LT: UInt16 = 3

    func getValues() -> [UInt16] {
        [
            LB, RB, RT,
            LB, RT, LT
        ]
    }
}
