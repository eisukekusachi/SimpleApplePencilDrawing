//
//  Logger.swift
//  SimpleApplePencilDrawing
//
//  Created by Eisuke Kusachi on 2025/02/19.
//
import Foundation
import os

public enum Logger {
    #if DEBUG
    public static let standard: os.Logger = .init(
        subsystem: Bundle.main.bundleIdentifier!,
        category: LogCategory.standard.rawValue
    )
    #else
    public static let standard: os.Logger? = nil
    #endif
}

private enum LogCategory: String {
    case standard = "Standard"
}
