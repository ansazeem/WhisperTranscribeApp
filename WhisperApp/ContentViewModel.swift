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
            melCompute: .cpuAndNeuralEngine,
            audioEncoderCompute: .cpuAndNeuralEngine,
            textDecoderCompute: .cpuAndNeuralEngine,
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
                prewarm: true,
                download: false
                
            )
            
            let startTime = CFAbsoluteTimeGetCurrent()
            let whisperKit = try await WhisperKit(config)
            let afterInitTime = CFAbsoluteTimeGetCurrent()

            try await whisperKit.loadModels()
            let afterLoadTime = CFAbsoluteTimeGetCurrent()

            print("[BENCHMARK] Init time: \(String(format: "%.2f", afterInitTime - startTime))s")
            print("[BENCHMARK] LoadModels time: \(String(format: "%.2f", afterLoadTime - afterInitTime))s")
            print("[BENCHMARK] Total model loading time: \(String(format: "%.2f", afterLoadTime - startTime))s")

            self.whisper = whisperKit
           
            self.isModelLoaded = true
            
            
        } catch {
            print("[DEBUG] Failed to load model: \(error)")
        }
        
        isLoadingModel = false
    }
}
