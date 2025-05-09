//
//  SystemSettingsView.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/04/10.
//

import SwiftUI

struct SystemSettingsView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @AppStorage("systemId") private var systemId: Int = 0
    @Binding var isShowingSheet: Bool
    @State private var system: System = System(id: 0, name: "No System", year: 0)
    @State private var alertManager = AlertManager()
    
    private func getSystem() async {
        do {
            system = try await NetworkService.getSystem(systemId: systemId)
        } catch let error as NSError {
            alertManager.show(
                title: "Failed to fetch systems",
                message: "\(error.code): \(error.localizedDescription)"
            )
        }
    }
    private func deleteSystem() {
        Task {
            do {
                try await NetworkService.deleteSystem(systemId: systemId)
                UserDefaults.standard.removeObject(forKey: "systemId")
                UserDefaults.standard.removeObject(forKey: "userId")
                UserDefaults.standard.removeObject(forKey: "systemName")
                UserDefaults.standard.removeObject(forKey: "username")
                isLoggedIn = false
                isShowingSheet = false
            } catch let error as NSError {
                alertManager.show(title: "Failed to delete system", message: "\(error.code): \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                VStack() {
                    Image(systemName: "house")
                        .resizable()
                        .frame(width: 44, height: 44)
                    Text(system.name)
                }
                .frame(maxWidth: .infinity)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
                
                Section() {
                    NavigationLink {
                        SystemNameSettingView(system: system, onUpdateSystem: {
                            Task { await getSystem() }
                        })
                    } label: {
                        HStack {
                            Text("Name")
                            Spacer()
                            Text(system.name)
                                .foregroundStyle(.secondary)
                        }
                    }
                    NavigationLink {
                        SystemYearSettingView(system: system, onUpdateSystem: {
                            Task { await getSystem() }
                        })
                    } label: {
                        HStack {
                            Text("Year")
                            Spacer()
                            Text("\(system.year)")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                Section() {
                    Button("Delete") {
                        deleteSystem()
                    }
                    .foregroundStyle(.red)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("System Settings")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        isShowingSheet = false
                    }) {
                        Text("Done")
                    }
                }
            }
            .alert(manager: alertManager)
        }
        .task {
            await getSystem()
        }
    }
}

struct SystemNameSettingView: View {
    @Environment(\.dismiss) private var dismiss
    let systemId: Int
    @State var systemNameUpdateRequest: SystemNameUpdateRequest
    let onUpdateSystem: () -> Void
    @FocusState private var focusedFieldNumber: Int?
    @State private var alertManager = AlertManager()
    
    init(system: System, onUpdateSystem: @escaping () -> Void) {
        systemId = system.id
        _systemNameUpdateRequest = State(initialValue: .init(from: system))
        self.onUpdateSystem = onUpdateSystem
    }
    
    private func updateSystemName() async {
        do {
            try await NetworkService.updateSystemName(systemId: systemId, systemNameUpdateRequest: systemNameUpdateRequest)
            UserDefaults.standard.set(systemNameUpdateRequest.name, forKey: "systemName")
            onUpdateSystem()
            dismiss()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: "\(error.localizedDescription)")
        }
    }
    
    var body: some View {
        Form {
            TextField(
                "System Name",
                text: $systemNameUpdateRequest.name
            )
            .focused($focusedFieldNumber, equals: 0)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Name")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Change") {
                    Task { await updateSystemName() }
                }
            }
        }
        .alert(manager: alertManager)
        .onAppear {
            focusedFieldNumber = 0
        }
    }
}

struct SystemYearSettingView: View {
    @Environment(\.dismiss) private var dismiss
    let systemId: Int
    @State var systemYearUpdateRequest: SystemYearUpdateRequest
    let onUpdateSystem: () -> Void
    @State private var alertManager = AlertManager()
    
    init(system: System, onUpdateSystem: @escaping () -> Void) {
        self.systemId = system.id
        _systemYearUpdateRequest = State(initialValue: .init(from: system))
        self.onUpdateSystem = onUpdateSystem
    }
    
    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: Date())
        return Array((currentYear - 20)...(currentYear + 10))
    }
    private func updateSystemYear() async {
        do {
            try await NetworkService.updateSystemYear(systemId: systemId, systemYearUpdateRequest: systemYearUpdateRequest)
            onUpdateSystem()
            dismiss()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: "\(error.localizedDescription)")
        }
    }
    
    var body: some View {
        Form {
            Picker("Year", selection: $systemYearUpdateRequest.year) {
                ForEach(years, id: \.self) { year in
                    Text("\(year)").tag(year)
                }
            }
            .pickerStyle(.wheel)
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Year")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Change") {
                    Task { await updateSystemYear() }
                }
            }
        }
        .alert(manager: alertManager)
    }
}

#Preview {
    SystemSettingsView(isShowingSheet: .constant(true)).ja()
}
