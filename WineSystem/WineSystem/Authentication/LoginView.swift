//
//  LoginView.swift
//  WineSystem
//
//  Created by 河野優輝 on 2024/11/18.
//

import SwiftUI

struct LoginView: View {
    @Binding var isShowingSheet: Bool
    @Binding var isLoggedIn: Bool
    @State private var systemId = 0
    @State private var loginRequest = LoginRequest()
    @State private var systems: [System] = []
    @State private var users: [User] = []
    @State private var isShowingPasswordAlert = false
    
    @State private var alertManager = AlertManager()
    
    private func getSystems() async {
        do {
            systems = try await NetworkService.getSystems()
            if !systems.contains(where: { $0.id == systemId }) {
                systemId = systems.first?.id ?? 0
            } else {
                await getUsers()
            }
        } catch {
            alertManager.show(
                title: "Failed to fetch systems",
                message: "\(error.localizedDescription)"
            )
        }
    }
    private func getUsers() async {
        do {
            users = try await NetworkService.getUsers(systemId: systemId)
            if !users.contains(where: { $0.id == loginRequest.userId }) {
                loginRequest.userId = self.users.first?.id ?? 0
            }
        } catch {
            alertManager.show(
                title: "Failed to fetch users",
                message: "\(error.localizedDescription)"
            )
        }
    }
    private func login() async {
        do {
            let token = try await NetworkService.login(systemId: systemId, loginRequest: loginRequest)
            UserDefaults.standard.set(systemId, forKey: "systemId")
            UserDefaults.standard.set(loginRequest.userId, forKey: "userId")
            UserDefaults.standard.set(systems.first(where: { $0.id == systemId })!.name, forKey: "systemName")
            UserDefaults.standard.set(users.first(where: { $0.id == loginRequest.userId})!.name, forKey: "username")
            UserDefaults.standard.set(token, forKey: "token")
            print(token)
            isShowingSheet = false
            isLoggedIn = true
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: "\(error.localizedDescription)")
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Picker(selection: $systemId) {
                    ForEach(systems) { system in
                        Text(system.name).tag(system.id)
                    }
                } label: {
                    Text("System")
                    Text("Choose a system you wanna use")
                }
                .task {
                    await getSystems()
                }
                .onChange(of: systemId) {
                    Task { await getUsers() }
                }
                
                Section {
                    Picker(selection: $loginRequest.userId) {
                        ForEach(users) { user in
                            Text(user.name).tag(user.id)
                        }
                    } label: {
                        Text("Username")
                    }
                    SecureField("Password", text: $loginRequest.password)
                    .onSubmit {
                        Task { await login( )}
                    }
                }
            }
            .navigationTitle("Wine System")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isShowingSheet = false
                    }) {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        Task { await login() }
                    }) {
                        Text("Login")
                    }
                }
            }
            .alert(manager: alertManager)
        }
    }
}

#Preview {
    LoginView(isShowingSheet: .constant(true), isLoggedIn: .constant(false)).ja()
}
