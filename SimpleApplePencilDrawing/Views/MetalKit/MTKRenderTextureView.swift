//
//  MTKRenderTextureView.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit

protocol MTKRenderTextureProtocol {
    var commandBuffer: MTLCommandBuffer { get }

    var renderTexture: MTLTexture? { get }
    var viewDrawable: CAMetalDrawable? { get }

    func setNeedsDisplay()
}

/// A custom view for displaying textures with Metal support.
class MTKRenderTextureView: MTKView, MTKViewDelegate, MTKRenderTextureProtocol {

    @objc dynamic var renderTexture: MTLTexture? {
        _renderTexture
    }
    @objc dynamic var renderTextureSize: CGSize = .zero

    var commandBuffer: MTLCommandBuffer {
        commandManager.currentCommandBuffer
    }
    var viewDrawable: (any CAMetalDrawable)? {
        currentDrawable
    }

    var isDisplayLinkPaused: Bool = false {
        didSet {
            displayLink?.isPaused = isDisplayLinkPaused

            if isDisplayLinkPaused {
                setNeedsDisplay()
            }
        }
    }

    private var _renderTexture: MTLTexture!

    private var commandManager: MTLCommandManager!

    private var displayLink: CADisplayLink?

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

        _renderTexture = MTLTextureManager.makeBlankTexture(with: device!, textureSize)
        renderTextureSize = textureSize
    }

    // MARK: - DrawTexture
    func draw(in view: MTKView) {
        assert(self._renderTexture != nil, "`rootTexture` is nil. Call `initRootTexture(with textureSize:)` once before rendering.")
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
            backgroundColor: (230, 230, 230),
            on: drawable.texture,
            with: commandBuffer
        )

        commandBuffer.present(drawable)
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        commandManager.clearCurrentCommandBuffer()
    }

    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Initialize the `_renderTexture` when the `drawableSize` is determined if it is not already initialized.
        if _renderTexture == nil {
            initTexture(with: size)
        }
        setNeedsDisplay()
    }

}

extension MTKRenderTextureView {

    @objc private func updateDisplayLink(_ displayLink: CADisplayLink) {
        setNeedsDisplay()
    }

}
