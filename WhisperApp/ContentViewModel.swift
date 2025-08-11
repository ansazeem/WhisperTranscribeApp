import Foundation
import WhisperKit

@MainActor
class ContentViewModel: ObservableObject {
    @Published var isModelLoaded = false
    @Published var isLoadingModel = false
    var whisper: WhisperKit?
    
    func loadModel() async {
        isLoadingModel = true
        
        let computeOptions = ModelComputeOptions(
            melCompute: .cpuAndGPU,
            audioEncoderCompute: .cpuAndGPU,
            textDecoderCompute: .cpuAndGPU,
            prefillCompute: .cpuOnly
        )
        
        do {
            print("[DEBUG] Loading WhisperKit...")
            
            // Change folderName to your actual model folder in the app bundle
            let folderName = "openai_whisper-medium"
            guard let modelFolderURL = Bundle.main.url(forResource: folderName, withExtension: nil) else {
                fatalError("Model folder not found in bundle")
            }
            
            let config = WhisperKitConfig(
                model: "small",
                modelFolder: modelFolderURL.path,
                computeOptions: computeOptions,
                verbose: true,
                logLevel: .debug,
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
