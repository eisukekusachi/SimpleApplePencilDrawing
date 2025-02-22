//
//  MTLBuffers.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

struct MTLGrayscalePointBuffers {
    let vertexBuffer: MTLBuffer
    let diameterIncludingBlurBuffer: MTLBuffer
    let brightnessBuffer: MTLBuffer
    let blurSizeBuffer: MTLBuffer
    let numberOfPoints: Int
}

struct MTLTextureBuffers {
    let vertexBuffer: MTLBuffer
    let texCoordsBuffer: MTLBuffer
    let indexBuffer: MTLBuffer
    let indicesCount: Int
}

enum MTLBuffers {

    static func makeGrayscalePointBuffers(
        grayscaleTexturePoints: [CanvasGrayscaleDotPoint],
        pointsAlpha: Int = 255,
        textureSize: CGSize,
        with device: MTLDevice
    ) -> MTLGrayscalePointBuffers? {
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

        return .init(
            vertexBuffer: vertexBuffer,
            diameterIncludingBlurBuffer: diameterPlusBlurSizeBuffer,
            brightnessBuffer: brightnessBuffer,
            blurSizeBuffer: blurSizeBuffer,
            numberOfPoints: grayscaleTexturePoints.count
        )
    }

    static func makeTextureBuffers(
        nodes: MTLTextureNodes = .textureNodes,
        with device: MTLDevice
    ) -> MTLTextureBuffers? {
        let vertices = nodes.vertices.getValues()
        let texCoords = nodes.textureCoord.getValues()
        let indices = nodes.indices.getValues()

        guard
            let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size),
            let texCoordsBuffer = device.makeBuffer(bytes: texCoords, length: texCoords.count * MemoryLayout<Float>.size),
            let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size)
        else { return nil }

        return .init(
            vertexBuffer: vertexBuffer,
            texCoordsBuffer: texCoordsBuffer,
            indexBuffer: indexBuffer,
            indicesCount: indices.count
        )
    }

    static func makeTextureBuffers(
        sourceSize: CGSize,
        destinationSize: CGSize,
        textureCoord: MTLTextureCoordinates = .screenTextureCoordinates,
        indices: MTLTextureIndices = .init(),
        with device: MTLDevice
    ) -> MTLTextureBuffers? {
        let vertices: [Float] = MTLTextureVertices.makeCenterAlignedTextureVertices(
            sourceSize: sourceSize,
            destinationSize: destinationSize
        ).getValues()
        let textureCoord: [Float]  = textureCoord.getValues()
        let indices: [UInt16] = indices.getValues()

        guard
            let vertexBuffer = device.makeBuffer(bytes: vertices, length: vertices.count * MemoryLayout<Float>.size),
            let texCoordsBuffer = device.makeBuffer(bytes: textureCoord, length: textureCoord.count * MemoryLayout<Float>.size),
            let indexBuffer = device.makeBuffer(bytes: indices, length: indices.count * MemoryLayout<UInt16>.size)
        else {
            return nil
        }

        return .init(
            vertexBuffer: vertexBuffer,
            texCoordsBuffer: texCoordsBuffer,
            indexBuffer: indexBuffer,
            indicesCount: indices.count
        )
    }

}
