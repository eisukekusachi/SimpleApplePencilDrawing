//
//  CanvasView.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
import Combine

protocol CanvasViewProtocol {
    var commandBuffer: MTLCommandBuffer { get }

    var renderTexture: MTLTexture? { get }

    func clearCommandBuffer()

    func setNeedsDisplay()
}

/// A custom view for displaying textures with Metal support.
class CanvasView: MTKView, MTKViewDelegate, CanvasViewProtocol {

    var commandBuffer: MTLCommandBuffer {
        commandManager.currentCommandBuffer
    }

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

    private var commandManager: MTLCommandManager!

    private (set) var displayLink: CADisplayLink!

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
        let commandQueue = self.device!.makeCommandQueue()

        assert(self.device != nil, "Device is nil.")
        assert(commandQueue != nil, "CommandQueue is nil.")

        commandManager = MTLCommandManager(device: self.device!)

        textureBuffers = MTLBuffers.makeTextureBuffers(device: device, nodes: textureNodes)

        // Configure the display link for rendering.
        displayLink = CADisplayLink(target: self, selector: #selector(updateDisplayLink(_:)))
        displayLink?.add(to: .current, forMode: .common)
        displayLink?.isPaused = true

        self.delegate = self
        self.enableSetNeedsDisplay = true
        self.autoResizeDrawable = true
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
        self.backgroundColor = .white

        if let textureSize: CGSize = currentDrawable?.texture.size {
            _renderTexture = MTKTextureUtils.makeBlankTexture(with: device!, textureSize)
         }
    }

    // MARK: - DrawTexture
    func draw(in view: MTKView) {
        guard
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

        commandManager.clearCurrentCommandBuffer()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Align the size of `_renderTexture` with `drawableSize`
        _renderTexture = MTKTextureUtils.makeBlankTexture(with: device!, size)
    }

}

extension CanvasView {

    func clearCommandBuffer() {
        commandManager.clearCurrentCommandBuffer()
    }

    @objc private func updateDisplayLink(_ displayLink: CADisplayLink) {
        setNeedsDisplay()
    }

}
