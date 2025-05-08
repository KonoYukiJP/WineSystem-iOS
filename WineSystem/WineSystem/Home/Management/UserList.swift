//
//  UserList.swift
//  WineSystem
//
//  Created by 河野 優輝 on 2024/11/25.
//

import SwiftUI

struct UserList: View {
    @AppStorage("systemId") private var systemId: Int = 0
    @AppStorage("userId") private var userId: Int = 0
    @State private var users: [User] = []
    @State private var roles: [Role] = []
    @State private var alertManager = AlertManager()
    @State private var isShowingSheet = false
    
    private func getRoles() async {
        do {
            roles = try await NetworkService.getRoles(systemId: systemId)
        } catch let error as NSError {
            alertManager.show(
                title: "\(error.code)",
                message: error.localizedDescription
            )
        }
    }
    private func getUsers() async {
        do {
            users = try await NetworkService.getUsers(systemId: systemId)
        } catch let error as NSError {
            alertManager.show(
                title: "\(error.code)",
                message: error.localizedDescription
            )
        }
    }

    var body: some View {
        List {
            Button(
                action: { isShowingSheet = true },
                label: { Text("Create User") }
            )
            .padding(.vertical, 8)
            
            ForEach(roles) { role in
                Section(header: Text(role.name)) {
                    ForEach(users.filter { $0.roleId == role.id }) { user in
                        NavigationLink(
                            destination: UserEditView(
                                user: user,
                                roles: roles,
                                onUpdateUser: {
                                    Task { await getUsers() }
                                }
                            ),
                            label: {
                                HStack {
                                    Text(user.name)
                                    if !user.isEnabled {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding(.vertical, 8)
                            }
                        )
                    }
                }
            }
        }
        .alert(manager: alertManager)
        .task {
            await getRoles()
            await getUsers()
        }
        .sheet(isPresented: $isShowingSheet, content: {
            UserCreateView(
                isShowingSheet: $isShowingSheet,
                systemId: systemId,
                roles: roles,
                onCreateUser: {
                    Task { await getUsers() }
                }
            )
        })
    }
}

struct UserCreateView: View {
    @Binding var isShowingSheet: Bool
    let systemId: Int
    let roles: [Role]
    let onCreateUser: () -> Void
    @State private var username = ""
    @State private var password = ""
    @State private var confirmation = ""
    @State private var isAlertingEmptyUsername = false
    @State private var isAlertingShortPassword = false
    @State private var isAlertingWrongPassword = false
    private var isValidUserInfo: Bool {
        var isValidUserInfo: Bool = true
        if username.isEmpty {
            isAlertingEmptyUsername = true
            isValidUserInfo = false
        }
        if password.count < 4 {
            isAlertingShortPassword = true
            isValidUserInfo = false
        }
        if password != confirmation {
            isAlertingWrongPassword = true
            isValidUserInfo = false
        }
        return isValidUserInfo
    }
    @State private var roleId = 0
    @State private var isEnabled = true
    @State private var alertManager = AlertManager()
    
    private func createUser() async {
        let userCreateRequest = UserCreateRequest(
            name: username,
            password: password,
            roleId: roleId,
            isEnabled: isEnabled
        )
        do {
            try await NetworkService.createUser(systemId: systemId, userCreateRequest: userCreateRequest)
            onCreateUser()
            isShowingSheet = false
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                TextFieldWithAlert(
                    title: "Username",
                    placeholder: "Required",
                    text: $username,
                    showAlert: $isAlertingEmptyUsername,
                    alertMessage: "This field is required."
                )
                Section {
                    SecureFieldWithAlert(
                        title: "Password",
                        placeholder: "Required",
                        text: $password,
                        showAlert: $isAlertingShortPassword,
                        alertMessage: "4 or more characters."
                    )
                    SecureFieldWithAlert(
                        title: "Confirm",
                        placeholder: "Confirm password",
                        text: $confirmation,
                        showAlert: $isAlertingWrongPassword,
                        alertMessage: "The passwords you entered do not match."
                    )
                }
                Picker(selection: $roleId) {
                    ForEach(roles) { role in
                        Text(role.name).tag(role.id)
                    }
                } label: {
                    Text("Role")
                }
                .onAppear {
                    roleId = roles.first!.id
                }
                Toggle(
                    "Status",
                    isOn: $isEnabled
                )
            }
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
                        if isValidUserInfo {
                            Task { await createUser() }
                        }
                    }) {
                        Text("Create")
                    }
                }
            }
            .alert(manager: alertManager)
        }
    }
}

struct UserEditView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: Int
    @State var userUpdateRequest: UserUpdateRequest
    let roles: [Role]
    let onUpdateUser: () -> Void
    @State private var alertManager = AlertManager()
    
    init(user: User, roles: [Role], onUpdateUser: @escaping () -> Void) {
        self.userId = user.id
        _userUpdateRequest = State(initialValue: .init(from: user))
        self.roles = roles
        self.onUpdateUser = onUpdateUser
    }
    
    private func updateUser() async {
        if userUpdateRequest.name.isEmpty {
            alertManager.show(title: "name", message: "is empty")
            return
        }
        do {
            try await NetworkService.updateUser(userId: userId, userUpdateRequest: userUpdateRequest)
            onUpdateUser()
            dismiss()
        } catch let error as NSError {
            alertManager.show(
                title: "\(error.code)",
                message: error.localizedDescription
            )
        }
    }
    private func deleteUser() {
        Task {
            do {
                try await NetworkService.deleteUser(userId: userId)
                onUpdateUser()
                dismiss()
            } catch let error as NSError {
                alertManager.show(
                    title: "\(error.code)",
                    message: error.localizedDescription
                )
            }
        }
    }
    
    var body: some View {
        Form {
            HStack() {
                Text("Name")
                TextField(
                    "Username",
                    text: $userUpdateRequest.name
                )
                .multilineTextAlignment(.trailing)
            }
            Picker(selection: $userUpdateRequest.roleId) {
                ForEach(roles) { role in
                    Text(role.name).tag(role.id)
                }
            } label: {
                Text("Role")
            }
            Toggle(
                "Status",
                isOn: $userUpdateRequest.isEnabled
            )
            
            Section {
                Button("Delete") {
                    deleteUser()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("User Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task { await updateUser() }
                }
            }
        }
        .alert(manager: alertManager)
    }
}

#Preview {
    NavigationStack {
        UserList()
    }.ja()
}
