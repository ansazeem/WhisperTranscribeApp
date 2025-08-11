import Foundation
import WhisperKit

struct BenchmarkResult {
    let modelName: String
    let loadTime: Double
    let transcriptionTime: Double
    let transcription: String
}

class BenchmarkRunner {
    let modelsToTest = ["tiny"/*, "base", "small", "medium"*/]
    let computeOptions = ModelComputeOptions(
        melCompute: .cpuAndGPU,
        audioEncoderCompute: .cpuAndGPU,
        textDecoderCompute: .cpuAndGPU,
        prefillCompute: .cpuOnly
    )
    let audioURL: URL

    init(audioURL: URL) {
        self.audioURL = audioURL
    }

    func runAllBenchmarks() async -> [BenchmarkResult] {
        var results: [BenchmarkResult] = []

        for modelName in modelsToTest {
            print("[BENCHMARK] Starting benchmark for model: \(modelName)")
            print("Bundle path:", Bundle.main.bundlePath)
            print("Contents:", try! FileManager.default.contentsOfDirectory(atPath: Bundle.main.bundlePath))

            let folderName = "openai_whisper-medium"
                guard let modelFolderURL = Bundle.main.url(forResource: folderName, withExtension: nil) else {
                    fatalError("Model folder not found for model:  \(modelName)")
                }
            print("[BENCHMARK] Model folder path: \(modelFolderURL)")
            guard let tokenizerFolderURL = Bundle.main.url(forResource: "tokenizer", withExtension: nil) else {
                fatalError("Tokenizer folder not found")
            }
            print("[BENCHMARK] Tokenizer folder path: \(tokenizerFolderURL)")
            let config = WhisperKitConfig(
                model: "medium",
                modelFolder: modelFolderURL.path,
                tokenizerFolder: tokenizerFolderURL,
                computeOptions: computeOptions,
                verbose: true,
                logLevel: .debug,
                download: false
            )

            do {
                let whisper = try await WhisperKit(config)
                let loadStart = CFAbsoluteTimeGetCurrent()
                try await whisper.loadModels()
                let loadDuration = CFAbsoluteTimeGetCurrent() - loadStart
                print("[BENCHMARK] Loaded \(modelName) in \(String(format: "%.2f", loadDuration))s")
                
                let transcribeStart = CFAbsoluteTimeGetCurrent()
                let options = DecodingOptions(language: "ur")
                let result = try await whisper.transcribe(audioPath: audioURL.path, decodeOptions:options)
                let transcript = result.map { $0.text }.joined(separator: " ")
                print("[BENCHMARK] Transcription result: \(transcript)")
                let fullText = result.map { $0.text }.joined(separator: " ")
                let transcribeDuration = CFAbsoluteTimeGetCurrent() - transcribeStart

                let benchmarkResult = BenchmarkResult(
                    modelName: modelName,
                    loadTime: loadDuration,
                    transcriptionTime: transcribeDuration,
                    transcription: fullText
                )
                results.append(benchmarkResult)
            } catch {
                print("[BENCHMARK] Failed to benchmark \(modelName): \(error)")
            }
        }

        return results
    }
}
