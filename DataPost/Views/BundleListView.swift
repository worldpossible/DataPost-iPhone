import SwiftUI

struct BundleListView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var transferManager = FileTransferManager.shared
    @State private var bundles: [ContentBundle] = []
    @State private var isLoading = false
    @State private var searchText = ""
    
    var filteredBundles: [ContentBundle] {
        if searchText.isEmpty {
            return bundles
        }
        return bundles.filter { $0.title.localizedCaseInsensitiveContains(searchText) }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading bundles...")
                } else if bundles.isEmpty {
                    emptyStateView
                } else {
                    bundleListView
                }
            }
            .navigationTitle("Content Bundles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadBundles) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search bundles")
            .onAppear {
                loadBundles()
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "folder.badge.questionmark")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Bundles Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Connect to a RACHEL device to see available content bundles.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Button(action: loadBundles) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
    }
    
    private var bundleListView: some View {
        List {
            Section {
                ForEach(filteredBundles) { bundle in
                    BundleRowView(bundle: bundle) {
                        // Toggle download
                        toggleBundleDownload(bundle)
                    }
                }
            } header: {
                Text("\(filteredBundles.count) bundles available")
            }
        }
    }
    
    private func loadBundles() {
        isLoading = true
        
        // Simulate loading bundles from RACHEL device
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            
            await MainActor.run {
                // Demo bundles - in real app, these would come from RACHEL API
                bundles = [
                    ContentBundle(
                        id: "wikipedia",
                        title: "Wikipedia for Schools",
                        description: "Educational articles from Wikipedia",
                        sizeBytes: 5_500_000_000,
                        isDownloaded: false,
                        category: "Encyclopedia"
                    ),
                    ContentBundle(
                        id: "khan-academy",
                        title: "Khan Academy Lite",
                        description: "Math and science video lessons",
                        sizeBytes: 3_200_000_000,
                        isDownloaded: true,
                        category: "Education"
                    ),
                    ContentBundle(
                        id: "openstax",
                        title: "OpenStax Textbooks",
                        description: "Free college textbooks",
                        sizeBytes: 1_800_000_000,
                        isDownloaded: false,
                        category: "Textbooks"
                    ),
                    ContentBundle(
                        id: "medline",
                        title: "MedLine Medical",
                        description: "Medical reference materials",
                        sizeBytes: 800_000_000,
                        isDownloaded: true,
                        category: "Health"
                    ),
                    ContentBundle(
                        id: "ck12",
                        title: "CK-12 Flexbooks",
                        description: "Interactive textbooks for K-12",
                        sizeBytes: 2_100_000_000,
                        isDownloaded: false,
                        category: "Education"
                    )
                ]
                isLoading = false
            }
        }
    }
    
    private func toggleBundleDownload(_ bundle: ContentBundle) {
        if let index = bundles.firstIndex(where: { $0.id == bundle.id }) {
            bundles[index].isDownloaded.toggle()
            
            if bundles[index].isDownloaded {
                // Start download
                transferManager.downloadBundle(bundle)
            } else {
                // Cancel/delete download
                transferManager.deleteBundle(bundle)
            }
        }
    }
}

struct BundleRowView: View {
    let bundle: ContentBundle
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(categoryColor.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: categoryIcon)
                    .font(.title2)
                    .foregroundColor(categoryColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(bundle.title)
                    .font(.headline)
                
                Text(bundle.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack {
                    Text(bundle.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.systemGray5))
                        .cornerRadius(4)
                    
                    Text(formatBytes(bundle.sizeBytes))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Download Button
            Button(action: onToggle) {
                Image(systemName: bundle.isDownloaded ? "checkmark.circle.fill" : "arrow.down.circle")
                    .font(.title2)
                    .foregroundColor(bundle.isDownloaded ? .green : .blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var categoryIcon: String {
        switch bundle.category {
        case "Encyclopedia": return "book.closed"
        case "Education": return "graduationcap"
        case "Textbooks": return "text.book.closed"
        case "Health": return "cross.case"
        default: return "folder"
        }
    }
    
    private var categoryColor: Color {
        switch bundle.category {
        case "Encyclopedia": return .blue
        case "Education": return .green
        case "Textbooks": return .orange
        case "Health": return .red
        default: return .gray
        }
    }
    
    private func formatBytes(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

#Preview {
    BundleListView()
}
