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
            roles = try await NetworkService.getRoles(systemId: systemId)
            resources = try await NetworkService.getResources()
            actions = try await NetworkService.getActions()
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
            Button("Create Role") {
                isShowingSheet = true
            }
            
            Section {
                ForEach(roles) { role in
                    NavigationLink(
                        destination:
                            RoleEditView(
                                role: role,
                                resources: resources,
                                actions: actions,
                                onUpdateRole: {
                                    Task { await getRoles() }
                                }),
                        label: {
                            VStack(alignment: .leading) {
                                Text(role.name)
                                VStack(alignment: .leading) {
                                    ForEach(role.permissions.indices, id: \.self) { index in
                                        let permission = role.permissions[index]
                                        let resourceName: LocalizedStringKey = resources.first(where: { $0.id == permission.resourceId })?.localizedResourceName ?? "?"
                                        let actionName: LocalizedStringKey = actions.first(where: { $0.id == permission.actionId })?.localizedActionName ?? "?"
                                        HStack(spacing: 0) {
                                            Text(resourceName)
                                            Text(": ")
                                            Text(actionName)
                                        }
                                        .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    )
                }
                .onDelete(perform: deleteRole)
            }
        }
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
                    title: "Role Name",
                    placeholder: "Required",
                    text: $name,
                    showAlert: $isAlertingRoleName,
                    alertMessage: "This field is required."
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
                    Button("Create") {
                        Task { await createRole() }
                    }
                }
            }
            .alert(manager: alertManager)
        }
    }
}

struct RoleEditView: View {
    @Environment(\.dismiss) private var dismiss
    let role: Role
    @State var roleUpdateRequest: RoleUpdateRequest
    let onUpdateRole: () -> Void
    @State private var isAlertingName = false
    var actions: [Action]
    var resources: [Resource]
    @State private var resourcePermissions: [ResourcePermission]
    @State private var alertManager = AlertManager()
    @State private var isExpanded = true
    
    init(role: Role, resources: [Resource], actions: [Action], onUpdateRole: @escaping () -> Void) {
        self.role = role
        _roleUpdateRequest = State(initialValue: .init(from: role))
        self.resources = resources
        self.actions = actions
        var resourcePermissions: [ResourcePermission] = []
        for resource in resources {
            var resourceActions: [ActionPermission] = []
            for action in actions {
                let isPermitted = role.permissions.contains {
                    $0.resourceId == resource.id && $0.actionId == action.id
                }
                resourceActions.append(ActionPermission(id: action.id, actionName: action.name, isPermitted: isPermitted))
            }
            resourcePermissions.append(ResourcePermission(id: resource.id, resourceName: resource.name, actionPermissions: resourceActions))
        }
        _resourcePermissions = State(initialValue: resourcePermissions)
        self.onUpdateRole = onUpdateRole
    }
    
    private func updateRole() async {
        if roleUpdateRequest.name.isEmpty {
            isAlertingName = true
            return
        }
        let permissions: [Permission] = resourcePermissions.flatMap { resourcePermission in
            resourcePermission.actionPermissions
                .filter { $0.isPermitted }
                .map { Permission(resourceId: resourcePermission.id, actionId: $0.id) }
        }
        let old = Set(role.permissions)
        let new = Set(permissions)
        let insert: [Permission] = Array(new.subtracting(old))
        let delete: [Permission] = Array(old.subtracting(new))
        roleUpdateRequest.permissionsPatch = PermissionsPatch(insert: insert, delete: delete)
        do {
            try await NetworkService.updateRole(roleId: role.id, roleUpdateRequest: roleUpdateRequest)
            onUpdateRole()
            dismiss()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func deleteRole() {
        Task {
            do {
                try await NetworkService.deleteRole(roleId: role.id)
                onUpdateRole()
                dismiss()
            } catch let error as NSError {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        Form {
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
            
            Section() {}
            ForEach(resourcePermissions) { resource in
                let resourceIndex = resourcePermissions.firstIndex(where: { $0.id == resource.id })!
                DisclosureGroup(resource.localizedResourceName, isExpanded: $isExpanded) {
                    ForEach(resource.actionPermissions) { action in
                        let actionIndex = resourcePermissions[resourceIndex].actionPermissions.firstIndex(where: { $0.id == action.id })!
                        Toggle(
                            action.localizedActionName,
                            isOn: $resourcePermissions[resourceIndex].actionPermissions[actionIndex].isPermitted
                        )
                        
                    }
                }
            }
            .listStyle(.sidebar)
            
            Section {
                Button("Delete") {
                    deleteRole()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Role Details")
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

#Preview {
    NavigationStack {
        RoleList()
    }.ja()
}
