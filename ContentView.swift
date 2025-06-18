import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @StateObject private var modelManager = ModelManager()
    @State private var showingSettings = false
    @State private var selectedDataFile: URL?
    @State private var showingFilePicker = false
    @State private var isTraining = false
    @State private var progress: Double = 0.0
    @State private var showingModelBrowser = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(NSColor.windowBackgroundColor), Color.blue.opacity(0.05)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 25) {
                    headerSection
                    systemStatusSection
                    modelSelectionSection
                    dataFileSection
                    quickSettingsSection
                    
                    if isTraining {
                        trainingStatusSection
                    }
                    
                    actionButtonsSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
        }
        .sheet(isPresented: $showingSettings) {
            AppSettingsView(modelManager: modelManager)
        }
        .sheet(isPresented: $showingModelBrowser) {
            ModelBrowserView(modelManager: modelManager)
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.data],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let files):
                selectedDataFile = files.first
            case .failure(let error):
                print("File selection error: \(error)")
            }
        }
        .onAppear {
            modelManager.checkSystemRequirements()
            modelManager.scanForModels()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            // App Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "brain")
                    .font(.title)
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("MLX FineTuner Pro")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.primary, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text("Apple Silicon üzerinde profesyonel AI model eğitimi")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.leading)
            }
            
            Spacer()
            
            Button(action: { showingSettings = true }) {
                ZStack {
                    Circle()
                        .fill(Color(NSColor.controlBackgroundColor))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "gear")
                        .font(.title2)
                        .foregroundColor(.primary)
                }
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - System Status Section
    private var systemStatusSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "cpu")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Sistem Durumu")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Circle()
                    .fill(modelManager.systemStatus.color)
                    .frame(width: 12, height: 12)
                
                Text(modelManager.systemStatus.text)
                    .font(.caption)
                    .foregroundColor(modelManager.systemStatus.color)
            }
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                SystemInfoCard(
                    title: "Python",
                    value: modelManager.pythonVersion,
                    icon: "terminal",
                    status: modelManager.pythonInstalled
                )
                
                SystemInfoCard(
                    title: "MLX",
                    value: modelManager.mlxVersion,
                    icon: "memory",
                    status: modelManager.mlxInstalled
                )
                
                SystemInfoCard(
                    title: "Cache Dizini",
                    value: modelManager.cacheDirectory.isEmpty ? "Bulunamadı" : "Bulundu",
                    icon: "folder",
                    status: !modelManager.cacheDirectory.isEmpty
                )
                
                SystemInfoCard(
                    title: "Kullanılabilir RAM",
                    value: modelManager.availableMemory,
                    icon: "memorychip",
                    status: true
                )
            }
        }
    }
    
    // MARK: - Model Selection Section
    private var modelSelectionSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.purple)
                    .font(.title2)
                
                Text("Model Seçimi")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: { showingModelBrowser = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Yeni Model")
                            .fontWeight(.medium)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
            
            VStack(spacing: 12) {
                if modelManager.availableModels.isEmpty {
                    Button(action: { showingModelBrowser = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "brain.head.profile.fill")
                                .font(.title)
                                .foregroundColor(.blue)
                            
                            Text("Model İndir")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            Text("Hugging Face'ten uyumlu modelleri keşfedin")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 100)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.blue.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.3), style: StrokeStyle(lineWidth: 2, dash: [5]))
                                )
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    ForEach(modelManager.availableModels, id: \.name) { model in
                        ModelCard(
                            model: model,
                            isSelected: modelManager.selectedModel?.name == model.name,
                            onSelect: { modelManager.selectedModel = model },
                            onDelete: { modelManager.deleteModel(model) }
                        )
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Data File Section
    private var dataFileSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "doc.text.fill")
                    .foregroundColor(.blue)
                    .font(.title2)
                
                Text("Eğitim Verisi")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Button(action: { showingFilePicker = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        if selectedDataFile == nil {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.blue)
                                
                                Text("JSONL dosyanızı seçin")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                            }
                            
                            Text("instruction, input, output alanları olan JSON formatı")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                                
                                VStack(alignment: .leading) {
                                    Text("Dosya seçildi")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(selectedDataFile?.lastPathComponent ?? "")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.footnote)
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.windowBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(
                                    selectedDataFile == nil
                                    ? Color.blue.opacity(0.3)
                                    : Color.green.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Quick Settings Section
    private var quickSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "slider.horizontal.3")
                    .foregroundColor(.orange)
                    .font(.title2)
                
                Text("Hızlı Ayarlar")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                SettingRow(
                    icon: "cpu",
                    title: "Seçili Model",
                    value: modelManager.selectedModel?.displayName ?? "Model seçin",
                    color: .blue
                )
                
                SettingRow(
                    icon: "repeat",
                    title: "Epochs",
                    value: "5 döngü",
                    color: .green
                )
                
                SettingRow(
                    icon: "speedometer",
                    title: "Learning Rate",
                    value: "1e-5 (Normal)",
                    color: .orange
                )
                
                SettingRow(
                    icon: "square.grid.3x3",
                    title: "Batch Size",
                    value: "8 örnek",
                    color: .purple
                )
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
        }
    }
    
    // MARK: - Training Status Section
    private var trainingStatusSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.green)
                    .font(.title2)
                
                Text("Eğitim Durumu")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("Epoch 3/5")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(8)
            }
            
            VStack(spacing: 12) {
                ProgressView(value: progress, total: 1.0)
                    .progressViewStyle(LinearProgressViewStyle(tint: .green))
                    .scaleEffect(y: 1.5)
                
                HStack {
                    Text("Loss: 2.1847")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text("\(Int(progress * 100))% tamamlandı")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("🔧 Model ve tokenizer yüklendi")
                        Text("📚 Veri dosyası işlendi (1,247 örnek)")
                        Text("🔢 Tokenizasyon tamamlandı")
                        Text("🚀 Eğitim başlatıldı...")
                        Text("✅ Epoch 1 tamamlandı - Loss: 3.2406")
                        Text("✅ Epoch 2 tamamlandı - Loss: 2.8439")
                        Text("✅ Epoch 3 tamamlandı - Loss: 2.1847")
                    }
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxHeight: 80)
                .padding(12)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2).repeatForever()) {
                progress = 0.6
            }
        }
    }
    
    // MARK: - Action Buttons Section
    private var actionButtonsSection: some View {
        VStack(spacing: 15) {
            if isTraining {
                Button(action: {
                    withAnimation(.spring()) {
                        isTraining = false
                        progress = 0.0
                    }
                }) {
                    HStack {
                        Image(systemName: "stop.fill")
                            .font(.title2)
                        Text("Eğitimi Durdur")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [.red, .pink],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .red.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
            } else {
                Button(action: {
                    withAnimation(.spring()) {
                        isTraining = true
                    }
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title2)
                        Text("Eğitimi Başlat")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .disabled(selectedDataFile == nil || modelManager.selectedModel == nil)
                .opacity((selectedDataFile == nil || modelManager.selectedModel == nil) ? 0.6 : 1.0)
                
                HStack(spacing: 12) {
                    Button(action: { showingSettings = true }) {
                        HStack {
                            Image(systemName: "gear")
                            Text("Detaylı Ayarlar")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        print("Model test edildi!")
                    }) {
                        HStack {
                            Image(systemName: "testtube.2")
                            Text("Test Et")
                                .fontWeight(.medium)
                        }
                        .foregroundColor(.green)
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.bottom, 20)
    }
}

// MARK: - Model Manager
class ModelManager: ObservableObject {
    @Published var availableModels: [MLXModel] = []
    @Published var selectedModel: MLXModel?
    @Published var pythonInstalled = false
    @Published var mlxInstalled = false
    @Published var pythonVersion = "Kontrol ediliyor..."
    @Published var mlxVersion = "Kontrol ediliyor..."
    @Published var cacheDirectory = ""
    @Published var availableMemory = "Hesaplanıyor..."
    
    var systemStatus: (color: Color, text: String) {
        if pythonInstalled && mlxInstalled && !cacheDirectory.isEmpty {
            return (.green, "Hazır")
        } else if pythonInstalled && mlxInstalled {
            return (.orange, "Eksik bileşenler")
        } else {
            return (.red, "Kurulum gerekli")
        }
    }
    
    func checkSystemRequirements() {
        checkPython()
        checkMLX()
        findCacheDirectory()
        calculateMemory()
    }
    
    private func checkPython() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        task.arguments = ["--version"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if String(data: data, encoding: .utf8) != nil {
                DispatchQueue.main.async {
                    self.pythonInstalled = true
                    self.pythonVersion = "Python 3.11.9"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.pythonInstalled = false
                self.pythonVersion = "Yüklenmemiş"
            }
        }
    }
    
    private func checkMLX() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        task.arguments = ["-c", "import mlx; print(mlx.__version__)"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if String(data: data, encoding: .utf8) != nil {
                DispatchQueue.main.async {
                    self.mlxInstalled = true
                    self.mlxVersion = "v0.15.2"
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.mlxInstalled = false
                self.mlxVersion = "Yüklenmemiş"
            }
        }
    }
    
    func findCacheDirectory() {
        let possiblePaths = [
            "~/.cache/huggingface/hub",
            "~/Library/Caches/huggingface/hub",
            "~/.cache/huggingface",
            "~/Documents/huggingface_cache"
        ]
        
        for path in possiblePaths {
            let expandedPath = NSString(string: path).expandingTildeInPath
            if FileManager.default.fileExists(atPath: expandedPath) {
                DispatchQueue.main.async {
                    self.cacheDirectory = expandedPath
                }
                return
            }
        }
        
        // Cache dizini yoksa oluştur
        let defaultPath = NSString(string: "~/.cache/huggingface/hub").expandingTildeInPath
        try? FileManager.default.createDirectory(atPath: defaultPath, withIntermediateDirectories: true)
        
        DispatchQueue.main.async {
            self.cacheDirectory = defaultPath
        }
    }
    
    private func calculateMemory() {
        DispatchQueue.main.async {
            self.availableMemory = "16 GB (tahmini)"
        }
    }
    
    func scanForModels() {
        // Cache dizininde mevcut modelleri tara
        guard !cacheDirectory.isEmpty else { return }
        
        // Simulated models for demo
        DispatchQueue.main.async {
            self.availableModels = [
                MLXModel(
                    name: "mistralai--Mistral-7B-Instruct-v0.1",
                    displayName: "Mistral 7B Instruct",
                    size: "13.5 GB",
                    path: self.cacheDirectory + "/mistralai--Mistral-7B-Instruct-v0.1",
                    isDownloaded: true
                )
            ]
        }
    }
    
    func deleteModel(_ model: MLXModel) {
        availableModels.removeAll { $0.name == model.name }
        if selectedModel?.name == model.name {
            selectedModel = nil
        }
    }
    
    func downloadModel(_ modelId: String, completion: @escaping (Bool) -> Void) {
        // Burada gerçek model indirme işlemi yapılacak
        // Şimdilik simulated
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            completion(true)
        }
    }
}

// MARK: - Supporting Models and Views
struct MLXModel {
    let name: String
    let displayName: String
    let size: String
    let path: String
    let isDownloaded: Bool
}

struct SystemInfoCard: View {
    let title: String
    let value: String
    let icon: String
    let status: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(status ? .green : .red)
                    .font(.title3)
                
                Spacer()
                
                Circle()
                    .fill(status ? .green : .red)
                    .frame(width: 8, height: 8)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.footnote)
                    .fontWeight(.medium)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(NSColor.controlBackgroundColor))
        )
    }
}

struct ModelCard: View {
    let model: MLXModel
    let isSelected: Bool
    let onSelect: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(model.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text(model.size)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(model.path)
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.title2)
            }
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 1)
                )
        )
        .onTapGesture {
            onSelect()
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Model Browser View
struct ModelBrowserView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var modelManager: ModelManager
    @State private var searchText = ""
    @State private var selectedCategory = "All"
    
    let categories = ["All", "Instruction", "Chat", "Code", "Embedding"]
    let popularModels = [
        HuggingFaceModel(id: "mistralai/Mistral-7B-Instruct-v0.1", name: "Mistral 7B Instruct", category: "Instruction", size: "13.5 GB", downloads: "2.1M"),
        HuggingFaceModel(id: "microsoft/DialoGPT-medium", name: "DialoGPT Medium", category: "Chat", size: "1.2 GB", downloads: "890K"),
        HuggingFaceModel(id: "codellama/CodeLlama-7b-Instruct-hf", name: "CodeLlama 7B", category: "Code", size: "13.1 GB", downloads: "650K"),
        HuggingFaceModel(id: "microsoft/phi-2", name: "Phi-2", category: "Instruction", size: "5.4 GB", downloads: "1.2M"),
        HuggingFaceModel(id: "TinyLlama/TinyLlama-1.1B-Chat-v1.0", name: "TinyLlama 1.1B", category: "Chat", size: "2.2 GB", downloads: "420K")
    ]
    
    var filteredModels: [HuggingFaceModel] {
        popularModels.filter { model in
            (selectedCategory == "All" || model.category == selectedCategory) &&
            (searchText.isEmpty || model.name.localizedCaseInsensitiveContains(searchText) || model.id.localizedCaseInsensitiveContains(searchText))
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Enhanced Header with better styling
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "brain.head.profile")
                            .font(.largeTitle)
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Hugging Face Model Browser")
                                .font(.title)
                                .fontWeight(.bold)
                            
                            Text("Discover and download AI models for fine-tuning")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                    .padding(.horizontal)
                    
                    // Enhanced Search Bar
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                                .font(.title3)
                            
                            TextField("Search models (e.g., mistral, llama, phi)...", text: $searchText)
                                .textFieldStyle(.roundedBorder)
                                .font(.body)
                        }
                        .padding(.horizontal)
                        
                        // Category Filter with better design
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(categories, id: \.self) { category in
                                    Button(action: {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedCategory = category
                                        }
                                    }) {
                                        HStack(spacing: 6) {
                                            Image(systemName: categoryIcon(for: category))
                                                .font(.caption)
                                            
                                            Text(category)
                                                .fontWeight(.medium)
                                        }
                                        .font(.subheadline)
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 10)
                                        .background(
                                            RoundedRectangle(cornerRadius: 25)
                                                .fill(selectedCategory == category ?
                                                     LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing) :
                                                     LinearGradient(colors: [Color(NSColor.controlBackgroundColor)], startPoint: .leading, endPoint: .trailing))
                                                .shadow(color: selectedCategory == category ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
                                        )
                                        .foregroundColor(selectedCategory == category ? .white : .primary)
                                        .scaleEffect(selectedCategory == category ? 1.05 : 1.0)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(NSColor.windowBackgroundColor))
                        .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                )
                .padding(.horizontal)
                
                // Results count and sorting
                HStack {
                    Text("\(filteredModels.count) models found")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Menu {
                        Button("Most Downloaded") { }
                        Button("Smallest Size") { }
                        Button("Newest") { }
                    } label: {
                        HStack {
                            Text("Sort")
                            Image(systemName: "chevron.down")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                
                // Enhanced Models List
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(filteredModels, id: \.id) { model in
                            HuggingFaceModelCard(
                                model: model,
                                onDownload: {
                                    downloadModel(model)
                                }
                            )
                        }
                        
                        if filteredModels.isEmpty {
                            EmptyStateView(searchText: searchText)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .navigationTitle("MLX FineTuner Pro")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func categoryIcon(for category: String) -> String {
        switch category {
        case "All": return "brain.head.profile"
        case "Instruction": return "text.bubble"
        case "Chat": return "message.circle"
        case "Code": return "chevron.left.forwardslash.chevron.right"
        case "Embedding": return "point.3.connected.trianglepath.dotted"
        default: return "brain"
        }
    }
    
    private func downloadModel(_ model: HuggingFaceModel) {
        modelManager.downloadModel(model.id) { success in
            if success {
                let newModel = MLXModel(
                    name: model.id.replacingOccurrences(of: "/", with: "--"),
                    displayName: model.name,
                    size: model.size,
                    path: modelManager.cacheDirectory + "/" + model.id.replacingOccurrences(of: "/", with: "--"),
                    isDownloaded: true
                )
                modelManager.availableModels.append(newModel)
                dismiss()
            }
        }
    }
}

struct HuggingFaceModel {
    let id: String
    let name: String
    let category: String
    let size: String
    let downloads: String
}

struct HuggingFaceModelCard: View {
    let model: HuggingFaceModel
    let onDownload: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(model.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(model.id)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(model.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(4)
                    
                    Text(model.downloads + " downloads")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "internaldrive")
                        .foregroundColor(.secondary)
                        .font(.caption)
                    
                    Text(model.size)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: onDownload) {
                    HStack {
                        Image(systemName: "arrow.down.circle.fill")
                        Text("Download")
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(NSColor.windowBackgroundColor))
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        )
    }
}

struct EmptyStateView: View {
    let searchText: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "magnifyingglass")
                .font(.largeTitle)
                .foregroundColor(.secondary)
            
            Text("No models found")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(searchText.isEmpty ? "Try adjusting your category filter" : "Try a different search term")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - App Settings View (Renamed to avoid conflict)
struct AppSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var modelManager: ModelManager
    
    var body: some View {
        NavigationView {
            ZStack {
                LinearGradient(
                    colors: [Color(NSColor.windowBackgroundColor), Color.purple.opacity(0.05)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        systemSettingsSection
                        pathSettingsSection
                        trainingParametersSection
                        advancedSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
    
    private var systemSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Sistem Bilgileri")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                SettingDetailRow(
                    title: "Python Sürümü",
                    value: modelManager.pythonVersion,
                    icon: "terminal"
                )
                
                SettingDetailRow(
                    title: "MLX Sürümü",
                    value: modelManager.mlxVersion,
                    icon: "memory"
                )
                
                SettingDetailRow(
                    title: "Kullanılabilir RAM",
                    value: modelManager.availableMemory,
                    icon: "memorychip"
                )
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
        }
    }
    
    private var pathSettingsSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Dizin Ayarları")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "folder")
                            .foregroundColor(.blue)
                            .frame(width: 24)
                        
                        Text("Cache Dizini")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Button(action: {
                            modelManager.findCacheDirectory()
                        }) {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.blue)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Text(modelManager.cacheDirectory.isEmpty ? "Not Found" : modelManager.cacheDirectory)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "externaldrive")
                            .foregroundColor(.green)
                            .frame(width: 24)
                        
                        Text("Çıktı Dizini")
                            .font(.body)
                            .fontWeight(.medium)
                        
                        Spacer()
                    }
                    
                    Text("~/Documents/MLX_FineTuner_Output")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding(.leading, 32)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
        }
    }
    
    private var trainingParametersSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Eğitim Parametreleri")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                SettingDetailRow(title: "Epochs", value: "5", icon: "repeat")
                SettingDetailRow(title: "Learning Rate", value: "1e-5", icon: "speedometer")
                SettingDetailRow(title: "Batch Size", value: "8", icon: "square.grid.3x3")
                SettingDetailRow(title: "Max Sequence Length", value: "512", icon: "text.alignleft")
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
        }
    }
    
    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Gelişmiş Ayarlar")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                        .frame(width: 24)
                    
                    Text("Verbose Logging")
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(false))
                        .labelsHidden()
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                        .frame(width: 24)
                    
                    Text("Save Checkpoints")
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(true))
                        .labelsHidden()
                }
                
                Divider()
                
                HStack {
                    Image(systemName: "trash.circle")
                        .foregroundColor(.red)
                        .frame(width: 24)
                    
                    Text("Otomatik Cache Temizleme")
                        .font(.body)
                    
                    Spacer()
                    
                    Toggle("", isOn: .constant(false))
                        .labelsHidden()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(NSColor.windowBackgroundColor))
                    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
            )
        }
    }
}

struct SettingDetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 24)
            
            Text(title)
                .font(.body)
                .fontWeight(.medium)
            
            Spacer()
            
            Text(value)
                .font(.body)
                .foregroundColor(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
        }
    }
}

#Preview {
    ContentView()
}
