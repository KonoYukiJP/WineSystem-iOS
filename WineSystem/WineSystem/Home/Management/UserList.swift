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
    
    private func getUsers() async {
        do {
            users = try await NetworkService.getUsers(systemId: systemId)
            roles = try await NetworkService.getRoles(systemId: systemId)
        } catch let error as NSError {
            alertManager.show(
                title: "\(error.code)",
                message: error.localizedDescription
            )
        }
    }

    var body: some View {
        List {
            ForEach(roles) { role in
                Section(header: Text(role.name)) {
                    ForEach(users.filter { $0.roleId == role.id }) { user in
                        NavigationLink(
                            destination: UserEditView(
                                user: user,
                                roles: roles
                            ),
                            label: {
                                HStack {
                                    Text(user.name)
                                    if !user.isEnabled {
                                        Image(systemName: "exclamationmark.square")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle("Users")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Create User", systemImage: "plus") {
                    isShowingSheet = true
                }
            }
        }
        .alert(manager: alertManager)
        .task { await getUsers() }
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

struct UserEditView: View {
    @Environment(\.dismiss) private var dismiss
    let userId: Int
    @State var userUpdateRequest: UserUpdateRequest
    let roles: [Role]
    @State private var alertManager = AlertManager()
    
    init(user: User, roles: [Role]) {
        self.userId = user.id
        _userUpdateRequest = State(initialValue: .init(from: user))
        self.roles = roles
    }
    
    private func updateUser() async {
        if userUpdateRequest.name.isEmpty {
            alertManager.show(title: "name", message: "is empty")
            return
        }
        do {
            try await NetworkService.updateUser(userId: userId, userUpdateRequest: userUpdateRequest)
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
        .navigationTitle("Details")
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

struct UserCreateView: View {
    @Binding var isShowingSheet: Bool
    let systemId: Int
    let roles: [Role]
    let onCreateUser: () -> Void
    @State private var userCreateRequest = UserCreateRequest()
    @State private var confirmation = ""
    @State private var isAlertingEmptyUsername = false
    @State private var isAlertingShortPassword = false
    @State private var isAlertingWrongPassword = false
    @State private var alertManager = AlertManager()
    @FocusState private var focusedFieldNumber: Int?
    
    private func validateRequest() -> Bool {
        var isValidRequest: Bool = true
        if userCreateRequest.name.isEmpty {
            isAlertingEmptyUsername = true
            isValidRequest = false
        }
        if userCreateRequest.password.count < 4 {
            isAlertingShortPassword = true
            isValidRequest = false
        }
        if userCreateRequest.password != confirmation {
            isAlertingWrongPassword = true
            isValidRequest = false
        }
        return isValidRequest
    }
    
    private func createUser() async {
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
                    placeholder: "Name",
                    text: $userCreateRequest.name,
                    isShowingAlert: $isAlertingEmptyUsername,
                    alertText: "This field is required."
                )
                .focused($focusedFieldNumber, equals: 0)
                .onSubmit { focusedFieldNumber = 1 }
                Section("Password") {
                    SecureFieldWithAlert(
                        placeholder: "Password",
                        text: $userCreateRequest.password,
                        isShowingAlert: $isAlertingShortPassword,
                        alertText: "4 or more characters."
                    )
                    .focused($focusedFieldNumber, equals: 1)
                    .onSubmit { focusedFieldNumber = 2 }
                    SecureFieldWithAlert(
                        placeholder: "Confirm password",
                        text: $confirmation,
                        isShowingAlert: $isAlertingWrongPassword,
                        alertText: "The passwords you entered do not match."
                    )
                    .focused($focusedFieldNumber, equals: 2)
                }
                Picker(selection: $userCreateRequest.roleId) {
                    ForEach(roles) { role in
                        Text(role.name).tag(role.id)
                    }
                } label: {
                    Text("Role")
                }
                Toggle(
                    "Status",
                    isOn: $userCreateRequest.isEnabled
                )
            }
            .navigationTitle("New User")
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
                        if validateRequest() {
                            Task { await createUser() }
                        }
                    }) {
                        Text("Create")
                    }
                }
            }
            .alert(manager: alertManager)
            .onAppear {
                userCreateRequest.roleId = roles.first!.id
                focusedFieldNumber = 0
            }
        }
    }
}

#Preview {
    NavigationStack {
        UserList()
    }.ja()
}
