//
//  CanvasCurrentTexture.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

final class CanvasCurrentTexture {

    private (set) var texture: MTLTexture?

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!
}

extension CanvasCurrentTexture {
    func initTexture(textureSize: CGSize) {
        texture = MTKTextureUtils.makeBlankTexture(
            with: device,
            textureSize
        )
    }

    func clearTexture() {
        let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!
        MTLRenderer.clear(texture, with: commandBuffer)
        commandBuffer.commit()
    }

}
