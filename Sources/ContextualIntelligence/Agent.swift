//
//  Agent.swift
//  ContextualIntelligence
//
//  Created for ContextualSDK
//

import Foundation
import FoundationModels
import ContextualSDK
import OSLog

/// Monitors the number of turns to prevent infinite loops in multi-agent systems
@available(iOS 26.0, macOS 26.0, *)
actor MaxTurnMonitor {
    let maxTurn: Int
    var currentTurn = 0
    
    init(maxTurn: Int) {
        self.maxTurn = maxTurn
    }
    
    enum Error: Swift.Error, LocalizedError {
        case maxTurnExceeded
        
        var errorDescription: String? {
            return "Max Turn for answering user's prompt is exceeded."
        }
        
        var recoverySuggestion: String? {
            return "Please provide a response based on the information you have."
        }
    }
    
    func checkAndIncrement() throws {
        currentTurn += 1
        if currentTurn > maxTurn {
            throw Error.maxTurnExceeded
        }
    }
}

/// A Tool definition that wraps an Agent, allowing it to be called by other Agents
@available(iOS 26.0, macOS 26.0, *)
struct AgentTool: Tool {
    let name: String
    let description: String
    // Agent is a class, so we need to ensure it's handled safely.
    // In this context, tools are usually stateless copies, but here we reference a shared agent.
    // We mark it as valid because we handle concurrency via internal actors (LanguageModelSession is thread-safe).
    var agent: Agent

    @Generable
    struct Arguments {
        @Guide(description: "A prompt for the agent to respond to.")
        let prompt: String
    }
    
    func call(arguments: Arguments) async throws -> String {
        Logger.brain.debug("[AgentTool] Running sub-agent: \(name)")
        
        // Use do-catch to allow the calling agent to recover or report the error gracefully
        do {
            return try await self.agent._run(prompt: arguments.prompt)
        } catch {
            Logger.brain.error("[AgentTool] Error in sub-agent \(name): \(error.localizedDescription)")
            
            if let localizedError = error as? LocalizedError, let suggestion = localizedError.recoverySuggestion {
                return "Error: \(error.localizedDescription) \nSuggestion: \(suggestion)"
            }
            return "Error: \(error.localizedDescription)"
        }
    }
}

/// A reusable AI Agent that wraps a LanguageModelSession and can be used as a Tool
/// Marked @unchecked Sendable because established patterns for Agents often involve shared state managed internally.
/// `LanguageModelSession` handles its own concurrency.
@available(iOS 26.0, macOS 26.0, *)
class Agent: @unchecked Sendable {
    let name: String
    let session: LanguageModelSession
    
    // Optional transform to modify the prompt before sending it to the model
    let promptTransformer: ((String) -> String)?
    
    // Protected by its own actor serialization
    var maxTurnMonitor: MaxTurnMonitor?
    
    // Keep track of sub-agents to propagate the monitor
    private let subAgents: [Agent]
    
    init(
        name: String,
        instructions: String,
        tools: [any Tool] = [],
        promptTransformer: ((String) -> String)? = nil
    ) {
        self.name = name
        self.promptTransformer = promptTransformer
        
        // filter out tools that are actually AgentTools to manage their state
        self.subAgents = tools.compactMap { $0 as? AgentTool }.map { $0.agent }
        
        // Initialize session with tools and instructions
        self.session = LanguageModelSession(tools: tools) {
            instructions
        }
    }
    
    /// Entry point for running the agent
    /// - Parameters:
    ///   - prompt: The user prompt
    ///   - maxTurn: Optional maximum number of turns (calls) allowed for this request tree
    @discardableResult
    func run(prompt: String, maxTurn: Int? = nil) async throws -> String {
        if let maxTurn {
            self.maxTurnMonitor = MaxTurnMonitor(maxTurn: maxTurn)
        } else {
            // If calling run() effectively restarts usage as a top-level agent, implies new monitor or nil
            self.maxTurnMonitor = nil
        }
        
        // Propagate monitor to all sub-agents
        for sub in self.subAgents {
            // function is not async in the original code, but actor isolation requires await or sync access?
            // Actually, since Agent is a class, we can set this directly if we are careful,
            // or we delegate it.
            // Since we are inside an async context (run), we can just set it.
            // But `setMaxTurnMonitor` wasn't async in the previous code, checking warning...
            // "no 'async' operations occur within 'await' expression" meant it WAS NOT async.
            sub.setMaxTurnMonitor(self.maxTurnMonitor)
        }
        
        return try await _run(prompt: prompt)
    }

    /// Internal run method used by AgentTool to share the monitor
    func _run(prompt: String) async throws -> String {
        try await maxTurnMonitor?.checkAndIncrement()

        let finalPrompt = self.promptTransformer?(prompt) ?? prompt
        
        // Log the interaction
        Logger.brain.debug("[Agent: \(self.name)] Responding to prompt...")
        
        let response = try await session.respond(to: finalPrompt)
        
        Logger.brain.debug("[Agent: \(self.name)] content: \(response.content)")
        return response.content
    }
    
    /// Converts this Agent into a Tool that can be used by others
    func asTool(description: String, name: String? = nil) -> AgentTool {
        return AgentTool(name: name ?? self.name, description: description, agent: self)
    }
    
    /// Helper to set the shared monitor
    func setMaxTurnMonitor(_ monitor: MaxTurnMonitor?) {
        self.maxTurnMonitor = monitor
        // Propagate recursively
        for sub in self.subAgents {
            sub.setMaxTurnMonitor(monitor)
        }
    }
}
