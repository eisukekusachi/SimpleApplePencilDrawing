//
//  MTLPipelineManager.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

final class MTLPipelineManager {

    static let shared = MTLPipelineManager()

    private (set) var drawTexture: MTLRenderPipelineState!
    private (set) var fillColor: MTLComputePipelineState!

    private init() {
        guard
            let device = MTLCreateSystemDefaultDevice(),
            let library = device.makeDefaultLibrary()
        else {
            fatalError("Failed to create default library with device.")
        }

        self.drawTexture = makeRenderPipelineState(
            device: device,
            library: library,
            label: "Draw a texture"
        ) { descriptor in
            descriptor.vertexFunction = library.makeFunction(name: "draw_texture_vertex")
            descriptor.fragmentFunction = library.makeFunction(name: "draw_texture_fragment")
            descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
            descriptor.colorAttachments[0].isBlendingEnabled = true
            descriptor.colorAttachments[0].rgbBlendOperation = .add
            descriptor.colorAttachments[0].alphaBlendOperation = .add
            descriptor.colorAttachments[0].sourceRGBBlendFactor = .one
            descriptor.colorAttachments[0].sourceAlphaBlendFactor = .one
            descriptor.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
            descriptor.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        }

        self.fillColor = makeComputePipeline(
            device: device,
            library: library,
            label: "Add color to a texture",
            shaderName: "add_color_to_texture"
        )
    }

}

extension MTLPipelineManager {

    private func makeComputePipeline(
        device: MTLDevice,
        library: MTLLibrary,
        label: String,
        shaderName: String
    ) -> MTLComputePipelineState {
        guard let function = library.makeFunction(name: shaderName) else {
            fatalError("The function is not found in the library.")
        }
        do {
            return try device.makeComputePipelineState(function: function)
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    private func makeRenderPipelineState(
        device: MTLDevice,
        library: MTLLibrary,
        label: String,
        block: (MTLRenderPipelineDescriptor) -> Void
    ) -> MTLRenderPipelineState {

        let descriptor = MTLRenderPipelineDescriptor()
        block(descriptor)
        descriptor.label = label
        do {
            return try device.makeRenderPipelineState(descriptor: descriptor)
        } catch {
            fatalError(error.localizedDescription)
        }
    }

}
