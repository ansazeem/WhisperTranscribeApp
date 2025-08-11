import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ContentViewModel()
    
    @State private var transcription: String = ""
    @State private var selectedLanguage: String = "en"
    @State private var isTranscribing = false
    @State private var selectedFileURL: URL?
    @State private var showingFilePicker = false
    @State private var transcriptionTime: Double?

    var body: some View {
        VStack(spacing: 20) {
            Text("Whisper Transcriber")
                .font(.title)

            Picker("Language", selection: $selectedLanguage) {
                Text("English").tag("en")
                Text("Urdu").tag("ur")
            }
            .pickerStyle(.segmented)

            if viewModel.isLoadingModel {
                ProgressView("Loading model...")
            } else {
                Button(action: {
                    Task {
                        await viewModel.loadModel()
                    }
                }) {
                    Text(viewModel.isModelLoaded ? "✅ Model Loaded" : "Load Model")
                }
                .disabled(viewModel.isModelLoaded)
            }

            Button(action: {
                showingFilePicker = true
            }) {
                Text(isTranscribing ? "Transcribing..." : "Choose Audio File")
            }
            .disabled(!viewModel.isModelLoaded || isTranscribing)

            if let time = transcriptionTime {
                Text(String(format: "⏱ Transcription Time: %.2f seconds", time))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }

            ScrollView {
                Text(transcription)
                    .padding()
            }
        }
        .padding()
        .sheet(isPresented: $showingFilePicker) {
            DocumentPicker(selectedFileURL: $selectedFileURL)
        }
        .onChange(of: selectedFileURL) { _, _ in
            if let url = selectedFileURL {
                transcribe(from: url)
            }
        }
    }

    private func transcribe(from url: URL) {
        isTranscribing = true
        transcription = "Processing..."
        transcriptionTime = nil

        Task {
            do {
                guard let whisper = viewModel.whisper else {
                    transcription = "Model not loaded"
                    return
                }

                let start = Date()

                // Copy file to Documents dir
                let fileManager = FileManager.default
                let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destURL = docsURL.appendingPathComponent(url.lastPathComponent)
                if fileManager.fileExists(atPath: destURL.path) {
                    try fileManager.removeItem(at: destURL)
                }
                try fileManager.copyItem(at: url, to: destURL)

                let transcriber = Transcriber(whisper: whisper)
                let result = try await transcriber.transcribe(audioURL: destURL, language: selectedLanguage)

                let duration = Date().timeIntervalSince(start)
                transcriptionTime = duration
                transcription = result
            } catch {
                transcription = "Error: \(error.localizedDescription)"
            }
            isTranscribing = false
        }
    }
}
