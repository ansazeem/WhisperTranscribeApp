import Foundation
import WhisperKit

@MainActor
class ContentViewModel: ObservableObject {
    @Published var isBenchmarking = false
    @Published var selectedAudioFile: URL?
    @Published var isBenchmarkRunning = false
    @Published var benchmarkResults: [BenchmarkResult]?

    func runBenchmark() {
        guard let file = selectedAudioFile else {
            print("[ERROR] No file selected.")
            return
        }

        isBenchmarkRunning = true
        Task {
            let runner = BenchmarkRunner(audioURL: file)
            let results = await runner.runAllBenchmarks()
            await MainActor.run {
                self.benchmarkResults = results
                self.isBenchmarkRunning = false
            }
        }
    }
}
