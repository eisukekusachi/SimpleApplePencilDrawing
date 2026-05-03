//
//  ContentView.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2025/12/31.
//

import UIKit
import SwiftUI

struct ContentView: View {
    var body: some View {
        CanvasViewRepresentable()
            .ignoresSafeArea()
    }
}

struct CanvasViewRepresentable: UIViewRepresentable {
    func makeUIView(context: Context) -> CanvasView {
        let canvasView = CanvasView()
        do {
            try canvasView.setup()
        } catch {
            fatalError("Failed to initialize the canvas")
        }
        return canvasView
    }

    func updateUIView(_ uiView: CanvasView, context: Context) {}
    static func dismantleUIView(_ uiView: CanvasView, coordinator: ()) {}
}

#Preview {
    ContentView()
}
