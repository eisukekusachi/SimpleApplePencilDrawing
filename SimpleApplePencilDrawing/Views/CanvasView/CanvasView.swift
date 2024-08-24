//
//  CanvasView.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

protocol CanvasViewProtocol {
    var commandBuffer: MTLCommandBuffer { get }

    var renderTexture: MTLTexture? { get }
    var viewDrawable: CAMetalDrawable? { get }

    func initTexture(with textureSize: CGSize)

    func setNeedsDisplay()
}

/// A custom view for displaying textures with Metal support.
class CanvasView: MTKView, MTKViewDelegate, CanvasViewProtocol {

    @objc dynamic var renderTexture: MTLTexture?

    var commandBuffer: MTLCommandBuffer {
        commandManager.currentCommandBuffer
    }
    var viewDrawable: (any CAMetalDrawable)? {
        currentDrawable
    }

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
    }

    func initTexture(with textureSize: CGSize) {
        let minLength: CGFloat = CGFloat(MTLRenderer.threadGroupLength)
        assert(textureSize.width >= minLength && textureSize.height >= minLength, "The textureSize is not appropriate")

        renderTexture = MTLTextureManager.makeBlankTexture(with: device!, textureSize)
    }

    // MARK: - DrawTexture
    func draw(in view: MTKView) {
        guard
            let device,
            let renderTexture,
            let drawable = view.currentDrawable,
            let textureBuffers = MTLBuffers.makeAspectFitTextureBuffers(
                device: device,
                sourceSize: renderTexture.size,
                destinationSize: drawable.texture.size,
                nodes: textureNodes
            )
        else { return }

        MTLRenderer.drawTexture(
            renderTexture,
            buffers: textureBuffers,
            withBackgroundColor: (230, 230, 230),
            on: drawable.texture,
            with: commandBuffer
        )

        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        commandManager.clearCurrentCommandBuffer()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        setNeedsDisplay()
    }

}

extension CanvasView {

    @objc private func updateDisplayLink(_ displayLink: CADisplayLink) {
        setNeedsDisplay()
    }

}
