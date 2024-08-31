//
//  CanvasViewController.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/01.
//

import UIKit
import Combine

class CanvasViewController: UIViewController {

    @IBOutlet private weak var canvasView: CanvasView!

    private let canvasViewModel = CanvasViewModel()

    private var cancellables = Set<AnyCancellable>()

    override func viewDidLoad() {
        super.viewDidLoad()

        subscribeEvents()
        bindViewModel()
        setupCanvasViewModel()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        canvasViewModel.onViewDidAppear(
            canvasView.drawableSize,
            canvasView: canvasView
        )
    }

}

extension CanvasViewController {

    private func setupCanvasViewModel() {
        // Initialize the texture with any size
        /*
        canvasViewModel.initCanvas(
            textureSize: .init(width: 768, height: 1024),
            canvasView: canvasView
        )
        */
    }

    private func subscribeEvents() {
        // Remove `/* */` to enable finger drawing
        /*
        canvasView.addGestureRecognizer(
            CanvasFingerInputGestureRecognizer(self)
        )
        */
        canvasView.addGestureRecognizer(
            CanvasPencilInputGestureRecognizer(self)
        )

        // Add a gesture recognizer to clear the canvas when the screen is tapped with three fingers.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGesture.numberOfTouchesRequired = 3
        canvasView.addGestureRecognizer(tapGesture)
    }

    private func bindViewModel() {
        canvasViewModel.pauseDisplayLinkPublish
            .receive(on: DispatchQueue.main)
            .assign(to: \.isPaused, on: canvasView.displayLink)
            .store(in: &cancellables)
    }

}

extension CanvasViewController: CanvasFingerInputGestureSender {

    func sendFingerTouches(_ touches: Set<UITouch>, with event: UIEvent?, on view: UIView) {
        canvasViewModel.onFingerInputGesture(
            touches: touches,
            view: self.view,
            canvasView: canvasView
        )
    }

}

extension CanvasViewController: CanvasPencilInputGestureSender {

    func sendPencilEstimatedTouches(_ touches: Set<UITouch>, with event: UIEvent?, on view: UIView) {
        canvasViewModel.onPencilInputGesture(
            touches: touches,
            with: event,
            view: view,
            canvasView: canvasView
        )
    }

    func sendPencilActualTouches(_ touches: Set<UITouch>, on view: UIView) {

    }

}

extension CanvasViewController {

    @objc func didTap(_ gesture: UITapGestureRecognizer) -> Void {
        canvasViewModel.onTapClearTexture(canvasView: canvasView)
    }

}
