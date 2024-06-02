//
//  MTLTextureManager.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
import Accelerate

enum MTLTextureManager {

    static func makeBlankTexture(
        with device: MTLDevice,
        _ textureSize: CGSize
    ) -> MTLTexture? {
        guard
            let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer(),
            let texture = Self.makeTexture(with: device, textureSize)
        else { return nil }

        MTLRenderer.clear(
            texture,
            commandBuffer
        )
        commandBuffer.commit()

        return texture
    }

}

extension MTLTextureManager {

    private static func makeTexture(
        with device: MTLDevice,
        _ textureSize: CGSize,
        _ pixelFormat: MTLPixelFormat = .bgra8Unorm
    ) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: pixelFormat,
            width: Int(textureSize.width),
            height: Int(textureSize.height),
            mipmapped: false
        )
        textureDescriptor.usage = [
            .renderTarget,
            .shaderRead,
            .shaderWrite
        ]

        return device.makeTexture(descriptor: textureDescriptor)
    }

}
