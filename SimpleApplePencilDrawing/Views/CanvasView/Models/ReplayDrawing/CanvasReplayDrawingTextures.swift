//
//  CanvasReplayDrawingTextures.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/09/21.
//

import Foundation
import MetalKit

final class CanvasReplayDrawingTextures {

    private (set) var currentTexture: MTLTexture?
    private (set) var canvasTexture: MTLTexture?

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

    func initTexture(_ textureSize: CGSize) {
        currentTexture = MTKTextureUtils.makeBlankTexture(with: device, textureSize)
        canvasTexture = MTKTextureUtils.makeBlankTexture(with: device, textureSize)
    }

    func clearTexture() {
        let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!
        MTLRenderer.clear(
            textures: [currentTexture, canvasTexture],
            with: commandBuffer
        )
        commandBuffer.commit()
    }

}
