import Foundation
import WhisperKit

class Transcriber {
    private let whisper: WhisperKit

    init(whisper: WhisperKit) {
        self.whisper = whisper
    }

    /// Transcribes audio from a given file URL using the specified language
    func transcribe(audioURL: URL, language: String?) async throws -> String {
        // Build decoding options with the chosen language
        let options = DecodingOptions(
            task: .transcribe,
            language: language // "en", "ur", or nil for auto-detect
        )

        print("[DEBUG] Transcribing: \(audioURL.lastPathComponent)")
        
        let start = CFAbsoluteTimeGetCurrent()
        
        // Perform transcription
        let result = try await whisper.transcribe(
            audioPath: audioURL.path,
            decodeOptions: options
        )
        
        let duration = CFAbsoluteTimeGetCurrent() - start
        print("[BENCHMARK] Transcription time: \(String(format: "%.2f", duration))s")
        
        // Combine all segments into one string
        let combinedText = result.map { $0.text }.joined(separator: " ")
        
        print("[DEBUG] Transcription result: \(combinedText)")
        return combinedText
    }
}
