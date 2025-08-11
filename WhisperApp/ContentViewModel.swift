import Foundation
import WhisperKit

@MainActor
class ContentViewModel: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isLoadingModel = false
    @Published var selectedModel = "small" // Default selection
    var whisper: WhisperKit?
    
    let availableModels = ["tiny", "base", "small", "medium", "large"]

    func loadModel() async {
        isLoadingModel = true
        
        let computeOptions = ModelComputeOptions(
            melCompute: .cpuAndGPU,
            audioEncoderCompute: .cpuAndGPU,
            textDecoderCompute: .cpuAndGPU,
            prefillCompute: .cpuOnly
        )
        
        do {
            print("[DEBUG] Loading WhisperKit with model: \(selectedModel)")
            
            // Model folder in bundle
            let folderName = "openai_whisper-\(selectedModel)"
            guard let modelFolderURL = Bundle.main.url(forResource: folderName, withExtension: nil) else {
                fatalError("Model folder '\(folderName)' not found in bundle")
            }
            
            let config = WhisperKitConfig(
                model: selectedModel,
                modelFolder: modelFolderURL.path,
                computeOptions: computeOptions,
                verbose: false,
                download: false
            )
            
            let whisperKit = try await WhisperKit(config)
            
            let startTime = CFAbsoluteTimeGetCurrent()
            try await whisperKit.loadModels()
            let duration = CFAbsoluteTimeGetCurrent() - startTime
            
            print("[BENCHMARK] Model load time: \(String(format: "%.2f", duration))s")
            self.whisper = whisperKit
           
            self.isModelLoaded = true
            
            
        } catch {
            print("[DEBUG] Failed to load model: \(error)")
        }
        
        isLoadingModel = false
    }
}
