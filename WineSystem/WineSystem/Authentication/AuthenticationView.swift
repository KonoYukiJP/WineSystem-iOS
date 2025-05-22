//
//  ContentView.swift
//  WineSystem
//
//  Created by 河野優輝 on 2024/11/16.
//

import SwiftUI

struct AuthenticationView: View {
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false
    @State private var isShowingAdmiSheet = false
    @State private var isShowingUserSheet = false
    @State private var systemId = 0
    @State private var loginRequest = LoginRequest()
    @State private var systems: [System] = []
    @State private var isShowingPasswordAlert = false
    @State private var alertManager = AlertManager()
    @FocusState private var focusedFieldNumber: Int?
    
    private func getSystems() async {
        do {
            systems = try await NetworkService.getSystems()
            if !systems.contains(where: { $0.id == systemId }) {
                systemId = systems.first?.id ?? 0
            }
        } catch {
            alertManager.show(
                title: "Failed to fetch systems",
                message: "\(error.localizedDescription)"
            )
        }
    }
    private func login() async {
        do {
            let token = try await NetworkService.login(systemId: systemId, loginRequest: loginRequest)
            UserDefaults.standard.set(systems.first(where: { $0.id == systemId })!.name, forKey: "systemName")
            UserDefaults.standard.set(loginRequest.username, forKey: "username")
            UserDefaults.standard.set(token, forKey: "token")
            isLoggedIn = true
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: "\(error.localizedDescription)")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                VStack() {
                    Image(systemName: "wineglass")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                Section {}
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
                
                Section {
                    TextField("Username", text: $loginRequest.username)
                        .focused($focusedFieldNumber, equals: 0)
                        .onSubmit {
                            focusedFieldNumber = 1
                        }
                    SecureField("Password", text: $loginRequest.password)
                        .focused($focusedFieldNumber, equals: 1)
                        .onSubmit {
                            Task { await login( )}
                        }
                }
            }
            .navigationTitle("Wine System")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("New System") {
                        isShowingAdmiSheet = true
                    }
                    .sheet(
                        isPresented: $isShowingAdmiSheet,
                        content: {
                            SystemCreateView(
                                isShowingSheet: $isShowingAdmiSheet,
                                onCreateSystem: {
                                    Task { await getSystems() }
                                }
                            )
                        }
                    )
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Login") {
                        Task { await login() }
                    }
                }
            }
            .alert(manager: alertManager)
            .onAppear {
                focusedFieldNumber = 0
            }
        }
    }
}

#Preview {
    AuthenticationView().ja()
}
