import SwiftUI
import UniformTypeIdentifiers

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

            // Model picker
            Picker("Model", selection: $viewModel.selectedModel) {
                ForEach(viewModel.availableModels, id: \.self) { model in
                    Text(model.capitalized).tag(model)
                }
            }
            .pickerStyle(.segmented)

            // Language picker
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
        .onChange(of: selectedFileURL) {
            if let url = selectedFileURL {
                transcribe(from: url)
            }
        }
    }

    func transcribe(from url: URL) {
        isTranscribing = true
        transcription = "Processing..."
        transcriptionTime = nil

        Task {
            do {
                guard let whisper = viewModel.whisper else {
                    print("[ERROR] WhisperKit model not loaded")
                    transcription = "Model not loaded"
                    return
                }

                let start = Date()
                print("[Transcription] Started for file: \(url.lastPathComponent) in language: \(selectedLanguage)")

                // Copy file to Documents directory for safe access
                let fileManager = FileManager.default
                let docsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
                let destURL = docsURL.appendingPathComponent(url.lastPathComponent)

                if fileManager.fileExists(atPath: destURL.path) {
                    try fileManager.removeItem(at: destURL)
                }
                try fileManager.copyItem(at: url, to: destURL)
                print("[Transcription] File copied to: \(destURL.path)")

                let transcriber = Transcriber(whisper: whisper)
                let result = try await transcriber.transcribe(audioURL: destURL, language: selectedLanguage)

                let duration = Date().timeIntervalSince(start)
                transcriptionTime = duration

                print("[Transcription] Success. Time: \(duration) seconds")
                transcription = result
            } catch {
                transcription = "Error: \(error.localizedDescription)"
                print("[Transcription] Failed with error: \(error.localizedDescription)")
            }

            isTranscribing = false
        }
    }
}
