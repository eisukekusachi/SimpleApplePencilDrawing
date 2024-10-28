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

enum MTLBuffers {
    static let defaultTextureNodes: TextureNodes = (
        vertices: MTLBuffers.defaultVertices,
        texCoords: MTLBuffers.defaultTexCoords,
        indices: MTLBuffers.defaultIndices
    )

    static let defaultVertices: [Float] = [
        Float(-1.0), Float( 1.0), // LB
        Float( 1.0), Float( 1.0), // RB
        Float( 1.0), Float(-1.0), // RT
        Float(-1.0), Float(-1.0)  // LT
    ]
    static let defaultTexCoords: [Float] = [
        0.0, 1.0, // LB
        1.0, 1.0, // RB
        1.0, 0.0, // RT
        0.0, 0.0  // LT
    ]
    static let defaultIndices: [UInt16] = [
        0, 1, 2, // LB, RB, RT
        0, 2, 3  // LB, RT, LT
    ]

    static func makeGrayscalePointBuffers(
        grayscaleTexturePoints: [CanvasGrayscaleDotPoint],
        pointsAlpha: Int = 255,
        textureSize: CGSize,
        with device: MTLDevice
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
            let vertexBuffer = device.makeBuffer(
                bytes: vertexArray,
                length: vertexArray.count * MemoryLayout<Float>.size
            ),
            let diameterPlusBlurSizeBuffer = device.makeBuffer(
                bytes: diameterPlusBlurSizeArray,
                length: diameterPlusBlurSizeArray.count * MemoryLayout<Float>.size
            ),
            let blurSizeBuffer = device.makeBuffer(
                bytes: bufferSizeArray,
                length: bufferSizeArray.count * MemoryLayout<Float>.size
            ),
            let brightnessBuffer = device.makeBuffer(
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

    static func makeTextureBuffers(with device: MTLDevice) -> TextureBuffers? {
        let vertices = defaultVertices
        let texCoords = defaultTexCoords
        let indices = defaultIndices

        guard
            let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size),
            let texCoordsBuffer = device.makeBuffer(bytes: texCoords, length: texCoords.count * MemoryLayout<Float>.size),
            let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size)
        else { return nil }

        return (
            vertexBuffer: vertexBuffer,
            texCoordsBuffer: texCoordsBuffer,
            indexBuffer: indexBuffer,
            indicesCount: indices.count
        )
    }

    static func makeTextureBuffers(
        sourceSize: CGSize,
        destinationSize: CGSize,
        with device: MTLDevice
    ) -> TextureBuffers? {
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
                bytes: defaultTexCoords,
                length: defaultTexCoords.count * MemoryLayout<Float>.size,
                options: []
            ),
            let indexBuffer = device.makeBuffer(
                bytes: defaultIndices,
                length: defaultIndices.count * MemoryLayout<UInt16>.size,
                options: []
            )
        else {
            return nil
        }

        return TextureBuffers(
            vertexBuffer: vertexBuffer,
            texCoordsBuffer: texCoordsBuffer,
            indexBuffer: indexBuffer,
            indicesCount: defaultIndices.count
        )
    }

}
