//
//  CanvasView.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
import Combine

protocol CanvasViewProtocol {
    var commandBuffer: MTLCommandBuffer? { get }

    var renderTexture: MTLTexture? { get }

    func resetCommandBuffer()

    func updateCanvasView()
}

/// A custom view for displaying textures with Metal support.
class CanvasView: MTKView, MTKViewDelegate, CanvasViewProtocol {

    private var commandQueue: MTLCommandQueue!

    private (set) var commandBuffer: MTLCommandBuffer?

    var updateTexturePublisher: AnyPublisher<Void, Never> {
        updateTextureSubject.eraseToAnyPublisher()
    }
    var renderTexture: MTLTexture? {
        _renderTexture
    }

    private var _renderTexture: MTLTexture? {
        didSet {
            updateTextureSubject.send(())
        }
    }

    private var textureBuffers: TextureBuffers?

    private let updateTextureSubject = PassthroughSubject<Void, Never>()

    override init(frame frameRect: CGRect, device: MTLDevice?) {
        super.init(frame: frameRect, device: device)
        commonInit()
    }
    required init(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        self.device = MTLCreateSystemDefaultDevice()
        assert(device != nil, "Device is nil.")

        guard
            let device,
            let queue = device.makeCommandQueue()
        else { return }

        commandQueue = queue
        resetCommandBuffer()

        textureBuffers = MTLBuffers.makeTextureBuffers(device: device, nodes: textureNodes)

        self.delegate = self
        self.enableSetNeedsDisplay = true
        self.autoResizeDrawable = true
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
        self.backgroundColor = .white

        if let textureSize: CGSize = currentDrawable?.texture.size {
            _renderTexture = MTKTextureUtils.makeBlankTexture(size: textureSize, with: device)
         }
    }

    // MARK: - DrawTexture
    func draw(in view: MTKView) {
        guard
            let commandBuffer,
            let textureBuffers,
            let renderTexture,
            let drawable = view.currentDrawable
        else { return }

        // Draw `renderTexture` directly onto `drawable.texture`
        MTLRenderer.draw(
            texture: renderTexture,
            buffers: textureBuffers,
            on: drawable.texture,
            with: commandBuffer
        )

        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        resetCommandBuffer()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        guard let device else { return }

        // Align the size of `_renderTexture` with `drawableSize`
        _renderTexture = MTKTextureUtils.makeBlankTexture(size: size, with: device)
    }

}

extension CanvasView {
    func resetCommandBuffer() {
        commandBuffer = commandQueue.makeCommandBuffer()
    }

    func updateCanvasView() {
        setNeedsDisplay()
    }

}
