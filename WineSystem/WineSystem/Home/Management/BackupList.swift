//
//  BackupList.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/05/11.
//

import SwiftUI

struct BackupList: View {
    @AppStorage("systemId") private var systemId: Int = 0
    @State private var alertManager = AlertManager()
    @State private var backups: [Backup] = []
    @State private var isShowingSheet: Bool = false
    
    private func getBackups() async {
        do {
            backups = try await NetworkService.getBackups(systemId: systemId)
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func deleteBackup(at offsets: IndexSet) {
        Task {
            do {
                try await NetworkService.deleteBackup(systemId: systemId, filename: backups[offsets.first!].filename)
                backups.remove(atOffsets: offsets)
            } catch let error as NSError {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }
    private func restore(filename: String) {
        Task {
            do {
                try await NetworkService.updateBackup(systemId: systemId, filename: filename)
            } catch let error as NSError {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(backups) { backup in
                HStack {
                    VStack(alignment: .leading) {
                        Text(backup.createdAt, formatter: dateFormatter)
                        Text(backup.createdBy)
                        if !backup.note.isEmpty {
                            Text(backup.note)
                        }
                    }
                    Spacer()
                    Button(action: {
                        restore(filename: backup.filename)
                    }) {
                        Text("Restore")
                    }
                }
            }
            .onDelete(perform: deleteBackup)
        }
        .navigationTitle("Backups")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Create Backup", systemImage: "plus") {
                    isShowingSheet = true
                }
            }
        }
        .alert(manager: alertManager)
        .task {
            await getBackups()
        }
        .sheet(isPresented: $isShowingSheet) {
            BackupCreateView(
                isShowingSheet: $isShowingSheet,
                systemId: systemId,
                onCreateBackup: {
                    Task { await getBackups() }
                }
            )
        }
    }
}

struct BackupCreateView: View {
    @Binding var isShowingSheet: Bool
    let systemId: Int
    let onCreateBackup: () -> Void
    @State private var backupCreateRequest: BackupCreateRequest
    @State private var alertManager = AlertManager()
    @FocusState private var isFocused: Bool
    
    init(isShowingSheet: Binding<Bool>, systemId: Int, onCreateBackup: @escaping () -> Void) {
        _isShowingSheet = isShowingSheet
        self.systemId = systemId
        _backupCreateRequest = State(initialValue: .init(username: UserDefaults.standard.string(forKey: "username") ?? "??"))
        self.onCreateBackup = onCreateBackup
    }
    
    private func createBackup() async {
        do {
            try await NetworkService.createBackup(
                systemId: systemId,
                backupCreateRequest: backupCreateRequest
            )
            onCreateBackup()
            isShowingSheet = false
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                HStack {
                    Text("User")
                    Spacer()
                    Text(backupCreateRequest.username)
                }
                Section(header: Text("Note")) {
                    TextEditor(text: $backupCreateRequest.note)
                        .frame(minHeight: 64)
                        .focused($isFocused)
                }
            }
            .navigationTitle("New Backup")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        isShowingSheet = false
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        Task { await createBackup() }
                    }
                }
                
            }
            .alert(manager: alertManager)
            .onAppear { isFocused = true }
        }
    }
}

#Preview {
    NavigationStack {
        BackupList()
    }.ja()
}
