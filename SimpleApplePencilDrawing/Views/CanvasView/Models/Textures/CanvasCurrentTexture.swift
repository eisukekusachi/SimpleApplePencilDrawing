//
//  CanvasCurrentTexture.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

final class CanvasCurrentTexture {

    private (set) var currentTexture: MTLTexture?

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!
}

extension CanvasCurrentTexture {
    func initTexture(
        _ textureSize: CGSize
    ) {
        currentTexture = MTKTextureUtils.makeBlankTexture(
            with: device,
            textureSize
        )
    }

    func clearTexture() {
        let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!
        MTLRenderer.clear(currentTexture, with: commandBuffer)
        commandBuffer.commit()
    }

}
