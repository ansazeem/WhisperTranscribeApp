import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ContentViewModel()
    @State private var showPicker = false

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button("Pick Audio File") {
                    showPicker = true
                }

                if let selected = viewModel.selectedAudioFile {
                    Text("Selected: \(selected.lastPathComponent)")
                        .font(.caption)
                        .lineLimit(1)
                }

                Button("Run Benchmark") {
                    viewModel.runBenchmark()
                }
                .disabled(viewModel.selectedAudioFile == nil || viewModel.isBenchmarkRunning)

                if viewModel.isBenchmarkRunning {
                    ProgressView("Running benchmarks…")
                }

                if let results = viewModel.benchmarkResults {
                    List(results, id: \.modelName) { result in
                        VStack(alignment: .leading) {
                            Text(result.modelName)
                                .bold()
                            Text("Load Time: \(String(format: "%.2fs", result.loadTime))")
                            Text("Transcription Time: \(String(format: "%.2fs", result.transcriptionTime))")
                            Text("Transcription: \(result.transcription)")
                          
                        }
                    }
                }
            }
            .sheet(isPresented: $showPicker) {
                FilePicker { url in
                    viewModel.selectedAudioFile = url
                    showPicker = false
                }
            }
            .navigationTitle("WhisperKit Benchmark")
            .padding()
        }
    }
}
