//
//  SwiftUIView.swift
//  WineSystem
//
//  Created by 河野 優輝 on 2024/12/15.
//

import SwiftUI

struct TankList: View {
    @State private var tanks: [Tank] = []
    @State private var materials: [Material] = []
    @State private var alertManager = AlertManager()
    @State private var isShowingSheet = false
    
    private func getTanks() async {
        do {
            tanks = try await NetworkService.getTanks()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func getMaterials() async {
        do {
            materials = try await NetworkService.getMaterials()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func deleteTank(at offsets: IndexSet) {
        Task {
            do {
                try await NetworkService.deleteTank(tankId: tanks[offsets.first!].id)
                tanks.remove(atOffsets: offsets)
            } catch let error as NSError {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }

    var body: some View {
        List {
            ForEach(tanks) { tank in
                NavigationLink(
                    destination:
                        TankEditView(
                            tank: tank,
                            materials: materials,
                            onUpdateTank: {
                                Task { await getTanks() }
                            }),
                    label: {
                        VStack(alignment: .leading) {
                            Text(tank.name)
                            if let materialName = materials.first(where: { $0.id == tank.materialId })?.name {
                                Text(materialName)
                                    .foregroundStyle(.secondary)
                            }
                            if !tank.note.isEmpty {
                                Text(tank.note)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                )
            }
            .onDelete(perform: deleteTank)
        }
        .navigationTitle("Tanks")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Create Tank", systemImage: "plus") {
                    isShowingSheet = true
                }
            }
        }
        .alert(manager: alertManager)
        .task {
            await getTanks()
            await getMaterials()
        }
        .sheet(isPresented: $isShowingSheet) {
            TankCreateView(
                isShowingSheet: $isShowingSheet,
                materials: materials,
                onCreateTank: {
                    Task {
                        await getMaterials()
                        await getTanks()
                    }
                }
            )
        }
        
    }
}

struct TankEditView: View {
    @Environment(\.dismiss) private var dismiss
    let tankId: Int
    @State private var newTankRequest: NewTankRequest
    let materials: [Material]
    let onUpdateTank: () -> Void
    @State private var isAlertingName = false
    @State private var alertManager = AlertManager()
    
    init(tank:Tank, materials: [Material], onUpdateTank: @escaping () -> Void) {
        tankId = tank.id
        _newTankRequest = State(initialValue: .init(from: tank))
        self.materials = materials
        self.onUpdateTank = onUpdateTank
    }
    
    private func updateTank() async {
        if newTankRequest.name.isEmpty {
            isAlertingName = true
            return
        }
        do {
            try await NetworkService.updateTank(tankId: tankId, newTankRequest: newTankRequest)
            onUpdateTank()
            dismiss()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func deleteTank() {
        Task {
            do {
                try await NetworkService.deleteTank(tankId: tankId)
                onUpdateTank()
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
                    text: $newTankRequest.name
                )
                .onChange(of: newTankRequest.name) {
                    isAlertingName = false
                }
                if isAlertingName {
                    AlertText("Thie field is required.")
                }
            }
            Picker(selection: $newTankRequest.materialId) {
                Text("None").tag(nil as Int?)
                ForEach(materials) { material in
                    Text(material.name).tag(material.id)
                }
            } label: {
                Text("Material")
            }
            Section(header: Text("Note")) {
                TextEditor(text: $newTankRequest.note)
                    .frame(minHeight: 64)
            }
            
            Section {
                Button("Delete") {
                    deleteTank()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Edit")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task { await updateTank() }
                }
            }
        }
        .alert(manager: alertManager)
    }
}

private struct TankCreateView: View {
    @Binding var isShowingSheet: Bool
    let materials: [Material]
    let onCreateTank: () -> Void
    @State private var name = ""
    @State private var note = ""
    @State private var materialId: Int? = nil
    @State private var isAlertingName = false
    @State private var alertManager = AlertManager()
    @FocusState private var focusedFieldNumber: Int?
    
    private func createTank() async {
        if name.isEmpty {
            isAlertingName = true
            return
        }
        let newTankRequest = NewTankRequest(
            name: name,
            note: note,
            materialId: materialId
        )
        do {
            try await NetworkService.createTank(newTankRequest: newTankRequest)
            onCreateTank()
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
                    isShowingAlert: $isAlertingName,
                    alertText: "This field is required."
                )
                .focused($focusedFieldNumber, equals: 0)
                Picker(selection: $materialId) {
                    Text("None").tag(nil as Int?)
                    ForEach(materials) { material in
                        Text(material.name).tag(material.id)
                    }
                } label: {
                    Text("Material")
                }
                
                Section(header: Text("Note")) {
                    TextEditor(text: $note)
                        .frame(minHeight: 64)
                }
            }
            .navigationTitle("New Tank")
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
                        Task { await createTank() }
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
        TankList()
    }.ja()
}
