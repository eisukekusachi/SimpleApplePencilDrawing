//
//  MTLRendering.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2026/01/03.
//

import MetalKit

@MainActor
public protocol MTLRendering {

    var device: MTLDevice { get }

    var newCommandBuffer: MTLCommandBuffer? { get }

    func drawGrayPointBuffersWithMaxBlendMode(
        buffers: MTLGrayscalePointBuffers,
        onGrayscaleTexture texture: MTLTexture,
        with commandBuffer: MTLCommandBuffer
    )

    func drawTexture(
        texture: MTLTexture?,
        frameSize: CGSize,
        backgroundColor: UIColor,
        on destinationTexture: MTLTexture,
        with commandBuffer: MTLCommandBuffer
    )

    func drawTexture(
        texture: MTLTexture,
        buffers: MTLTextureBuffers,
        withBackgroundColor color: UIColor?,
        on destinationTexture: MTLTexture,
        with commandBuffer: MTLCommandBuffer
    )

    func drawTexture(
        grayscaleTexture: MTLTexture,
        color rgb: IntRGB,
        on destinationTexture: MTLTexture,
        with commandBuffer: MTLCommandBuffer
    )

    func mergeTexture(
        texture: MTLTexture,
        into destinationTexture: MTLTexture,
        with commandBuffer: MTLCommandBuffer
    )

    func mergeTexture(
        texture: MTLTexture,
        alpha: Int,
        into destinationTexture: MTLTexture,
        with commandBuffer: MTLCommandBuffer
    )

    func fillColor(
        texture: MTLTexture,
        withRGB rgb: IntRGB,
        with commandBuffer: MTLCommandBuffer
    )

    func fillColor(
        texture: MTLTexture,
        withRGBA rgba: IntRGBA,
        with commandBuffer: MTLCommandBuffer
    )

    func copyTexture(
        srcTexture: MTLTexture,
        dstTexture: MTLTexture,
        with commandBuffer: MTLCommandBuffer
    )

    func copyTexture(
        srcTexture: MTLTexture,
        dstTexture: MTLTexture
    ) async throws

    func clearTextures(
        textures: [MTLTexture?],
        with commandBuffer: MTLCommandBuffer
    )

    func clearTexture(
        texture: MTLTexture,
        with commandBuffer: MTLCommandBuffer
    )
}
