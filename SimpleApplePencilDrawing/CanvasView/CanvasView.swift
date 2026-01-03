//
//  CanvasView.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2026/01/10.
//

import Combine
import UIKit

@preconcurrency import MetalKit

@objc public class CanvasView: UIView {

    private let displayView: CanvasDisplayView

    private var viewModel: CanvasViewModel

    /// The single Metal device instance used throughout the app
    private let sharedDevice: MTLDevice

    private let renderer: MTLRendering

    private let brushDrawingRenderer = BrushDrawingRenderer()

    private var cancellables = Set<AnyCancellable>()

    /// The size of the screen
    static var screenSize: CGSize {
        let scale = UIScreen.main.scale
        let size = UIScreen.main.bounds.size
        return .init(
            width: size.width * scale,
            height: size.height * scale
        )
    }

    public init() {
        do {
            guard let sharedDevice = MTLCreateSystemDefaultDevice() else {
                throw NSError()
            }
            self.sharedDevice = sharedDevice
            self.renderer = MTLRenderer(device: sharedDevice)
            self.displayView = .init(renderer: renderer)
            self.viewModel = .init(
                displayView: displayView,
                canvasRenderer: .init(renderer: renderer, displayView: displayView)
            )
            super.init(frame: .zero)
        } catch {
            fatalError("Metal is not supported on this device.")
        }
    }
    public required init?(coder: NSCoder) {
        do {
            guard let sharedDevice = MTLCreateSystemDefaultDevice() else {
                throw NSError()
            }
            self.sharedDevice = sharedDevice
            self.renderer = MTLRenderer(device: sharedDevice)
            self.displayView = .init(renderer: renderer)
            self.viewModel = .init(
                displayView: displayView,
                canvasRenderer: .init(renderer: renderer, displayView: displayView)
            )
            super.init(frame: .zero)
        } catch {
            fatalError("Metal is not supported on this device.")
        }
    }

    public func setup(textureSize: CGSize? = nil) throws {
        layoutViews()
        addEvents()
        bindData()

        brushDrawingRenderer.setup(renderer: renderer)

        try self.viewModel.setup(
            drawingRenderer: brushDrawingRenderer,
            textureSize: textureSize ?? CanvasView.screenSize
        )
    }

    private func layoutViews() {
        addSubview(displayView)
        displayView.isUserInteractionEnabled = false
        displayView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            displayView.topAnchor.constraint(equalTo: topAnchor),
            displayView.bottomAnchor.constraint(equalTo: bottomAnchor),
            displayView.leadingAnchor.constraint(equalTo: leadingAnchor),
            displayView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
    }

    private func addEvents() {
        addGestureRecognizer(
            PencilInputGestureRecognizer(delegate: self)
        )

        // Add a gesture recognizer to clear the canvas when the screen is tapped with three fingers.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGesture.numberOfTouchesRequired = 3
        addGestureRecognizer(tapGesture)
    }

    private func bindData() {
        displayView.displayTextureSizeChanged
            .sink { [weak self] _ in
                guard let `self` else { return }
                self.viewModel.onUpdateDisplayTexture()
            }
            .store(in: &cancellables)
    }

    public override func layoutSubviews() {
        viewModel.frameSize = frame.size
    }
}

extension CanvasView: PencilInputGestureRecognizerSender {

    func sendPencilEstimatedTouches(_ touches: Set<UITouch>, with event: UIEvent?, on view: UIView) {
        viewModel.onPencilGestureDetected(
            estimatedTouches: touches,
            with: event,
            view: view
        )
    }

    func sendPencilActualTouches(_ touches: Set<UITouch>, on view: UIView) {
        viewModel.onPencilGestureDetected(
            actualTouches: touches,
            view: view
        )
    }
}

extension CanvasView {
    @objc func didTap(_ gesture: UITapGestureRecognizer) -> Void {
        viewModel.onTapClearTexture()
    }
}
