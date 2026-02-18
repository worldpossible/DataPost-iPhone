import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        Group {
            if authManager.isSignedIn {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            StatusView()
                .tabItem {
                    Image(systemName: "arrow.triangle.2.circlepath")
                    Text("Status")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
            
            SettingsView()
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
        }
        .accentColor(.blue)
    }
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var email = ""
    @State private var name = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Spacer()
                
                // Logo/App Name
                VStack(spacing: 10) {
                    Image(systemName: "envelope.circle.fill")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .foregroundColor(.blue)
                    
                    Text("RACHEL Cloud")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Sync content with RACHEL devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Login Form
                VStack(spacing: 16) {
                    TextField("Name", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.name)
                        .autocorrectionDisabled()
                    
                    TextField("Email", text: $email)
                        .textFieldStyle(.roundedBorder)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    
                    Button(action: signIn) {
                        HStack {
                            Image(systemName: "arrow.right.circle.fill")
                                .font(.title2)
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isFormValid ? Color.blue : Color.gray)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(!isFormValid)
                    
                    if let error = errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
                
                Text("A World Possible Project")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.bottom)
            }
            .navigationBarHidden(true)
            .overlay {
                if isLoading {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.trimmingCharacters(in: .whitespaces).isEmpty &&
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        email.contains("@")
    }
    
    private func signIn() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        authManager.signIn(email: trimmedEmail, name: trimmedName)
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthManager.shared)
}
