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

    static func makeTextureBuffers(
        device: MTLDevice?,
        sourceSize: CGSize,
        destinationSize: CGSize,
        nodes: TextureNodes
    ) -> TextureBuffers? {
        guard let device else { return nil }

        // Normalize vertex positions
        let vertices: [Float] = [
            // bottomLeft
            Float((destinationSize.width * 0.5 + -1 * sourceSize.width * 0.5) / destinationSize.width) * 2.0 - 1.0,
            Float((destinationSize.height * 0.5 + -1 * sourceSize.height * 0.5) / destinationSize.height) * 2.0 - 1.0,
            // bottomRight
            Float((destinationSize.width * 0.5 + 1 * sourceSize.width * 0.5) / destinationSize.width) * 2.0 - 1.0,
            Float((destinationSize.height * 0.5 + -1 * sourceSize.height * 0.5) / destinationSize.height * 2.0 - 1.0),
            // topRight
            Float((destinationSize.width * 0.5 + 1 * sourceSize.width * 0.5) / destinationSize.width * 2.0 - 1.0),
            Float((destinationSize.height * 0.5 + 1 * sourceSize.height * 0.5) / destinationSize.height * 2.0 - 1.0),
            // topLeft
            Float((destinationSize.width * 0.5 + -1 * sourceSize.width * 0.5) / destinationSize.width * 2.0 - 1.0),
            Float((destinationSize.height * 0.5 + 1 * sourceSize.height * 0.5) / destinationSize.height * 2.0 - 1.0)
        ]

        // Create buffers
        guard
            let vertexBuffer = device.makeBuffer(
                bytes: vertices,
                length: vertices.count * MemoryLayout<Float>.size,
                options: []
            ),
            let texCoordsBuffer = device.makeBuffer(
                bytes: nodes.texCoords,
                length: nodes.texCoords.count * MemoryLayout<Float>.size,
                options: []
            ),
            let indexBuffer = device.makeBuffer(
                bytes: nodes.indices,
                length: nodes.indices.count * MemoryLayout<UInt16>.size,
                options: []
            )
        else {
            return nil
        }

        return TextureBuffers(
            vertexBuffer: vertexBuffer,
            texCoordsBuffer: texCoordsBuffer,
            indexBuffer: indexBuffer,
            indicesCount: nodes.indices.count
        )
    }

}
