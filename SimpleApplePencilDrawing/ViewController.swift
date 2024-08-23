//
//  ViewController.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2024/06/01.
//

import UIKit
import Combine

class ViewController: UIViewController {

    @IBOutlet private weak var canvasView: MTKRenderTextureView!

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
            renderTarget: canvasView
        )
    }

}

extension ViewController {

    private func setupCanvasViewModel() {
        // Initialize the texture with any size
        /*
        canvasViewModel.initCanvas(
            textureSize: .init(width: 768, height: 1024),
            renderTarget: canvasView
        )
        */
    }

    private func subscribeEvents() {
        // Remove `/* */` to enable finger drawing
        /*
        canvasView.addGestureRecognizer(
            FingerInputGestureRecognizer(self)
        )
        */

        canvasView.addGestureRecognizer(
            PencilInputGestureRecognizer(self)
        )

        // Add a gesture recognizer to clear the canvas when the screen is tapped with three fingers.
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
        tapGesture.numberOfTouchesRequired = 3
        canvasView.addGestureRecognizer(tapGesture)
    }

    private func bindViewModel() {
        canvasViewModel.pauseDisplayLinkPublish
            .receive(on: DispatchQueue.main)
            .assign(to: \.isDisplayLinkPaused, on: canvasView)
            .store(in: &cancellables)
    }

}

extension ViewController: FingerInputGestureSender {

    func sendFingerTouches(_ touches: Set<UITouch>, with event: UIEvent?, on view: UIView) {
        canvasViewModel.onFingerInputGesture(
            touches: touches.map { TouchPoint(touch: $0, view: view) },
            renderTarget: canvasView
        )
    }

}

extension ViewController: PencilInputGestureSender {

    func sendPencilTouches(_ touches: Set<UITouch>, with event: UIEvent?, on view: UIView) {
        canvasViewModel.onPencilInputGesture(
            touches: touches.map { TouchPoint(touch: $0, view: view) },
            renderTarget: canvasView
        )
    }

}

extension ViewController {

    @objc func didTap(_ gesture: UITapGestureRecognizer) -> Void {
        canvasViewModel.onTapClearTexture(renderTarget: canvasView)
    }

}
