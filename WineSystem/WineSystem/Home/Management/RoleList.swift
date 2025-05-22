//
//  RoleList.swift
//  WineSystem
//
//  Created by 河野優輝 on 2024/12/20.
//

import SwiftUI

struct RoleList: View {
    @State private var roles: [Role] = []
    @State private var resources: [Resource] = []
    @State private var actions: [Action] = []
    @State private var alertManager = AlertManager()
    @State private var isShowingSheet = false
    
    private func getRoles() async {
        do {
            resources = try await NetworkService.getResources()
            actions = try await NetworkService.getActions()
            roles = try await NetworkService.getRoles()
        } catch let error as NSError {
            alertManager.show(
                title: "\(error.code)",
                message: error.localizedDescription
            )
        }
    }
    private func deleteRole(at offsets: IndexSet) {
        Task {
            do {
                try await NetworkService.deleteRole(roleId: roles[offsets.first!].id)
                roles.remove(atOffsets: offsets)
            } catch let error as NSError {
                alertManager.show(
                    title: "\(error.code)",
                    message: error.localizedDescription
                )
            }
        }
    }

    var body: some View {
        List {
            ForEach(roles) { role in
                NavigationLink(
                    destination:
                        RoleEditView(
                            role: role,
                            resources: resources,
                            actions: actions
                        ),
                    label: {
                        RoleListCell(
                            role: role,
                            resources: resources,
                            actions: actions
                        )
                    }
                )
            }
            .onDelete(perform: deleteRole)
        }
        .navigationTitle("Roles")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Create Role", systemImage: "plus") {
                    isShowingSheet = true
                }
            }
        }
        .alert(manager: alertManager)
        .task {
            await getRoles()
        }
        .sheet(isPresented: $isShowingSheet) {
            RoleCreateView(
                isShowingSheet: $isShowingSheet,
                onCreateRole: {
                    Task { await getRoles() }
                },
                resources: resources,
                actions: actions
            )
        }
    }
}

struct RoleListCell: View {
    let role: Role
    let resources: [Resource]
    let actions: [Action]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(role.name)
            Text("Permissions")
            Grid {
                ForEach(role.permissions) { permission in
                    GridRow {
                        Text(resources.first(where: { $0.id == permission.resourceId})!.localizedName)
                        ForEach(actions) { action in
                            let isPermitted = permission.actionIds.contains(action.id)
                            Text(isPermitted ? action.localizedName : "")
                        }
                    }
                }
            }
            .foregroundStyle(.secondary)
        }
    }
}

struct RoleEditView: View {
    @Environment(\.dismiss) private var dismiss
    let role: Role
    @State var name: String
    @State private var isAlertingName = false
    let actions: [Action]
    let resources: [Resource]
    @State private var permissions: Permissions
    @State private var alertManager = AlertManager()
    
    init(role: Role, resources: [Resource], actions: [Action]) {
        self.role = role
        _name = State(initialValue: role.name)
        self.resources = resources
        self.actions = actions
        _permissions = State(initialValue: role.toResourcePermissions(resources: resources, actions: actions))
    }
    
    private func updateRole() async {
        if name.isEmpty {
            isAlertingName = true
            return
        }
        let permissions: [Permission] = permissions.toPermissions()
        let roleUpdateRequest = RoleUpdateRequest(
            name: name,
            resources: resources,
            oldPermissions: role.permissions,
            newPermissions: permissions
        )
        do {
            try await NetworkService.updateRole(roleId: role.id, roleUpdateRequest: roleUpdateRequest)
            dismiss()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func deleteRole() {
        Task {
            do {
                try await NetworkService.deleteRole(roleId: role.id)
                dismiss()
            } catch let error as NSError {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        Form {
            Section("Name") {
                VStack(alignment: .leading) {
                    TextField(
                        "Role Name",
                        text: $name
                    )
                    .onChange(of: name) {
                        isAlertingName = false
                    }
                    if isAlertingName {
                        AlertText("Thie field is required.")
                    }
                }
            }
            
            Section("Permissions") {
                ForEach($permissions.resources) { resource in
                    DisclosureGroup(resources.first(where: { $0.id == resource.id })!.localizedName, isExpanded: resource.isExpanded) {
                        ForEach(resource.actions) { action in
                            Toggle(
                                actions.first(where: { $0.id == action.id })!.localizedName,
                                isOn: action.isPermitted
                            )
                            
                        }
                    }
                }
                .listStyle(.sidebar)
            }
            
            Section {
                Button("Delete") {
                    deleteRole()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Edit")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task { await updateRole() }
                }
            }
        }
        .alert(manager: alertManager)
    }
}

struct RoleCreateView: View {
    @Binding var isShowingSheet: Bool
    let onCreateRole: () -> Void
    @State private var name = ""
    @State private var isAlertingRoleName = false
    let resources: [Resource]
    let actions: [Action]
    @State private var permissions: Permissions
    @State private var alertManager = AlertManager()
    @FocusState private var isFocused: Bool
    
    init(isShowingSheet: Binding<Bool>, onCreateRole: @escaping () -> Void, resources: [Resource], actions: [Action]) {
        _isShowingSheet = isShowingSheet
        self.onCreateRole = onCreateRole
        self.resources = resources
        self.actions = actions
        _permissions = State(initialValue: .init(resources: resources, actions: actions))
    }
    
    private func createRole() async {
        if name.isEmpty {
            isAlertingRoleName = true
            return
        }
        let roleCreateRequest = RoleCreateRequest(name: name, permissions: permissions.toPermissions())
        do {
            try await NetworkService.createRole(roleCreateRequest: roleCreateRequest)
            onCreateRole()
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
                    text: $name,
                    isShowingAlert: $isAlertingRoleName,
                    alertText: "This field is required."
                )
                .focused($isFocused)
                
                Section("Permissions") {
                    ForEach($permissions.resources) { resource in
                        DisclosureGroup(resources.first(where: { $0.id == resource.id })!.localizedName, isExpanded: resource.isExpanded) {
                            ForEach(resource.actions) { action in
                                Toggle(
                                    actions.first(where: { $0.id == action.id })!.localizedName,
                                    isOn: action.isPermitted
                                )
                                
                            }
                        }
                    }
                    .listStyle(.sidebar)
                }
            }
            .navigationTitle("New Role")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: {
                        isShowingSheet = false
                    }) {
                        Text("Cancel")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task { await createRole() }
                    }
                }
            }
            .alert(manager: alertManager)
            .onAppear { isFocused = true }
        }
    }
}

#Preview {
    NavigationStack {
        RoleList()
    }.ja()
}
