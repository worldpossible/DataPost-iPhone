import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var apiService = APIService.shared
    @State private var stats: CourierStats?
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    profileHeader
                    
                    Divider()
                    
                    // Stats Cards
                    if let stats = stats {
                        statsSection(stats)
                    } else if isLoading {
                        ProgressView("Loading stats...")
                            .padding()
                    } else if let error = errorMessage {
                        errorCard(error)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: loadStats) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
            .onAppear {
                loadStats()
            }
        }
    }
    
    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 100, height: 100)
                
                Text(authManager.userInitials)
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(.blue)
            }
            
            // Name & Email
            Text(authManager.userName ?? "User")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(authManager.userEmail ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Courier Badge
            HStack {
                Image(systemName: "checkmark.seal.fill")
                    .foregroundColor(.green)
                Text("Verified Courier")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.green.opacity(0.1))
            .cornerRadius(20)
        }
    }
    
    private func statsSection(_ stats: CourierStats) -> some View {
        VStack(spacing: 16) {
            Text("Your Impact")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Main Stats Grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatCard(
                    title: "RACHELs Visited",
                    value: "\(stats.devices)",
                    icon: "wifi",
                    color: .blue
                )
                
                StatCard(
                    title: "Deliveries",
                    value: "\(stats.deliveries)",
                    icon: "arrow.down.circle",
                    color: .green
                )
                
                StatCard(
                    title: "Pickups",
                    value: "\(stats.pickups)",
                    icon: "arrow.up.circle",
                    color: .orange
                )
            }
            
            // Ranking Section
            VStack(spacing: 12) {
                Text("Community Ranking")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                HStack(spacing: 16) {
                    RankCard(
                        title: "Devices Rank",
                        rank: stats.rankByDevices,
                        total: stats.totalCouriers,
                        icon: "medal"
                    )
                    
                    RankCard(
                        title: "Deliveries Rank",
                        rank: stats.rankByDeliveries,
                        total: stats.totalCouriers,
                        icon: "trophy"
                    )
                }
            }
            .padding(.top, 8)
            
            // Total Couriers
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundColor(.purple)
                Text("Part of \(stats.totalCouriers) active couriers worldwide")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.purple.opacity(0.1))
            .cornerRadius(10)
        }
    }
    
    private func errorCard(_ message: String) -> some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)
            
            Text("Couldn't load stats")
                .font(.headline)
            
            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Try Again") {
                loadStats()
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func loadStats() {
        guard let email = authManager.userEmail else { return }
        
        isLoading = true
        errorMessage = nil
        
        Task {
            do {
                let fetchedStats = try await apiService.fetchCourierStats(email: email)
                await MainActor.run {
                    self.stats = fetchedStats
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RankCard: View {
    let title: String
    let rank: Int
    let total: Int
    let icon: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.yellow)
            
            if rank > 0 {
                Text("#\(rank)")
                    .font(.title2)
                    .fontWeight(.bold)
                Text("of \(total)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                Text("--")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

#Preview {
    ProfileView()
        .environmentObject(AuthManager.shared)
}
