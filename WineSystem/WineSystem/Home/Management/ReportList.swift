//
//  ReportList.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/04/28.
//

import SwiftUI

struct ReportList: View {
    @State private var reports: [Report] = []
    @State private var users: [User] = []
    @State private var works: [Work] = []
    @State private var operations: [Operation] = []
    @State private var features: [Feature] = []
    @State private var materials: [Material] = []
    @State private var tanks: [Tank] = []
    @State private var alertManager = AlertManager()
    
    private func getReports() async {
        do {
            reports = try await NetworkService.getReports()
            users = try await NetworkService.getUsers()
            works = try await NetworkService.getWorks()
            operations = try await NetworkService.getOperations()
            features = try await NetworkService.getFeatures()
            materials = try await NetworkService.getMaterials()
            tanks = try await NetworkService.getTanks()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    var body: some View {
        List {
            ForEach(reports) { report in
                NavigationLink(
                    destination: ReportEditView(
                        report: report,
                        users: users,
                        works: works,
                        operations: operations,
                        features: features,
                        materials: materials,
                        tanks: tanks
                    ),
                    label: {
                        ReportListCell(
                            report: report,
                            users: users,
                            works: works,
                            operations: operations,
                            features: features,
                            materials: materials,
                            tanks: tanks
                        )
                    }
                )
            }
        }
        .navigationTitle("Reports")
        .alert(manager: alertManager)
        .task {
            await getReports()
        }
    }
}

struct ReportListCell: View {
    let report: Report
    let users: [User]
    let works: [Work]
    let operations: [Operation]
    let features: [Feature]
    let materials: [Material]
    let tanks: [Tank]
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(report.date, formatter: dateFormatter)")
                Text(users.first(where: { $0.id == report.userId})?.name ?? "?")
            }
            HStack {
                Text(works.first(where: { $0.id == report.workId})?.localizedName ?? "?")
                Text("-")
                Text(operations.first(where: { $0.id == report.operationId})?.localizedName ?? "?")
            }
            Group {
                HStack {
                    if let operation = operations.first(where: { $0.id == report.operationId }) {
                        if operation.targetType == .material {
                            Text("Material")
                            Text(materials.first(where: { $0.id == report.kindId})?.name ?? "?")
                        } else {
                            Text("Tank")
                            Text(tanks.first(where: { $0.id == report.kindId})?.name ?? "?")
                        }
                    }
                }
                HStack {
                    if let featureId = report.featureId, let value = report.value {
                        Text(features.first(where: { $0.id == featureId})?.name ?? "?")
                        Text("\(value)")
                        Text(features.first(where: { $0.id == featureId})?.unit ?? "?")
                    }
                }
                if !report.note.isEmpty {
                    HStack {
                        Text("Note")
                        Text(report.note)
                    }
                }
            }
            .foregroundStyle(.secondary)
        }
    }
}

struct ReportEditView: View {
    @Environment(\.dismiss) private var dismiss
    let report: Report
    @State var newReportRequest: ReportUpdateRequest
    let users: [User]
    let works: [Work]
    let operations: [Operation]
    let features: [Feature]
    let materials: [Material]
    let tanks: [Tank]
    @State private var alertManager = AlertManager()
    
    init(report: Report, users: [User], works: [Work], operations: [Operation], features: [Feature], materials: [Material], tanks: [Tank]) {
        self.report = report
        _newReportRequest = State(initialValue: .init(from: report))
        self.users = users
        self.works = works
        self.operations = operations
        self.features = features
        self.materials = materials
        self.tanks = tanks
    }
    private func deleteReport() {
        Task {
            do {
                try await NetworkService.deleteReport(reportId: report.id)
                dismiss()
            } catch let error as NSError {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        List {
            NavigationLink(destination: DateEditView(date: $newReportRequest.date)) {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(newReportRequest.date, formatter: dateFormatter)
                }
            }
            Picker("User", selection: $newReportRequest.userId) {
                ForEach(users) { user in
                    Text(user.name).tag(user.id)
                }
            }
            Picker("Work", selection: $newReportRequest.workId) {
                ForEach(works) { work in
                    Text(work.localizedName).tag(work.id)
                }
            }
            Picker("Operation", selection: $newReportRequest.operationId) {
                ForEach(works.first(where: {$0.id == newReportRequest.workId})!.operationIds, id: \.self) { operationId in
                    if let operation = operations.first(where: { $0.id == operationId }) {
                        Text(operation.localizedName)
                            .tag(operation.id)
                    }
                }
            }
            if operations.first(where: { $0.id == newReportRequest.operationId})!.targetType == .material {
                Picker("Material", selection: $newReportRequest.kindId) {
                    ForEach(materials) { material in
                        Text(material.name).tag(material.id)
                    }
                }
            } else {
                Picker("Tank", selection: $newReportRequest.kindId) {
                    ForEach(tanks) { tank in
                        Text(tank.name).tag(tank.id)
                    }
                }
            }
            if !operations.first(where: { $0.id == newReportRequest.operationId})!.featureIds.isEmpty {
                Picker("Feature", selection: $newReportRequest.featureId) {
                    ForEach(features) { feature in
                        Text(feature.name).tag(feature.id)
                    }
                }
                NavigationLink(destination: ValueEditView(value: $newReportRequest.value)) {
                    HStack {
                        Text("Value")
                        Spacer()
                        Text(newReportRequest.value.map { String($0) } ?? "None")
                    }
                }
            }
            
            NavigationLink(destination: NoteEditView(
                text: $newReportRequest.note
            )) {
                HStack {
                    Text("Note")
                    Spacer()
                    Text(newReportRequest.note)
                }
            }
            
            Section {
                Button("Delete") {
                    deleteReport()
                }
                .foregroundStyle(.red)
            }
        }
        .pickerStyle(.navigationLink)
        .navigationTitle("Edit")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task {
                        do {
                            try await NetworkService.updateReport(reportId: report.id, reportUpdateRequest: newReportRequest)
                            dismiss()
                        } catch {
                            alertManager.show(title: "Error", message: error.localizedDescription)
                        }
                    }
                }
            }
        }
        .alert(manager: alertManager)
    }
}

struct DateEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var date: Date
    
    var body: some View {
        Form {
            DatePicker("Date", selection: $date)
                .pickerStyle(.inline)
        }
    }
}

struct ValueEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var value: Double?
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Form {
            TextField("Value", value: $value, format: .number)
                .focused($isFocused)
                .onSubmit {
                    dismiss()
                }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .navigationTitle("Value")
        .onAppear {
            isFocused = true
        }
    }
}

struct NoteEditView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Form {
            TextEditor(text: $text)
                .frame(minHeight: 64)
                .focused($isFocused)
        }
        .navigationTitle("Note")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            isFocused = true
        }
    }
}

#Preview {
    NavigationStack {
        ReportList()
    }.ja()
}
