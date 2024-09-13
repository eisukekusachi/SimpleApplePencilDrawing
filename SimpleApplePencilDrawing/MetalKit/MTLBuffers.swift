//
//  MTLBuffers.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

typealias GrayscalePointBuffers = (
    vertexBuffer: MTLBuffer,
    diameterIncludingBlurBuffer: MTLBuffer,
    brightnessBuffer: MTLBuffer,
    blurSizeBuffer: MTLBuffer,
    numberOfPoints: Int
)

typealias TextureBuffers = (
    vertexBuffer: MTLBuffer,
    texCoordsBuffer: MTLBuffer,
    indexBuffer: MTLBuffer,
    indicesCount: Int
)

typealias TextureNodes = (
    vertices: [Float],
    texCoords: [Float],
    indices: [UInt16]
)

let textureNodes: TextureNodes = (
    vertices: [
        Float(-1.0), Float( 1.0), // LB
        Float( 1.0), Float( 1.0), // RB
        Float( 1.0), Float(-1.0), // RT
        Float(-1.0), Float(-1.0)  // LT
    ],
    texCoords: [
        0.0, 1.0, // LB *
        1.0, 1.0, // RB *
        1.0, 0.0, // RT
        0.0, 0.0  // LT
    ],
    indices: [
        0, 1, 2,
        0, 2, 3
    ]
)

let flippedTextureNodes: TextureNodes = (
    vertices: [
        Float(-1.0), Float( 1.0), // LB
        Float( 1.0), Float( 1.0), // RB
        Float( 1.0), Float(-1.0), // RT
        Float(-1.0), Float(-1.0)  // LT
    ],
    texCoords: [
        0.0, 0.0, // LB *
        1.0, 0.0, // RB *
        1.0, 1.0, // RT
        0.0, 1.0  // LT
    ],
    indices: [
        0, 1, 2,
        0, 2, 3
    ]
)

enum MTLBuffers {

    static func makeGrayscalePointBuffers(
        device: MTLDevice?,
        grayscaleTexturePoints: [CanvasGrayscaleDotPoint],
        pointsAlpha: Int = 255,
        textureSize: CGSize
    ) -> GrayscalePointBuffers? {
        guard grayscaleTexturePoints.count != .zero else { return nil }

        var vertexArray: [Float] = []
        var diameterPlusBlurSizeArray: [Float] = []
        var bufferSizeArray: [Float] = []
        var brightnessArray: [Float] = []

        let alpha: CGFloat = CGFloat(pointsAlpha) / 255.0

        grayscaleTexturePoints.forEach {
            let vertexX: Float = Float($0.location.x / textureSize.width) * 2.0 - 1.0
            let vertexY: Float = Float($0.location.y / textureSize.height) * 2.0 - 1.0

            vertexArray.append(contentsOf: [vertexX, vertexY])
            diameterPlusBlurSizeArray.append(Float($0.diameter))
            bufferSizeArray.append(4.0)
            brightnessArray.append(Float($0.brightness * alpha))
        }

        guard
            let vertexBuffer = device?.makeBuffer(
                bytes: vertexArray,
                length: vertexArray.count * MemoryLayout<Float>.size
            ),
            let diameterPlusBlurSizeBuffer = device?.makeBuffer(
                bytes: diameterPlusBlurSizeArray,
                length: diameterPlusBlurSizeArray.count * MemoryLayout<Float>.size
            ),
            let blurSizeBuffer = device?.makeBuffer(
                bytes: bufferSizeArray,
                length: bufferSizeArray.count * MemoryLayout<Float>.size
            ),
            let brightnessBuffer = device?.makeBuffer(
                bytes: brightnessArray,
                length: brightnessArray.count * MemoryLayout<Float>.size
            )
        else { return nil }

        return GrayscalePointBuffers(
            vertexBuffer: vertexBuffer,
            diameterIncludingBlurBuffer: diameterPlusBlurSizeBuffer,
            brightnessBuffer: brightnessBuffer,
            blurSizeBuffer: blurSizeBuffer,
            numberOfPoints: grayscaleTexturePoints.count
        )
    }

    static func makeTextureBuffers(
        device: MTLDevice?,
        nodes: TextureNodes
    ) -> TextureBuffers? {
        let vertices = nodes.vertices
        let texCoords = nodes.texCoords
        let indices = nodes.indices

        guard
            let vertexBuffer = device?.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size),
            let texCoordsBuffer = device?.makeBuffer(bytes: texCoords, length: texCoords.count * MemoryLayout<Float>.size),
            let indexBuffer = device?.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size)
        else { return nil }

        return (
            vertexBuffer: vertexBuffer,
            texCoordsBuffer: texCoordsBuffer,
            indexBuffer: indexBuffer,
            indicesCount: indices.count
        )
    }

    static func makeAspectFitTextureBuffers(
        device: MTLDevice?,
        sourceSize: CGSize,
        destinationSize: CGSize,
        nodes: TextureNodes
    ) -> TextureBuffers? {
        guard let device = device else { return nil }

        let texCoords = nodes.texCoords
        let indices = nodes.indices

        // Helper function to calculate vertex coordinates
        func calculateVertexPosition(xOffset: CGFloat, yOffset: CGFloat) -> CGPoint {
            let x = destinationSize.width * 0.5 + xOffset * sourceSize.width * 0.5
            let y = destinationSize.height * 0.5 + yOffset * sourceSize.height * 0.5
            return CGPoint(x: x, y: y)
        }

        // Calculate vertex positions for the four corners
        let bottomLeft = calculateVertexPosition(xOffset: -1, yOffset: 1)
        let bottomRight = calculateVertexPosition(xOffset: 1, yOffset: 1)
        let topRight = calculateVertexPosition(xOffset: 1, yOffset: -1)
        let topLeft = calculateVertexPosition(xOffset: -1, yOffset: -1)

        // Normalize vertex positions to OpenGL coordinates
        let vertices: [Float] = [
            Float(bottomLeft.x / destinationSize.width * 2.0 - 1.0), Float(bottomLeft.y / destinationSize.height * 2.0 - 1.0),
            Float(bottomRight.x / destinationSize.width * 2.0 - 1.0), Float(bottomRight.y / destinationSize.height * 2.0 - 1.0),
            Float(topRight.x / destinationSize.width * 2.0 - 1.0), Float(topRight.y / destinationSize.height * 2.0 - 1.0),
            Float(topLeft.x / destinationSize.width * 2.0 - 1.0), Float(topLeft.y / destinationSize.height * 2.0 - 1.0)
        ]

        // Create buffers
        guard
            let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size, options: []),
            let texCoordsBuffer = device.makeBuffer(bytes: texCoords, length: texCoords.count * MemoryLayout<Float>.size, options: []),
            let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size, options: [])
        else {
            return nil
        }

        return TextureBuffers(
            vertexBuffer: vertexBuffer,
            texCoordsBuffer: texCoordsBuffer,
            indexBuffer: indexBuffer,
            indicesCount: indices.count
        )
    }

}
