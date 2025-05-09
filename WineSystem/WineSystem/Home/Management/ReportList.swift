//
//  ReportList.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/04/28.
//

import SwiftUI

struct ReportList: View {
    @AppStorage("systemId") private var systemId: Int = 0
    @State private var reports: [Report] = []
    @State private var alertManager = AlertManager()
    
    private func getReports() async {
        do {
            reports = try await NetworkService.getReports(systemId: systemId)
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    var body: some View {
        List {
            ForEach(reports) { report in
                NavigationLink(
                    destination: ReportEditView(
                        systemId: systemId,
                        report: report
                    ),
                    label: {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("\(report.date, formatter: dateFormatter)")
                                Text(report.username)
                            }
                            HStack {
                                Text("Work")
                                Text(report.workName)
                            }
                            HStack {
                                Text("Operation")
                                Text(report.operationName)
                            }
                            HStack {
                                Text("Kind")
                                Text(report.kindName)
                            }
                            HStack {
                                if let feature = report.featureName {
                                    Text(feature)
                                }
                                if let value = report.value {
                                    Text("\(value)")
                                }
                                if let unit = report.unit {
                                    Text(unit)
                                }
                            }
                            
                            if let note = report.note {
                                HStack {
                                    Text("Note")
                                    Text(note)
                                }
                            }
                        }
                    }
                )
            }
        }
        .alert(manager: alertManager)
        .task {
            await getReports()
        }
    }
}

struct ReportEditView: View {
    let systemId: Int
    let report: Report
    @State var date: Date
    @State var user: Item
    @State var work: Work
    @State var operation: Item
    @State var kind: Item
    @State var feature: Item
    @State var value: Double?
    @State var note: String
    @State private var alertManager = AlertManager()
    
    init(systemId: Int, report: Report) {
        self.systemId = systemId
        self.report = report
        _date = State(initialValue: report.date)
        _user = State(
            initialValue: Item(id: report.userId, name: report.username)
        )
        _work = State(
            initialValue: Work(id: report.workId, name: report.workName)
        )
        _operation = State(
            initialValue: Item(id: report.operationId, name: report.operationName)
        )
        _kind = State(
            initialValue: Item(id: report.kindId, name: report.kindName)
        )
        _feature = State(
            initialValue: Item(id: report.featureId ?? 0, name: report.featureName ?? "")
        )
        _value = State(initialValue: report.value)
        _note = State(initialValue: report.note ?? "")
    }
    
    var body: some View {
        List {
            NavigationLink(destination: DateEditView(date: $date)) {
                HStack {
                    Text("Date")
                    Spacer()
                    Text(date, formatter: dateFormatter)
                }
            }
            NavigationLink(destination: UserPicker(
                systemId: systemId,
                user: $user
            )) {
                HStack {
                    Text("Username")
                    Spacer()
                    Text(user.name)
                }
            }
            NavigationLink(destination: WorkPicker(work: $work)) {
                HStack {
                    Text("Work")
                    Spacer()
                    Text(work.name)
                }
            }
            NavigationLink(destination: OperationPicker(
                workId: work.id,
                operation: $operation
            )) {
                HStack {
                    Text("Operation")
                    Spacer()
                    Text(operation.name)
                }
            }
            NavigationLink(destination: KindPicker(
                systemId: systemId,
                workId: work.id,
                kind: $kind
            )) {
                HStack {
                    Text("Kind")
                    Spacer()
                    Text(kind.name)
                }
            }
            if [4, 13, 17].contains(where: { $0 == operation.id }) {
                NavigationLink(destination: FeaturePicker(feature: $feature)) {
                    HStack {
                        Text("Feature")
                        Spacer()
                        Text(feature.name)
                    }
                }
                NavigationLink(destination: ValueEditView(value: $value)) {
                    HStack {
                        Text("Value")
                        Spacer()
                        Text(value.map { String($0) } ?? "None")
                    }
                }
            }
            
            NavigationLink(destination: NoteEditView(
                titleKey: "Note",
                text: $note
            )) {
                HStack {
                    Text("Note")
                    Spacer()
                    Text(note)
                }
            }
        }
        .navigationTitle("Report Detail")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Save") {
                    Task {
                        do {
                            try await NetworkService.updateReport(reportId: report.id, newReportRequest: NewReportRequest(
                                date: date,
                                userId: user.id,
                                workId: work.id,
                                operationId: operation.id,
                                kindId: kind.id,
                                featureId: feature.id,
                                value: value,
                                note: note
                            ))
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

struct UserPicker: View {
    @Environment(\.dismiss) private var dismiss
    let systemId: Int
    @Binding var user: Item
    @State private var users: [Item] = []
    @State private var alertManager = AlertManager()
    
    var body: some View {
        Form {
            Picker("User", selection: $user) {
                ForEach(users) { user in
                    Text(user.name).tag(user)
                }
            }
            .pickerStyle(.inline)
            .onChange(of: user) {
                dismiss()
            }
        }
        .alert(manager: alertManager)
        .task {
            do {
                users = try await NetworkService.getUsersAsItems(systemId: systemId)
            } catch {
                alertManager.show(title: "Error", message: error.localizedDescription)
            }
        }
    }
}

struct WorkPicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var work: Work
    @State private var works: [Work] = []
    @State private var alertManager = AlertManager()
    
    var body: some View {
        Form {
            Picker("Work", selection: $work) {
                ForEach(works) { work in
                    Text(work.name).tag(work)
                }
            }
            .pickerStyle(.inline)
            .onChange(of: work) {
                dismiss()
            }
        }
        .alert(manager: alertManager)
        .task {
            do {
                works = try await NetworkService.getWorks()
            } catch {
                alertManager.show(title: "Error", message: error.localizedDescription)
            }
        }
    }
}

struct OperationPicker: View {
    @Environment(\.dismiss) private var dismiss
    let workId: Int
    @Binding var operation: Item
    @State private var operations: [Item] = []
    @State private var alertManager = AlertManager()
    
    var body: some View {
        Form {
            Picker("Operation", selection: $operation) {
                ForEach(operations) { operation in
                    Text(operation.name).tag(operation)
                }
            }
            .pickerStyle(.inline)
            .onChange(of: operation) {
                dismiss()
            }
        }
        .alert(manager: alertManager)
        .task {
            do {
                operations = try await NetworkService.getOperationsAsItems(workId: workId)
            } catch {
                alertManager.show(title: "Error", message: error.localizedDescription)
            }
        }
    }
}

struct KindPicker: View {
    @Environment(\.dismiss) private var dismiss
    let systemId: Int
    let workId: Int
    @Binding var kind: Item
    @State private var materials: [Item] = []
    @State private var tanks: [Item] = []
    @State private var alertManager = AlertManager()
    
    var body: some View {
        Form {
            if workId == 1 {
                Picker("Kind", selection: $kind) {
                    ForEach(materials) { material in
                        Text(material.name).tag(material)
                    }
                }
                .pickerStyle(.inline)
                .onChange(of: kind) {
                    dismiss()
                }
            } else {
                Picker("Kind", selection: $kind) {
                    ForEach(tanks) { tank in
                        Text(tank.name).tag(tank)
                    }
                }
                .pickerStyle(.inline)
                .onChange(of: kind) {
                    dismiss()
                }
            }
        }
        .alert(manager: alertManager)
        .task {
            do {
                if workId == 1 {
                    materials = try await NetworkService.getMaterialsAsItems(systemId: systemId)
                } else {
                    tanks = try await NetworkService.getTanksAsItems(systemId: systemId)
                }
            } catch {
                alertManager.show(title: "Error", message: error.localizedDescription)
            }
        }
    }
}

struct FeaturePicker: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var feature: Item
    @State private var features: [Item] = []
    @State private var alertManager = AlertManager()
    
    var body: some View {
        Form {
            Picker("Feature", selection: $feature) {
                ForEach(features) { feature in
                    Text(feature.name).tag(feature)
                }
            }
            .pickerStyle(.inline)
            .onChange(of: feature) {
                dismiss()
            }
        }
        .task {
            do {
                features = try await NetworkService.getFeaturesAsItems()
            } catch {
                alertManager.show(title: "Error", message: error.localizedDescription)
            }
        }
    }
}

struct ValueEditView: View {
    
    @Binding var value: Double?
    
    
    var body: some View {
        Form {
            TextField("Value", value: $value, format: .number)
                .multilineTextAlignment(.trailing)
        }
    }
}

struct NoteEditView: View {
    @Environment(\.dismiss) private var dismiss
    let titleKey: String
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Form {
            TextEditor(text: $text)
                .frame(minHeight: 64)
                .focused($isFocused)
                .onSubmit {
                    dismiss()
                }
        }
        .navigationTitle(titleKey)
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
