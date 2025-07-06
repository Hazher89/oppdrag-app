//
//  PDFViewerView.swift
//  Oppdrag
//
//  Created by Hazher  on 05/07/2025.
//

import SwiftUI
import PDFKit

struct PDFViewerView: View {
    let url: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var pdfDocument: PDFDocument?
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading PDF...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else if let errorMessage = errorMessage {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Error Loading PDF")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text(errorMessage)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        Button("Try Again") {
                            loadPDF()
                        }
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else if let pdfDocument = pdfDocument {
                    PDFKitView(document: pdfDocument)
                } else {
                    VStack(spacing: 20) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        
                        Text("PDF Not Available")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Text("The assignment PDF could not be loaded.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                }
            }
            .navigationTitle("Assignment PDF")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                if pdfDocument != nil {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: sharePDF) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                }
            }
        }
        .onAppear {
            loadPDF()
        }
    }
    
    private func loadPDF() {
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                guard let url = URL(string: url) else {
                    throw PDFError.invalidURL
                }
                
                let (data, response) = try await URLSession.shared.data(from: url)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    throw PDFError.downloadFailed
                }
                
                guard let document = PDFDocument(data: data) else {
                    throw PDFError.invalidPDF
                }
                
                await MainActor.run {
                    self.pdfDocument = document
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
    
    private func sharePDF() {
        guard let pdfDocument = pdfDocument,
              let data = pdfDocument.dataRepresentation() else { return }
        
        let activityVC = UIActivityViewController(
            activityItems: [data],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(activityVC, animated: true)
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    let document: PDFDocument
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.document = document
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ uiView: PDFView, context: Context) {
        uiView.document = document
    }
}

enum PDFError: Error, LocalizedError {
    case invalidURL
    case downloadFailed
    case invalidPDF
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid PDF URL"
        case .downloadFailed:
            return "Failed to download PDF"
        case .invalidPDF:
            return "Invalid PDF file"
        }
    }
}

#Preview {
    PDFViewerView(url: "https://example.com/sample.pdf")
} 