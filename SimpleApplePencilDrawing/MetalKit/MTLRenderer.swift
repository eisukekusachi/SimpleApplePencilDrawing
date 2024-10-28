//
//  MTLRenderer.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

final class MTLRenderer {

    static let threadGroupLength: Int = 16

    static func draw(
        textures: [MTLTexture?],
        withBackgroundColor color: (Int, Int, Int, Int),
        on destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard let destinationTexture else { return }

        MTLRenderer.fill(
            color: color,
            on: destinationTexture,
            with: commandBuffer
        )

        textures.forEach { texture in
            if let texture {
                MTLRenderer.merge(
                    texture: texture,
                    into: destinationTexture,
                    with: commandBuffer
                )
            }
        }
    }

    static func drawTexture(
        texture: MTLTexture,
        buffers: TextureBuffers,
        withBackgroundColor color: UIColor = .clear,
        on destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard let destinationTexture else { return }

        let rgba = color.rgba

        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = destinationTexture
        descriptor.colorAttachments[0].loadAction = .clear
        descriptor.colorAttachments[0].clearColor = MTLClearColorMake(
            min(CGFloat(rgba.0) / 255.0, 1.0),
            min(CGFloat(rgba.1) / 255.0, 1.0),
            min(CGFloat(rgba.2) / 255.0, 1.0),
            min(CGFloat(rgba.3) / 255.0, 1.0)
        )

        let encoder = commandBuffer.makeRenderCommandEncoder(descriptor: descriptor)
        encoder?.setRenderPipelineState(MTLPipelineManager.shared.drawTexture)
        encoder?.setVertexBuffer(buffers.vertexBuffer, offset: 0, index: 0)
        encoder?.setVertexBuffer(buffers.texCoordsBuffer, offset: 0, index: 1)
        encoder?.setFragmentTexture(texture, index: 0)
        encoder?.drawIndexedPrimitives(
            type: .triangle,
            indexCount: buffers.indicesCount,
            indexType: .uint16,
            indexBuffer: buffers.indexBuffer,
            indexBufferOffset: 0
        )
        encoder?.endEncoding()
    }

    static func drawPointsWithMaxBlendMode(
        grayscalePointBuffers buffers: GrayscalePointBuffers,
        on destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer?
    ) {
        let descriptor = MTLRenderPassDescriptor()
        descriptor.colorAttachments[0].texture = destinationTexture
        descriptor.colorAttachments[0].loadAction = .load

        let encoder = commandBuffer?.makeRenderCommandEncoder(descriptor: descriptor)
        encoder?.setRenderPipelineState(MTLPipelineManager.shared.drawPointsWithMaxBlendMode)
        encoder?.setVertexBuffer(buffers.vertexBuffer, offset: 0, index: 0)
        encoder?.setVertexBuffer(buffers.diameterIncludingBlurBuffer, offset: 0, index: 1)
        encoder?.setVertexBuffer(buffers.blurSizeBuffer, offset: 0, index: 2)
        encoder?.setVertexBuffer(buffers.brightnessBuffer, offset: 0, index: 3)
        encoder?.drawPrimitives(
            type: .point,
            vertexStart: 0,
            vertexCount: buffers.numberOfPoints
        )
        encoder?.endEncoding()
    }

}

extension MTLRenderer {

    static func fill(
        color: (Int, Int, Int),
        on destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer?
    ) {
        guard let destinationTexture else { return }

        fill(
            color: (color.0, color.1, color.2, 255),
            on: destinationTexture,
            with: commandBuffer
        )
    }

    static func fill(
        color: (Int, Int, Int, Int),
        on destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer?
    ) {
        guard let destinationTexture else { return }

        let threadGroupSize = MTLSize(
            width: Int(destinationTexture.width / 16),
            height: Int(destinationTexture.height / 16),
            depth: 1
        )
        var color: [Float] = [
            Float(color.0) / 255.0,
            Float(color.1) / 255.0,
            Float(color.2) / 255.0,
            Float(color.3) / 255.0
        ]

        let w = threadGroupSize.width
        let h = threadGroupSize.height
        let threadGroupCount = MTLSize(
            width: (destinationTexture.width  + w - 1) / w,
            height: (destinationTexture.height + h - 1) / h,
            depth: 1
        )

        let encoder = commandBuffer?.makeComputeCommandEncoder()
        encoder?.setComputePipelineState(MTLPipelineManager.shared.fillColor)
        encoder?.setBytes(&color, length: color.count * MemoryLayout<Float>.size, index: 0)
        encoder?.setTexture(destinationTexture, index: 0)
        encoder?.dispatchThreadgroups(threadGroupSize, threadsPerThreadgroup: threadGroupCount)
        encoder?.endEncoding()
    }

    static func clear(
        textures: [MTLTexture?],
        with commandBuffer: MTLCommandBuffer
    ) {
        textures.forEach {
            clear(texture: $0, with: commandBuffer)
        }
    }

    static func clear(
        texture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard let texture else { return }

        let threadGroupSize = MTLSize(
            width: Int(texture.width / 16),
            height: Int(texture.height / 16),
            depth: 1
        )
        let w = threadGroupSize.width
        let h = threadGroupSize.height
        let threadGroupCount = MTLSize(
            width: (texture.width  + w - 1) / w,
            height: (texture.height + h - 1) / h,
            depth: 1
        )
        var color: [Float] = [0.0, 0.0, 0.0, 0.0]

        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder?.setComputePipelineState(MTLPipelineManager.shared.fillColor)
        encoder?.setBytes(&color, length: color.count * MemoryLayout<Float>.size, index: 0)
        encoder?.setTexture(texture, index: 0)
        encoder?.dispatchThreadgroups(threadGroupSize, threadsPerThreadgroup: threadGroupCount)
        encoder?.endEncoding()
    }

    static func merge(
        texture: MTLTexture?,
        alpha: Int = 255,
        into destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard 
            let texture,
            let destinationTexture
        else { return }

        let threadGroupSize = MTLSize(
            width: Int(destinationTexture.width / 16),
            height: Int(destinationTexture.height / 16),
            depth: 1
        )
        let w = threadGroupSize.width
        let h = threadGroupSize.height
        let threadGroupCount = MTLSize(
            width: (destinationTexture.width  + w - 1) / w,
            height: (destinationTexture.height + h - 1) / h,
            depth: 1
        )
        var alpha: Float = max(0.0, min(Float(alpha) / 255.0, 1.0))

        guard let encoder = commandBuffer.makeComputeCommandEncoder() else { return }

        encoder.setComputePipelineState(MTLPipelineManager.shared.merge)
        encoder.setTexture(destinationTexture, index: 0)
        encoder.setTexture(destinationTexture, index: 1)
        encoder.setTexture(texture, index: 2)
        encoder.setBytes(&alpha, length: MemoryLayout<Float>.size, index: 3)
        encoder.dispatchThreadgroups(threadGroupSize, threadsPerThreadgroup: threadGroupCount)
        encoder.endEncoding()
    }

    static func colorize(
        grayscaleTexture: MTLTexture,
        color: (Int, Int, Int),
        on destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer
    ) {
        guard let destinationTexture else { return }

        let threadGroupSize = MTLSize(
            width: Int(grayscaleTexture.width / threadGroupLength),
            height: Int(grayscaleTexture.height / threadGroupLength),
            depth: 1
        )
        let w = threadGroupSize.width
        let h = threadGroupSize.height
        let threadGroupCount = MTLSize(
            width: (grayscaleTexture.width  + w - 1) / w,
            height: (grayscaleTexture.height + h - 1) / h,
            depth: 1
        )
        var resultColor: [Float] = [
            Float(color.0) / 255.0,
            Float(color.1) / 255.0,
            Float(color.2) / 255.0,
            1.0
        ]

        let encoder = commandBuffer.makeComputeCommandEncoder()
        encoder?.setComputePipelineState(MTLPipelineManager.shared.colorize)
        encoder?.setBytes(&resultColor, length: resultColor.count * MemoryLayout<Float>.size, index: 0)
        encoder?.setTexture(destinationTexture, index: 0)
        encoder?.setTexture(grayscaleTexture, index: 1)
        encoder?.dispatchThreadgroups(threadGroupSize, threadsPerThreadgroup: threadGroupCount)
        encoder?.endEncoding()
    }

}
