//
//  UserSettingsView.swift
//  WineSystem
//
//  Created by 河野 優輝 on 2024/12/01.
//

import SwiftUI

struct UserSettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("userId") private var userId: Int = 0
    @Binding var isShowingSheet: Bool
    @State private var username: String = ""
    @State private var alertManager = AlertManager()
    
    private func getUsername() async {
        do {
            username = try await NetworkService.getUsername(userId: userId)
        } catch let error as NSError {
            alertManager.show(
                title: "\(error.code)",
                message: error.localizedDescription
            )
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                VStack() {
                    Image(systemName: "person")
                        .resizable()
                        .frame(width: 44, height: 44)
                    Text(username)
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                Section() {
                    NavigationLink {
                        UsernameSettingView(
                            userId: userId,
                            username: username,
                            onUpdateUsername: {
                                Task { await getUsername() }
                            }
                        )
                    } label: {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(username)
                                .foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink {
                        PasswordSettingView(userId: userId)
                    } label: {
                        Text("Change Password")
                    }
                }
                Section() {}
                Button("Logout") {
                    UserDefaults.standard.removeObject(forKey: "systemId")
                    UserDefaults.standard.removeObject(forKey: "userId")
                    UserDefaults.standard.removeObject(forKey: "systemName")
                    UserDefaults.standard.removeObject(forKey: "username")
                    isShowingSheet = false
                    isLoggedIn = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("User Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingSheet = false
                    }) {
                        Text("Done")
                    }
                }
            }
        }
        .task {
            await getUsername()
        }
    }
}

struct UsernameSettingView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: Int
    @State var usernameUpdateRequest: UsernameUpdateRequest
    let onUpdateUsername: () -> Void
    @State private var alertManager = AlertManager()
    
    init(userId: Int, username: String, onUpdateUsername: @escaping () -> Void) {
        self.userId = userId
        _usernameUpdateRequest = State(initialValue: .init(from: username))
        self.onUpdateUsername = onUpdateUsername
    }
    
    private func updateUsername() async {
        do {
            try await NetworkService.updateUsername(userId: userId, usernameUpdateRequest: usernameUpdateRequest)
            UserDefaults.standard.set(usernameUpdateRequest.name, forKey: "username")
            onUpdateUsername()
            dismiss()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    
    var body: some View {
        Form {
            TextField("Username", text: $usernameUpdateRequest.name)
                .onSubmit {
                    Task {await updateUsername() }
                }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Change") {
                    Task {await updateUsername() }
                }
            }
        }
        .alert(manager: alertManager)
    }
}

struct PasswordSettingView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: Int
    @State private var passwordUpdateRequest = PasswordUpdateRequest()
    @State private var verifyNewPassword = ""
    @State private var isShowingPasswordAlert: Bool = false
    @State private var isShowingNewPasswordAlert: Bool = false
    @State private var isShowingVerifyNewPasswordAlert: Bool = false
    @State private var alertManager = AlertManager()
    @FocusState private var focusedFieldNumber: Int?
    
    private func validateNewPassword() -> Bool {
        var isValid: Bool = true
        if passwordUpdateRequest.newPassword.count < 4 {
            isShowingNewPasswordAlert = true
            isValid = false
        }
        if passwordUpdateRequest.newPassword != verifyNewPassword {
            isShowingVerifyNewPasswordAlert = true
            isValid = false
        }
        return isValid
    }
    private func updatePassword() async {
        if !validateNewPassword() { return }
        do {
            try await NetworkService.updatePassword(userId: userId, passwordUpdateRequest: passwordUpdateRequest)
            dismiss()
        } catch let error as NSError {
            if error.code == 400 {
                isShowingPasswordAlert = true
            } else {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        Form {
            SecureFieldWithAlert(
                placeholder: "Password",
                text: $passwordUpdateRequest.oldPassword,
                isShowingAlert: $isShowingPasswordAlert,
                alertText: "The password you entered is incorrect."
            )
            .focused($focusedFieldNumber, equals: 0)
            .onSubmit {
                focusedFieldNumber = 1
            }
            
            Section("New password") {
                SecureFieldWithAlert(
                    placeholder: "New password",
                    text: $passwordUpdateRequest.newPassword,
                    isShowingAlert: $isShowingNewPasswordAlert,
                    alertText: "4 or more characters."
                )
                .focused($focusedFieldNumber, equals: 1)
                .onSubmit {
                    focusedFieldNumber = 2
                }
                SecureFieldWithAlert(
                    placeholder: "Retype Password",
                    text: $verifyNewPassword,
                    isShowingAlert: $isShowingVerifyNewPasswordAlert,
                    alertText: "The passwords you entered do not match."
                )
                .focused($focusedFieldNumber, equals: 2)
                .onSubmit {
                    Task { await updatePassword() }
                }
            }
            
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Change") {
                    Task { await updatePassword() }
                }
            }
        }
        .alert(manager: alertManager)
        .onAppear {
            focusedFieldNumber = 0
        }
    }
}

#Preview {
    UserSettingsView(isShowingSheet: .constant(true)).ja()
}
