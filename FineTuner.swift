import Foundation
import SwiftUI

class FineTuner: ObservableObject {
    @Published var settings = TrainingSettings()
    @Published var isTraining = false
    @Published var progress: Double = 0.0
    @Published var currentEpoch = 0
    @Published var currentLoss: Double = 0.0
    @Published var trainingLogs: [String] = []
    @Published var hasTrainedModel = false
    
    private var trainingProcess: Process?
    private var timer: Timer?
    
    func startTraining(dataFile: URL) {
        isTraining = true
        progress = 0.0
        currentEpoch = 0
        currentLoss = 0.0
        trainingLogs.removeAll()
        
        // Simulate training process
        addLog("🔧 Loading model and tokenizer...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.addLog("📚 Loading data from \(dataFile.lastPathComponent)")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            self.addLog("🔢 Tokenizing data...")
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 6) {
            self.addLog("🚀 Starting training...")
            self.startSimulatedTraining()
        }
    }
    
    private func startSimulatedTraining() {
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            if self.currentEpoch < self.settings.epochs {
                self.currentEpoch += 1
                self.currentLoss = Double.random(in: 1.0...4.0)
                self.progress = Double(self.currentEpoch) / Double(self.settings.epochs)
                self.addLog("✅ Epoch \(self.currentEpoch) finished with loss \(String(format: "%.4f", self.currentLoss))")
            } else {
                self.finishTraining()
            }
        }
    }
    
    private func finishTraining() {
        timer?.invalidate()
        timer = nil
        
        addLog("💾 Saving fine-tuned model...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.addLog("✅ Training completed successfully!")
            self.isTraining = false
            self.hasTrainedModel = true
            self.progress = 1.0
        }
    }
    
    func stopTraining() {
        timer?.invalidate()
        timer = nil
        trainingProcess?.terminate()
        isTraining = false
        addLog("⏹️ Training stopped by user")
    }
    
    func testModel() {
        addLog("🧪 Testing fine-tuned model...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.addLog("Model Response: Merhaba! Ben senin eğittiğin model!")
            self.addLog("✅ Model test completed!")
        }
    }
    
    private func addLog(_ message: String) {
        trainingLogs.append(message)
        
        // Keep only last 20 logs
        if trainingLogs.count > 20 {
            trainingLogs = Array(trainingLogs.suffix(20))
        }
    }
}
