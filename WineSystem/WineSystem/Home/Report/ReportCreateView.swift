//
//  Daily.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/04/21.
//

import SwiftUI

struct ReportCreateView: View {
    @AppStorage("systemId") var systemId: Int = 0
    let work: Work
    @State private var operations: [Operation] = []
    private var filteredOperations: [Operation] { operations.filter { $0.workId == work.id }
    }
    @State private var alertManager = AlertManager()
    
    private func getOperations() async {
        do {
            operations = try await NetworkService.getOperations()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    
    var body: some View {
        Form {
            HStack {
                Text("Work")
                Spacer()
                Text(work.name)
            }
            
            Section(header: Text("Operation")) {
                ForEach(filteredOperations) { operation in
                    NavigationLink(
                        destination:
                            [4, 13, 17].contains(where: { $0 == operation.id })
                        ? AnyView(FeaturesView(work: work, operation: operation))
                        : AnyView(ReportPostView(work: work, operation: operation)),
                        label: {
                            Text(operation.name)
                        }
                    )
                }
            }
        }
        .navigationTitle(work.name)
        .alert(manager: alertManager)
        .task {
            await getOperations()
        }
    }
}

struct ReportPostView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("systemId") var systemId: Int = 0
    @AppStorage("userId") var userId: Int = 0
    @AppStorage("username") var username: String = ""
    @State private var date: Date = Date()
    let work: Work
    let operation: Operation
    @State private var materialId: Int = 0
    @State private var tankId: Int = 0
    @State private var materials: [Material] = []
    @State private var tanks: [Tank] = []
    let feature: Feature?
    @State private var value: Double? = nil
    @State private var note: String = ""
    @State private var report: NewReportRequest?
    @State private var alertManager = AlertManager()
    
    init(work: Work, operation: Operation, feature: Feature? = nil) {
        self.feature = feature
        self.work = work
        self.operation = operation
    }
    
    private func getMaterials() async {
        do {
            materials = try await NetworkService.getMaterials(systemId: systemId)
            materialId = materials.first?.id ?? 0
        } catch let error as NSError {
            alertManager.show(
                title: "\(error.code)",
                message: error.localizedDescription
            )
        }
    }
    private func getTanks() async {
        do {
            tanks = try await NetworkService.getTanks(systemId: systemId)
            tankId = tanks.first?.id ?? 0
        } catch let error as NSError {
            alertManager.show(
                title: "\(error.code)",
                message: error.localizedDescription
            )
        }
    }
    
    private func createReport() async {
        let newReportRequest = NewReportRequest(
            date: date,
            userId: userId,
            workId: work.id,
            operationId: operation.id,
            kindId: work.id == 1 ? materialId : tankId,
            featureId: feature?.id,
            value: value,
            note: note.isEmpty ? nil : note
        )
        do {
            try await NetworkService.createReport(systemId: systemId, newReportRequest: newReportRequest)
            dismiss()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    
    var body: some View {
        Form {
            HStack {
                Text("User")
                Spacer()
                Text(username)
            }
            DatePicker("Date", selection: $date)
            
            Section {}
            HStack {
                Text("Work");Spacer();Text(work.localizedWorkName)
            }
            HStack {
                Text("Operation");Spacer();Text(operation.name)
            }
            if work.id == 1 {
                Picker(selection: $materialId) {
                    ForEach(materials) { material in
                        Text(material.name).tag(material.id)
                    }
                } label: {
                    Text("Material")
                }
                .task {
                    await getMaterials()
                }
            } else {
                Picker(selection: $tankId) {
                    ForEach(tanks) { tank in
                        Text(tank.name).tag(tank.id)
                    }
                } label: {
                    Text("Tank")
                }
                .task {
                    await getTanks()
                }
            }
            
            if let feature = feature {
                HStack {
                    Text(feature.name)
                    TextField("Value", value: $value, format: .number)
                        .multilineTextAlignment(.trailing)
                    Text(feature.unit)
                }
            }
            Section(header: Text("Note")) {
                TextEditor(text: $note)
                    .frame(minHeight: 64)
            }
        }
        .navigationTitle("\(work.name)-\(operation.name)")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Submit") {
                    Task { await createReport() }
                }
            }
        }
        .alert(manager: alertManager)
    }
}

#Preview {
    NavigationStack {
        ReportCreateView(work: Work(id: 2, name: "Work"))
    }.ja()
}
