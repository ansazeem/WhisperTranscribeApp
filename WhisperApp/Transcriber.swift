import Foundation
import WhisperKit

class Transcriber {
    private let whisper: WhisperKit

    init(whisper: WhisperKit) {
        self.whisper = whisper
    }

    func transcribe(audioURL: URL, language: String?) async throws -> String {
        let options = DecodingOptions(task: .transcribe, language: "ur")
        print("[DEBUG] Transcribing: \(audioURL.lastPathComponent)")

        let start = CFAbsoluteTimeGetCurrent()
        let result = try await whisper.transcribe(audioPath: audioURL.path, decodeOptions: options)
        let duration = CFAbsoluteTimeGetCurrent() - start
        print("[BENCHMARK] Transcription time: \(String(format: "%.2f", duration))s")

        let combinedText = result.map { $0.text }.joined(separator: " ")
        return combinedText
    }
}
