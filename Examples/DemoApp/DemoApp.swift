//
//  DemoApp.swift
//  ContextualSDK Demo
//
//  Tab-based showcase app demonstrating all SDK features
//

import SwiftUI
import Intents
import ContextualSDK
import ContextualIntelligence
import ContextualUI

@main
struct DemoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .preferredColorScheme(.dark)
        }
    }
}

struct RootView: View {
    @State private var authorizationCompleted = false
    @State private var authorizationStatus: INSiriAuthorizationStatus = .notDetermined
    
    var body: some View {
        Group {
            if authorizationCompleted {
                MainContentView(siriStatus: authorizationStatus)
            } else {
                SiriPermissionView(
                    status: $authorizationStatus,
                    onComplete: {
                        withAnimation {
                            authorizationCompleted = true
                        }
                    }
                )
            }
        }
    }
}

// MARK: - Siri Permission Screen

struct SiriPermissionView: View {
    @Binding var status: INSiriAuthorizationStatus
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.purple.gradient)
            
            Text("Apple Intelligence")
                .font(.largeTitle.bold())
            
            Text("This app uses Apple Intelligence to analyze fields and suggest the best input method.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 40)
            
            Spacer()
            
            switch status {
            case .notDetermined:
                Button(action: requestPermission) {
                    Label("Enable Apple Intelligence", systemImage: "sparkles")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.purple)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.horizontal, 40)
                
            case .denied, .restricted:
                VStack(spacing: 12) {
                    Text("Siri is not enabled")
                        .font(.headline)
                        .foregroundStyle(.orange)
                    
                    Button("Open Settings") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            UIApplication.shared.open(url)
                        }
                    }
                    
                    Button("Continue without AI") {
                        onComplete()
                    }
                    .foregroundStyle(.secondary)
                }
                
            case .authorized:
                ProgressView("Loading...")
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            onComplete()
                        }
                    }
                
            @unknown default:
                Button("Continue") {
                    onComplete()
                }
            }
            
            Spacer()
        }
        .task {
            status = INPreferences.siriAuthorizationStatus()
            if status == .authorized {
                onComplete()
            }
        }
    }
    
    private func requestPermission() {
        INPreferences.requestSiriAuthorization { newStatus in
            DispatchQueue.main.async {
                status = newStatus
                if newStatus == .authorized {
                    onComplete()
                }
            }
        }
    }
}

// MARK: - Main Content

struct MainContentView: View {
    let siriStatus: INSiriAuthorizationStatus
    
    var body: some View {
        TabView {
            PowerShowcaseView()
                .tabItem {
                    Label("Showcase", systemImage: "sparkles")
                }
            
            OnboardingFormView()
                .tabItem {
                    Label("Registration", systemImage: "person.badge.plus")
                }
            
            PDFFormView()
                .tabItem {
                    Label("Form", systemImage: "doc.text")
                }
            
            SettingsFormView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
            
            ControlsDemoView()
                .tabItem {
                    Label("Controls", systemImage: "slider.horizontal.3")
                }
            
            WebViewGalleryView()
                .tabItem {
                    Label("WebView Gallery", systemImage: "globe")
                }
            
            DebugView()
                .tabItem {
                    Label("Debug", systemImage: "ant")
                }
        }
    }
}

#Preview {
    RootView()
}


