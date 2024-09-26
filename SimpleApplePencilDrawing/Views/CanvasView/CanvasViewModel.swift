//
//  CanvasViewModel.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/02.
//

import MetalKit
import Combine
import Accelerate

final class CanvasViewModel {

    var pauseDisplayLinkPublish: AnyPublisher<Bool, Never> {
        pauseDisplayLinkSubject.eraseToAnyPublisher()
    }

    let sendImage = CurrentValueSubject<UIImage?, Never>(nil)

    /// An iterator for managing a grayscale curve
    private var grayscaleTextureCurveIterator: CanvasGrayscaleCurveIterator?

    /// A texture currently being drawn
    private let drawingTexture: CanvasDrawingTexture = CanvasBrushDrawingTexture()
    /// A texture with lines
    private var currentTexture: MTLTexture?
    /// A texture with a background color, composed of `drawingTexture` and `currentTexture`
    private var canvasTexture: MTLTexture?

    /// A manager for handling Apple Pencil input values
    private let pencilScreenTouchPoints = CanvasPencilScreenTouchPoints()

    private let pauseDisplayLinkSubject = CurrentValueSubject<Bool, Never>(true)

    private let replayDrawing = CanvasReplayDrawing()
    private let replayDrawingTextures = CanvasReplayDrawingTextures()

    private let drawingToolStatus = CanvasDrawingToolStatus()

    private var backgroundColor: UIColor = .white

    private let device: MTLDevice = MTLCreateSystemDefaultDevice()!

}

extension CanvasViewModel {

    func onViewDidAppear(canvasView: CanvasViewProtocol) {
        // Since `func onUpdateRenderTexture` is not called at app launch on iPhone,
        // initialize the canvas here.
        if canvasTexture == nil, let textureSize = canvasView.renderTexture?.size {
            initCanvas(
                textureSize: textureSize,
                canvasView: canvasView
            )

            drawTextureWithAspectFit(
                texture: canvasTexture,
                on: canvasView.renderTexture,
                commandBuffer: canvasView.commandBuffer
            )
            canvasView.setNeedsDisplay()
        }

        replayDrawing.delegate = self
    }

    func onUpdateRenderTexture(canvasView: CanvasViewProtocol) {
        if canvasTexture == nil, let textureSize = canvasView.renderTexture?.size {
            initCanvas(
                textureSize: textureSize,
                canvasView: canvasView
            )
        }

        // Redraws the canvas when the screen rotates and the canvas size changes.
        // Therefore, this code is placed outside the block.
        drawTextureWithAspectFit(
            texture: canvasTexture,
            on: canvasView.renderTexture,
            commandBuffer: canvasView.commandBuffer
        )
        canvasView.setNeedsDisplay()
    }

    func onFingerInputGesture(
        touches: Set<UITouch>,
        view: UIView,
        canvasView: CanvasViewProtocol
    ) {
        guard
            pencilScreenTouchPoints.estimatedTouchPointArray.isEmpty,
            let canvasTexture,
            let renderTexture = canvasView.renderTexture
        else { return }

        let touchScreenPoints: [CanvasTouchPoint] = touches.map {
            .init(touch: $0, view: view)
        }

        let touchPhase = touchScreenPoints.currentTouchPhase

        if touchPhase == .began {
            pauseDisplayLinkOnCanvas(false, canvasView: canvasView)
            grayscaleTextureCurveIterator = CanvasGrayscaleCurveIterator()
        }

        let textureTouchPoints: [CanvasTouchPoint] = touchScreenPoints.map {
            // Scale the touch location on the screen to fit the canvasTexture size with aspect fill
            CanvasTouchPoint.init(
                location: scaleAndCenterAspectFill(
                    sourceTextureLocation: $0.location,
                    sourceTextureSize: view.frame.size,
                    destinationTextureSize: canvasTexture.size
                ),
                touch: $0
            )
        }

        grayscaleTextureCurveIterator?.append(
            textureTouchPoints.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingToolStatus.brushDiameter)
                )
            }
        )

        drawingTexture.drawPointsOnDrawingTexture(
            grayscaleTexturePoints: grayscaleTextureCurveIterator?.makeCurvePoints(
                atEnd: touchPhase == .ended
            ) ?? [],
            color: drawingToolStatus.brushColor,
            with: canvasView.commandBuffer
        )

        mergeDrawingTexture(
            withCurrentTexture: currentTexture,
            withBackgroundColor: backgroundColor,
            on: canvasTexture,
            with: canvasView.commandBuffer,
            executeDrawingFinishProcess: touchPhase == .ended
        )

        drawTextureWithAspectFit(
            texture: canvasTexture,
            on: renderTexture,
            commandBuffer: canvasView.commandBuffer
        )

        replayDrawing.appendPointsToCurvePointArray(textureTouchPoints)

        if [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(touchPhase) {
            replayDrawing.appendCurveToArrayAndReadyForNextDrawing()

            pauseDisplayLinkOnCanvas(true, canvasView: canvasView)
            grayscaleTextureCurveIterator = nil
        }
    }

    func onPencilGestureDetected(
        touches: Set<UITouch>,
        with event: UIEvent?,
        view: UIView,
        canvasView: CanvasViewProtocol
    ) {
        // Make `grayscaleTextureCurveIterator` and start the display link when a touch begins
        if touches.contains(where: {$0.phase == .began}) {
            if grayscaleTextureCurveIterator != nil {
                cancelFingerDrawing(canvasView)
            }

            grayscaleTextureCurveIterator = CanvasGrayscaleCurveIterator()
            pauseDisplayLinkSubject.send(false)

            pencilScreenTouchPoints.reset()
        }

        event?.allTouches?
            .compactMap { $0.type == .pencil ? $0 : nil }
            .sorted { $0.timestamp < $1.timestamp }
            .forEach { touch in
                event?.coalescedTouches(for: touch)?.forEach { coalescedTouch in
                    pencilScreenTouchPoints.appendEstimatedValue(
                        .init(touch: coalescedTouch, view: view)
                    )
                }
            }
    }

    func onPencilGestureDetected(
        actualTouches: Set<UITouch>,
        view: UIView,
        canvasView: CanvasViewProtocol
    ) {
        guard
            let canvasTexture,
            let renderTexture = canvasView.renderTexture
        else { return }

        // Combine `actualTouches` with the estimated values to create actual values, and append them to an array
        let actualTouchArray = Array(actualTouches).sorted { $0.timestamp < $1.timestamp }
        actualTouchArray.forEach { actualTouch in
            pencilScreenTouchPoints.appendActualValueWithEstimatedValue(actualTouch)
        }
        if pencilScreenTouchPoints.hasActualValueReplacementCompleted {
            pencilScreenTouchPoints.appendLastEstimatedTouchPointToActualTouchPointArray()
        }

        guard
            // Wait to ensure sufficient time has passed since the previous process
            // as the operation may not work correctly if the time difference is too short.
            pencilScreenTouchPoints.hasSufficientTimeElapsedSincePreviousProcess(allowedDifferenceInSeconds: 0.01) ||
            [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(pencilScreenTouchPoints.actualTouchPointArray.currentTouchPhase)
        else { return }

        let latestScreenTouchArray = pencilScreenTouchPoints.latestActualTouchPoints
        pencilScreenTouchPoints.updateLatestActualTouchPoint()

        let touchPhase = latestScreenTouchArray.currentTouchPhase

        let latestTextureTouchArray = latestScreenTouchArray.map {
            // Scale the touch location on the screen to fit the canvasTexture size with aspect fill
            CanvasTouchPoint.init(
                location: scaleAndCenterAspectFill(
                    sourceTextureLocation: $0.location,
                    sourceTextureSize: view.frame.size,
                    destinationTextureSize: canvasTexture.size
                ),
                touch: $0
            )
        }

        grayscaleTextureCurveIterator?.append(
            latestTextureTouchArray.map {
                .init(
                    touchPoint: $0,
                    diameter: CGFloat(drawingToolStatus.brushDiameter)
                )
            }
        )

        drawingTexture.drawPointsOnDrawingTexture(
            grayscaleTexturePoints: grayscaleTextureCurveIterator?.makeCurvePoints(
                atEnd: touchPhase == .ended
            ) ?? [],
            color: drawingToolStatus.brushColor,
            with: canvasView.commandBuffer
        )

        mergeDrawingTexture(
            withCurrentTexture: currentTexture,
            withBackgroundColor: backgroundColor,
            on: canvasTexture,
            with: canvasView.commandBuffer,
            executeDrawingFinishProcess: touchPhase == .ended
        )

        drawTextureWithAspectFit(
            texture: canvasTexture,
            on: renderTexture,
            commandBuffer: canvasView.commandBuffer
        )

        replayDrawing.appendPointsToCurvePointArray(latestTextureTouchArray)

        if [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(touchPhase) {
            replayDrawing.appendCurveToArrayAndReadyForNextDrawing()

            pauseDisplayLinkOnCanvas(true, canvasView: canvasView)
            grayscaleTextureCurveIterator = nil

            pencilScreenTouchPoints.reset()
        }
    }

    func onTapClearTexture(canvasView: CanvasViewProtocol) {
        drawingTexture.clearTexture()

        let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!
        MTLRenderer.clear(
            texture: currentTexture,
            with: commandBuffer
        )
        commandBuffer.commit()

        clearCanvas(canvasView)
    }

    func onTapReplayButton(
        canvasView: CanvasViewProtocol
    ) {
        replayDrawingTextures.clearTexture()
        clearCanvas(canvasView)

        if !replayDrawing.replayDrawing {
            replayDrawing.drawCurveWhileReplaying(canvasView: canvasView)
        } else {
            replayDrawing.finishReplayDrawing()
        }
    }

}

extension CanvasViewModel {

    /// Initialize the textures used for drawing with the same size
    func initCanvas(
        textureSize: CGSize,
        canvasView: CanvasViewProtocol
    ) {
        guard let device = MTLCreateSystemDefaultDevice() else { return }

        drawingTexture.initTexture(textureSize: textureSize)
        currentTexture = MTKTextureUtils.makeBlankTexture(with: device, textureSize)
        canvasTexture = MTKTextureUtils.makeBlankTexture(with: device, textureSize)

        replayDrawingTextures.initTexture(textureSize)

        clearCanvas(canvasView)
    }

    private func clearCanvas(_ canvasView: CanvasViewProtocol) {
        MTLRenderer.fill(
            color: backgroundColor.rgb,
            on: canvasTexture,
            with: canvasView.commandBuffer
        )

        drawTextureWithAspectFit(
            texture: canvasTexture,
            on: canvasView.renderTexture,
            commandBuffer: canvasView.commandBuffer
        )

        canvasView.setNeedsDisplay()
    }

    private func cancelFingerDrawing(_ canvasView: CanvasViewProtocol) {
        canvasView.clearCommandBuffer()

        // Clear `drawingTextures` during drawing
        drawingTexture.clearTexture()

        mergeDrawingTexture(
            withCurrentTexture: currentTexture,
            withBackgroundColor: backgroundColor,
            on: canvasTexture,
            with: canvasView.commandBuffer
        )

        drawTextureWithAspectFit(
            texture: canvasTexture,
            on: canvasView.renderTexture,
            commandBuffer: canvasView.commandBuffer
        )

        canvasView.setNeedsDisplay()
    }

    private func pauseDisplayLinkOnCanvas(_ isPaused: Bool, canvasView: CanvasViewProtocol) {
        pauseDisplayLinkSubject.send(isPaused)

        // Call `canvasView.setNeedsDisplay` when stopping as the last line isn’t drawn
        if isPaused {
            canvasView.setNeedsDisplay()
        }
    }

    private func mergeDrawingTexture(
        withCurrentTexture currentTexture: MTLTexture?,
        withBackgroundColor backgroundColor: UIColor,
        on destinationTexture: MTLTexture?,
        with commandBuffer: MTLCommandBuffer,
        executeDrawingFinishProcess: Bool = false
    ) {
        guard
            let currentTexture,
            let destinationTexture
        else { return }

        // Render `currentTexture` and `drawingTexture` onto the `renderTexture`
        MTLRenderer.draw(
            textures: [
                currentTexture,
                drawingTexture.texture
            ],
            withBackgroundColor: backgroundColor.rgba,
            on: destinationTexture,
            with: commandBuffer
        )

        // At touch end, render `drawingTexture` on `currentTexture`
        // Then, clear `drawingTexture` for the next drawing.
        if executeDrawingFinishProcess {
            MTLRenderer.merge(
                texture: drawingTexture.texture,
                into: currentTexture,
                with: commandBuffer
            )
            drawingTexture.clearTexture(
                with: commandBuffer
            )
        }
    }

    /// Draw `texture` onto `destinationTexture` with aspect fit
    private func drawTextureWithAspectFit(
        texture: MTLTexture?,
        on destinationTexture: MTLTexture?,
        commandBuffer: MTLCommandBuffer
    ) {
        guard
            let texture,
            let destinationTexture
        else { return }

        let ratio = ViewSize.getScaleToFit(texture.size, to: destinationTexture.size)

        guard
            let device = MTLCreateSystemDefaultDevice(),
            let textureBuffers = MTLBuffers.makeTextureBuffers(
                device: device,
                sourceSize: .init(
                    width: texture.size.width * ratio,
                    height: texture.size.height * ratio
                ),
                destinationSize: destinationTexture.size,
                nodes: textureNodes
            )
        else { return }

        MTLRenderer.draw(
            texture: texture,
            buffers: textureBuffers,
            withBackgroundColor: Constants.blankAreaBackgroundColor,
            on: destinationTexture,
            with: commandBuffer
        )
    }

    /// Scales the `sourceTextureLocation` by applying the aspect fill ratio of `sourceTextureSize` to `destinationTextureSize`,
    /// ensuring the aspect ratio is maintained, and centers the scaled location within `destinationTextureSize`.
    private func scaleAndCenterAspectFill(
        sourceTextureLocation: CGPoint,
        sourceTextureSize: CGSize,
        destinationTextureSize: CGSize
    ) -> CGPoint {
        if sourceTextureSize == destinationTextureSize {
            return sourceTextureLocation
        }

        let ratio = ViewSize.getScaleToFill(sourceTextureSize, to: destinationTextureSize)

        return .init(
            x: sourceTextureLocation.x * ratio + (destinationTextureSize.width - sourceTextureSize.width * ratio) * 0.5,
            y: sourceTextureLocation.y * ratio + (destinationTextureSize.height - sourceTextureSize.height * ratio) * 0.5
        )
    }

}

extension CanvasViewModel: CanvasDrawingReplayDelegate {

    func sendPointForReplayDrawing(
        touchPoint: CanvasTouchPoint,
        drawingTool: String,
        canvasView: CanvasViewProtocol?
    ) {
        guard
            let canvasView,
            let renderTexture = canvasView.renderTexture
        else { return }

        let commandBuffer = device.makeCommandQueue()!.makeCommandBuffer()!

        let touchPhase = touchPoint.phase

        if touchPhase == .began {
            pauseDisplayLinkOnCanvas(false, canvasView: canvasView)
            grayscaleTextureCurveIterator = CanvasGrayscaleCurveIterator()
        }

        grayscaleTextureCurveIterator?.append(
            .init(
                touchPoint: touchPoint,
                diameter: CGFloat(drawingToolStatus.brushDiameter)
            )
        )

        guard
            replayDrawing.latestTouchPoint == nil ||
            replayDrawing.hasSufficientTimeElapsedSincePreviousProcess(touchPoint, allowedDifferenceInSeconds: 0.01) ||
            [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(touchPoint.phase)
        else { return }

        replayDrawing.latestTouchPoint = touchPoint

        let points = grayscaleTextureCurveIterator?.makeCurvePoints(
            atEnd: touchPhase == .ended
        ) ?? []

        // Draw curve points on the `drawingTexture`
        drawingTexture.drawPointsOnDrawingTexture(
            grayscaleTexturePoints: points,
            color: drawingToolStatus.brushColor,
            with: commandBuffer
        )

        mergeDrawingTexture(
            withCurrentTexture: replayDrawingTextures.currentTexture,
            withBackgroundColor: backgroundColor,
            on: replayDrawingTextures.canvasTexture,
            with: commandBuffer,
            executeDrawingFinishProcess: touchPhase == .ended
        )

        /*
        drawTextureWithAspectFit(
            texture: replayDrawingTextures.canvasTexture,
            on: renderTexture,
            commandBuffer: commandBuffer
        )

        if [UITouch.Phase.ended, UITouch.Phase.cancelled].contains(touchPhase) {
            pauseDisplayLinkOnCanvas(true, canvasView: canvasView)
            grayscaleTextureCurveIterator = nil
        }
        */

        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()

        if let image = replayDrawingTextures.canvasTexture?.upsideDownUIImage {
            replayDrawingTextures.imageArray.append(image)
            sendImage.send(image)
        }
    }

    func finishReplaying() {
        print("replay images")
        replayDrawingTextures.imageArray.forEach {
            print($0)
        }
    }

}

extension MTLTexture {

    var upsideDownUIImage: UIImage? {
        let width = self.width
        let height = self.height
        let numComponents = 4
        let bytesPerRow = width * numComponents
        let totalBytes = bytesPerRow * height
        let region = MTLRegionMake2D(0, 0, width, height)
        var bgraBytes = [UInt8](repeating: 0, count: totalBytes)
        self.getBytes(&bgraBytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        // use Accelerate framework to convert from BGRA to RGBA
        var bgraBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: bgraBytes),
                    height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytesPerRow)
        let rgbaBytes = [UInt8](repeating: 0, count: totalBytes)
        var rgbaBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: rgbaBytes),
                    height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: bytesPerRow)
        let map: [UInt8] = [2, 1, 0, 3]
        vImagePermuteChannels_ARGB8888(&bgraBuffer, &rgbaBuffer, map, 0)
        // flipping image vertically
        let flippedBytes = bgraBytes // share the buffer
        var flippedBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: flippedBytes),
                    height: vImagePixelCount(self.height), width: vImagePixelCount(self.width), rowBytes: bytesPerRow)
        vImageVerticalReflect_ARGB8888(&rgbaBuffer, &flippedBuffer, 0)
        // create CGImage with RGBA Flipped Bytes
        guard let data = CFDataCreate(nil, flippedBytes, totalBytes) else { return nil }
        guard let dataProvider = CGDataProvider(data: data) else { return nil }
        let cgImage = CGImage(width: self.width,
                              height: self.height,
                              bitsPerComponent: 8,
                              bitsPerPixel: 8 * numComponents,
                              bytesPerRow: bytesPerRow,
                              space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue),
                              provider: dataProvider,
                              decode: nil,
                              shouldInterpolate: true,
                              intent: .defaultIntent)
        guard let cgImage = cgImage else { return nil }
        return UIImage(cgImage: cgImage)
    }

}
