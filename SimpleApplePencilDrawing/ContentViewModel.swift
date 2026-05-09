//
//  ContentViewModel.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2026/05/09.
//

import Combine
import Foundation

@MainActor
class ContentViewModel: ObservableObject {

    let doSomethingSubject = PassthroughSubject<Void, Never>()

    func doSomething() {
        doSomethingSubject.send(())
    }
}
