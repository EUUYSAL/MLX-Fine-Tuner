import Foundation

struct TrainingSettings {
    var modelId = "mistralai/Mistral-7B-Instruct-v0.1"
    var outputDir = "finetuned-model"
    var epochs = 5
    var learningRate = 1e-5
    var batchSize = 8
    var maxSeqLength = 512
    var verboseLogging = false
    var saveCheckpoints = false
}
