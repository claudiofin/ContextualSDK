//
//  SignatureView.swift
//  ContextualUI
//
//  PencilKit-based signature capture with proper dark mode support
//

import SwiftUI
import ContextualSDK

#if canImport(UIKit) && canImport(PencilKit)
import UIKit
import PencilKit

public struct SignatureView: View {
    @Binding var signatureData: Data?
    @State private var canvasView: PKCanvasView
    @State private var hasDrawn = false
    @State private var previewImage: UIImage? = nil
    @Environment(\.colorScheme) private var colorScheme
    
    public init(signatureData: Binding<Data?>) {
        self._signatureData = signatureData
        let canvas = PKCanvasView()
        // Use cream/off-white for better visibility in both modes
        canvas.backgroundColor = UIColor(red: 0.98, green: 0.97, blue: 0.94, alpha: 1.0)
        canvas.isOpaque = true
        canvas.drawingPolicy = .anyInput
        canvas.tool = PKInkingTool(.pen, color: .black, width: 3)
        // Force light mode to ensure we get a "paper" look with black ink
        // regardless of the app's color scheme
        canvas.overrideUserInterfaceStyle = .light
        self._canvasView = State(initialValue: canvas)
    }
    
    public var body: some View {
        VStack(spacing: 12) {
            // Canvas area
            ZStack {
                // Cream/paper background for signature
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.98, green: 0.97, blue: 0.94))
                    .shadow(color: .black.opacity(0.1), radius: 3)
                
                // Border - darker for visibility
                RoundedRectangle(cornerRadius: 12)
                    .stroke(hasDrawn ? Color.green : Color.gray, lineWidth: 2)
                
                // Signature line hint
                if !hasDrawn {
                    VStack {
                        Spacer()
                        HStack {
                            Text("✗")
                                .font(.title3)
                                .foregroundColor(.gray)
                            
                            Rectangle()
                                .fill(Color.gray.opacity(0.5))
                                .frame(height: 2)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 30)
                    }
                    
                    // Hint text
                    Text("Sign Here")
                        .font(.caption)
                        .foregroundColor(.gray.opacity(0.7))
                }
                
                // The actual drawing canvas
                SignatureCanvasWrapper(
                    canvasView: canvasView,
                    hasDrawn: $hasDrawn,
                    onDrawingChanged: { updatePreview() }
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .frame(height: 180)
            
            // Preview & Controls
            HStack(spacing: 16) {
                // Clear button
                Button {
                    clearSignature()
                } label: {
                    Label("Clear", systemImage: "trash")
                        .font(.subheadline)
                        .foregroundStyle(.red)
                }
                .disabled(!hasDrawn)
                
                Spacer()
                
                // Status indicator
                if hasDrawn {
                    HStack(spacing: 6) {
                        // Mini preview
                        if let img = previewImage {
                            Image(uiImage: img)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 50, height: 35)
                                .background(Color(red: 0.98, green: 0.97, blue: 0.94))
                                .cornerRadius(4)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.green, lineWidth: 1)
                                )
                        }
                        
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text("Signed")
                            .font(.caption.bold())
                            .foregroundStyle(.green)
                    }
                } else {
                    Text("Draw your signature above")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func clearSignature() {
        canvasView.drawing = PKDrawing()
        hasDrawn = false
        signatureData = nil
        previewImage = nil
    }
    
    private func updatePreview() {
        let drawing = canvasView.drawing
        guard !drawing.bounds.isEmpty else {
            previewImage = nil
            signatureData = nil
            return
        }
        
        let paddedBounds = drawing.bounds.insetBy(dx: -10, dy: -10)
        let image = drawing.image(from: paddedBounds, scale: 2.0)
        previewImage = image
        signatureData = image.pngData()
    }
}

// MARK: - Canvas Wrapper

struct SignatureCanvasWrapper: UIViewRepresentable {
    let canvasView: PKCanvasView
    @Binding var hasDrawn: Bool
    let onDrawingChanged: () -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.delegate = context.coordinator
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        var parent: SignatureCanvasWrapper
        
        init(_ parent: SignatureCanvasWrapper) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            let drawn = !canvasView.drawing.bounds.isEmpty
            if parent.hasDrawn != drawn {
                parent.hasDrawn = drawn
            }
            parent.onDrawingChanged()
        }
    }
}

#else

// Fallback for macOS
public struct SignatureView: View {
    @Binding var signatureData: Data?
    
    public init(signatureData: Binding<Data?>) {
        self._signatureData = signatureData
    }
    
    public var body: some View {
        VStack {
            Image(systemName: "signature")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Signature not available on this platform")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
        .background(Color(red: 0.98, green: 0.97, blue: 0.94))
        .cornerRadius(12)
    }
}

#endif
