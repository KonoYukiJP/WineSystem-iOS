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
                Text(work.localizedName)
            }
            
            Section(header: Text("Operation")) {
                ForEach(work.operationIds, id: \.self) { operationId in
                    if let operation = operations.first(where: { $0.id == operationId }) {
                        NavigationLink(
                            destination:
                                operation.featureIds.isEmpty
                            ? AnyView(ReportPostView(work: work, operation: operation))
                            : AnyView(FeaturesView(work: work, operation: operation)),
                            label: {
                                Text(operation.localizedName)
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle(work.localizedName)
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
    let work: Work
    let operation: Operation
    @State private var materials: [Material] = []
    @State private var tanks: [Tank] = []
    let feature: Feature?
    @State private var newReportRequest = NewReportRequest()
    @State private var alertManager = AlertManager()
    
    init(work: Work, operation: Operation, feature: Feature? = nil) {
        self.feature = feature
        self.work = work
        self.operation = operation
    }
    
    private func getMaterials() async {
        do {
            materials = try await NetworkService.getMaterials(systemId: systemId)
            newReportRequest.kindId = materials.first?.id ?? 0
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
            newReportRequest.kindId = tanks.first?.id ?? 0
        } catch let error as NSError {
            alertManager.show(
                title: "\(error.code)",
                message: error.localizedDescription
            )
        }
    }
    
    private func createReport() async {
        let newReportRequest = NewReportRequest(
            date: newReportRequest.date,
            userId: userId,
            workId: work.id,
            operationId: operation.id,
            kindId: newReportRequest.kindId,
            featureId: feature?.id,
            value: newReportRequest.value,
            note: newReportRequest.note
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
            DatePicker("Date", selection: $newReportRequest.date)
            
            Section {}
            HStack {
                Text("Work");Spacer();Text(work.localizedName)
            }
            HStack {
                Text("Operation");Spacer();Text(operation.localizedName)
            }
            if operation.targetType == .material {
                Picker(selection: $newReportRequest.kindId) {
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
                Picker(selection: $newReportRequest.kindId) {
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
                    TextField("Value", value: $newReportRequest.value, format: .number)
                        .multilineTextAlignment(.trailing)
                    Text(feature.unit)
                }
            }
            Section(header: Text("Note")) {
                TextEditor(text: $newReportRequest.note)
                    .frame(minHeight: 64)
            }
        }
        .navigationTitle("Report")
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
        ReportCreateView(work: Work(id: 2, name: "Work", operationIds: [1]))
    }.ja()
}
