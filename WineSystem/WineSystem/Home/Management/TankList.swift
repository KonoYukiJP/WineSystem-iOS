//
//  SwiftUIView.swift
//  WineSystem
//
//  Created by 河野 優輝 on 2024/12/15.
//

import SwiftUI

struct TankList: View {
    @AppStorage("systemId") private var systemId: Int = 0
    @State private var tanks: [Tank] = []
    @State private var materials: [Material] = []
    @State private var alertManager = AlertManager()
    @State private var isShowingSheet = false
    
    private func getTanks() async {
        do {
            tanks = try await NetworkService.getTanks(systemId: systemId)
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func getMaterials() async {
        do {
            materials = try await NetworkService.getMaterials(systemId: systemId)
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
            Button("Create Tank") {
                isShowingSheet = true
            }
            Section {}
            ForEach(tanks) { tank in
                NavigationLink(
                    destination:
                        EditTankView(
                            tank: tank,
                            materials: materials,
                            onUpdateTank: {
                                Task { await getTanks() }
                            }),
                    label: {
                        Text(tank.name)
                    }
                )
            }
            .onDelete(perform: deleteTank)
        }
        .alert(manager: alertManager)
        .task {
            await getTanks()
            await getMaterials()
        }
        .sheet(isPresented: $isShowingSheet) {
            TankCreateView(
                isShowingSheet: $isShowingSheet,
                systemId: systemId,
                materials: materials,
                onCreateTank: {
                    Task {
                        await getTanks()
                        await getMaterials()
                    }
                }
            )
        }
        
    }
}

private struct TankCreateView: View {
    @Binding var isShowingSheet: Bool
    let systemId: Int
    let materials: [Material]
    let onCreateTank: () -> Void
    @State private var name = ""
    @State private var note = ""
    @State private var materialId: Int? = nil
    
    @State private var isAlertingName = false
    @State private var alertManager = AlertManager()
    
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
            try await NetworkService.createTank(systemId: systemId, newTankRequest: newTankRequest)
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
                    title: "Tank Name",
                    placeholder: "Required",
                    text: $name,
                    showAlert: $isAlertingName,
                    alertMessage: "This field is required."
                )
                TextFieldWithAlert(
                    title: "Note",
                    placeholder: "Required",
                    text: $note,
                    showAlert: .constant(false),
                    alertMessage: "4 or more characters."
                )
                Picker(selection: $materialId) {
                    Text("None").tag(nil as Int?)
                    ForEach(materials) { material in
                        Text(material.name).tag(material.id)
                    }
                } label: {
                    Text("Material")
                }
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
                        Task { await createTank() }
                    }
                }
            }
            .alert(manager: alertManager)
        }
    }
}

struct EditTankView: View {
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
            
            Section(header: Text("Note")) {
                TextEditor(text: $newTankRequest.note)
                    .frame(minHeight: 64)
            }
            Picker(selection: $newTankRequest.materialId) {
                Text("None").tag(nil as Int?)
                ForEach(materials) { material in
                    Text(material.name).tag(material.id)
                }
            } label: {
                Text("Material")
            }
            
            Section {
                Button("Delete") {
                    deleteTank()
                }
                .foregroundStyle(.red)
            }
        }
        .navigationTitle("Tank Details")
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

#Preview {
    NavigationStack {
        TankList()
    }.ja()
}
