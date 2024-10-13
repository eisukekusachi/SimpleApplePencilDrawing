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

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        canvasViewModel.onViewDidAppear(canvasView: canvasView)
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
        canvasView.updateTexturePublisher
            .sink { [weak self] in
                guard let `self` else { return }
                self.canvasViewModel.onUpdateRenderTexture(
                    canvasView: self.canvasView
                )
            }
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
        canvasViewModel.onPencilGestureDetected(
            touches: touches,
            with: event,
            view: view,
            canvasView: canvasView
        )
    }

    func sendPencilActualTouches(_ touches: Set<UITouch>, on view: UIView) {
        canvasViewModel.onPencilGestureDetected(
            actualTouches: touches,
            view: view,
            canvasView: canvasView
        )
    }

}

extension CanvasViewController {

    @objc func didTap(_ gesture: UITapGestureRecognizer) -> Void {
        canvasViewModel.onTapClearTexture(canvasView: canvasView)
    }

}
