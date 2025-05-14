//
//  RoleList.swift
//  WineSystem
//
//  Created by 河野優輝 on 2024/12/20.
//

import SwiftUI

struct RoleList: View {
    @AppStorage("systemId") private var systemId: Int = 0
    @State private var roles: [Role] = []
    @State private var resources: [Resource] = []
    @State private var actions: [Action] = []
    @State private var alertManager = AlertManager()
    @State private var isShowingSheet = false
    
    private func getRoles() async {
        do {
            resources = try await NetworkService.getResources()
            actions = try await NetworkService.getActions()
            roles = try await NetworkService.getRoles(systemId: systemId)
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
                systemId: systemId,
                onCreateRole: {
                    Task { await getRoles() }
                }
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
            HStack {
                VStack {
                    ForEach(role.permissions) { permission in
                        Text(resources.first(where: { $0.id == permission.resourceId})!.localizedName)
                    }
                }
                if !role.permissions.isEmpty {
                    Divider()
                }
                VStack(alignment: .leading) {
                    ForEach(role.permissions) { permission in
                        HStack {
                            ForEach(permission.actionIds, id: \.self) { actionId in
                                Text(actions.first(where: { $0.id == actionId})!.localizedName)
                            }
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
    @State var roleUpdateRequest: RoleUpdateRequest
    @State private var isAlertingName = false
    let actions: [Action]
    let resources: [Resource]
    @State private var resourcePermissions: [ResourcePermission]
    @State private var alertManager = AlertManager()
    
    init(role: Role, resources: [Resource], actions: [Action]) {
        self.role = role
        _roleUpdateRequest = State(initialValue: .init(from: role))
        self.resources = resources
        self.actions = actions
        _resourcePermissions = State(initialValue: role.toResourcePermissions(resources: resources, actions: actions))
    }
    
    private func updateRole() async {
        if roleUpdateRequest.name.isEmpty {
            isAlertingName = true
            return
        }
        let permissions: [Permission] = resourcePermissions.toPermissions()
        roleUpdateRequest.inserts = []
        roleUpdateRequest.deletes = []
        for resource in resources {
            let old = Set(role.permissions.first(where: { $0.resourceId == resource.id })?.actionIds ?? [])
            let new = Set(permissions.first(where: { $0.resourceId == resource.id })?.actionIds ?? [])
            let insertsActionIds = Array(new.subtracting(old))
            if !insertsActionIds.isEmpty {
                roleUpdateRequest.inserts.append(Permission(resourceId: resource.id, actionIds: insertsActionIds))
            }
            let deletesActionIds = Array(old.subtracting(new))
            if !deletesActionIds.isEmpty {
                roleUpdateRequest.deletes.append(Permission(resourceId: resource.id, actionIds: deletesActionIds))
            }
        }
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
                        text: $roleUpdateRequest.name
                    )
                    .onChange(of: roleUpdateRequest.name) {
                        isAlertingName = false
                    }
                    if isAlertingName {
                        AlertText("Thie field is required.")
                    }
                }
            }
            
            Section("Permissions") {
                ForEach($resourcePermissions) { resource in
                    DisclosureGroup(resources.first(where: { $0.id == resource.id })!.localizedName, isExpanded: resource.isExpanded) {
                        ForEach(resource.actionPermissions) { action in
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
    let systemId: Int
    let onCreateRole: () -> Void
    @State private var name = ""
    @State private var isAlertingRoleName = false
    @State private var alertManager = AlertManager()
    @FocusState private var focusedFieldNumber: Int?
    
    private func createRole() async {
        if name.isEmpty {
            isAlertingRoleName = true
            return
        }
        do {
            try await NetworkService.createRole(systemId: systemId, roleCreateRequest: .init(name: name))
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
                .focused($focusedFieldNumber, equals: 0)
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
            .onAppear { focusedFieldNumber = 0 }
        }
    }
}

#Preview {
    NavigationStack {
        RoleList()
    }.ja()
}
