//
//  MaterialList.swift
//  WineSystem
//
//  Created by 河野 優輝 on 2024/12/08.
//

import SwiftUI

struct MaterialList: View {
    @AppStorage("systemId") private var systemId: Int = 0
    @State private var materials: [Material] = []
    @State private var alertManager = AlertManager()
    @State private var isShowingSheet = false
    
    private func getMaterials() async {
        do {
            materials = try await NetworkService.getMaterials(systemId: systemId)
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func deleteMaterial(at offsets: IndexSet) {
        Task {
            do {
                try await NetworkService.deleteMaterial(materialId: materials[offsets.first!].id)
                materials.remove(atOffsets: offsets)
            } catch let error as NSError {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }

    var body: some View {
        List {
            Button("Create Material") {
                isShowingSheet = true
            }
            Section {
                ForEach(materials) { material in
                    NavigationLink(
                        destination:
                            MaterialEditView(
                                material: material,
                                onUpdateMaterial: {
                                    Task { await getMaterials() }
                                }),
                        label: {
                            VStack(alignment: .leading) {
                                Text(material.name)
                                if !material.note.isEmpty {
                                    Text(material.note)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    )
                }
                .onDelete(perform: deleteMaterial)
            }
        }
        .alert(manager: alertManager)
        .task {
            await getMaterials()
        }
        .sheet(isPresented: $isShowingSheet) {
            MaterialCreateView(
                isShowingSheet: $isShowingSheet,
                systemId: systemId,
                onCreateMaterial: {
                    Task { await getMaterials() }
                }
            )
        }
    }
}

struct MaterialCreateView: View {
    @Binding var isShowingSheet: Bool
    let systemId: Int
    let onCreateMaterial: () -> Void
    @State private var name = ""
    @State private var note = ""
    @State private var isAlertingMaterialName = false
    @State private var alertManager = AlertManager()
    
    struct NewMaterial: Codable {
        let name: String
        let note: String
    }
    private func createMaterial() async {
        if name.isEmpty {
            isAlertingMaterialName = true
            return
        }
        do {
            try await NetworkService.createMaterial(
                systemId: systemId,
                newMaterialRequest: .init(
                    name: name,
                    note: note
                )
            )
            onCreateMaterial()
            isShowingSheet = false
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Material") {
                    TextFieldWithAlert(
                        placeholder: "Name",
                        text: $name,
                        isShowingAlert: $isAlertingMaterialName,
                        alertText: "This field is required."
                    )
                }
                Section(header: Text("Note")) {
                    TextEditor(text: $note)
                        .frame(minHeight: 64)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isShowingSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task { await createMaterial() }
                    }
                }
            }
            .alert(manager: alertManager)
        }
    }
}

struct MaterialEditView: View {
    @Environment(\.dismiss) private var dismiss
    let materialId: Int
    @State private var newMaterialRequest: NewMaterialRequest
    let onUpdateMaterial: () -> Void
    @State private var isAlertingName = false
    @State private var alertManager = AlertManager()
    
    init(material: Material, onUpdateMaterial: @escaping () -> Void) {
        materialId = material.id
        _newMaterialRequest = State(initialValue: .init(from: material))
        self.onUpdateMaterial = onUpdateMaterial
    }
    
    private func updateMaterial() async {
        if newMaterialRequest.name.isEmpty {
            isAlertingName = true
            return
        }
        do {
            try await NetworkService.updateMaterial(materialId: materialId, newMaterialRequest: newMaterialRequest)
            onUpdateMaterial()
            dismiss()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func deleteMaterial() {
        Task {
            do {
                try await NetworkService.deleteMaterial(materialId: materialId)
                onUpdateMaterial()
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
                    "Material Name",
                    text: $newMaterialRequest.name
                )
                .onChange(of: newMaterialRequest.name) {
                    isAlertingName = false
                }
                if isAlertingName {
                    AlertText("Thie field is required.")
                }
            }
            
            Section(header: Text("Note")) {
                TextEditor(text: $newMaterialRequest.note)
                    .frame(minHeight: 64)
            }
            
            Button("Delete") {
                deleteMaterial()
            }
            .foregroundStyle(.red)
        }
        .navigationTitle("Material Details")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task { await updateMaterial() }
                }
            }
        }
        .alert(manager: alertManager)
    }
}

#Preview {
    NavigationStack {
        MaterialList()
    }.ja()
}
