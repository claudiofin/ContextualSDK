//
//  Logger+Contextual.swift
//  ContextualSDK
//
//  Created by ContextualSDK.
//

import OSLog

extension Logger {
    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.contextual.sdk"

    /// Logs related to the AI/Brain logic
    public static let brain = Logger(subsystem: subsystem, category: "Brain")
    
    /// Logs related to UI rendering
    public static let ui = Logger(subsystem: subsystem, category: "UI")
    
    /// Logs related to core SDK functions
    public static let core = Logger(subsystem: subsystem, category: "Core")
}
