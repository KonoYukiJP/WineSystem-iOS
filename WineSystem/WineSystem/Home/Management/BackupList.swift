//
//  BackupList.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/05/11.
//

import SwiftUI

struct BackupList: View {
    @State private var alertManager = AlertManager()
    @State private var backups: Backup = Backup(backups: [])
    
    private func getBackups() async {
        do {
            backups = try await NetworkService.getBackups()
        } catch let error as NSError {
            alertManager.show(title: "\(error.code)", message: error.localizedDescription)
        }
    }
    private func deleteBackup(at offsets: IndexSet) {
        Task {
            do {
                try await NetworkService.deleteBackup(filename: backups.backups[offsets.first!])
                backups.backups.remove(atOffsets: offsets)
            } catch let error as NSError {
                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
            }
        }
    }
    
    var body: some View {
        List {
            Button("Create Backup") {
                Task {
                    do {
                        try await NetworkService.createBackup(backupCreateRequest: BackupCreateRequest())
                        await getBackups()
                    } catch let error as NSError {
                        alertManager.show(title: "\(error.code)", message: error.localizedDescription)
                    }
                }
            }
            
            Section {}
            ForEach(backups.backups, id: \.self) { backup in
                HStack {
                    Text(backup)
                    Spacer()
                    Button("Restore") {
                        Task {
                            do {
                                try await NetworkService.updateBackup(backupUpdateRequest: BackupUpdateRequest(filename: backup))
                            } catch let error as NSError {
                                alertManager.show(title: "\(error.code)", message: error.localizedDescription)
                            }
                        }
                    }
                }
            }
            .onDelete(perform: deleteBackup)
        }
        .navigationTitle("Backups")
        .alert(manager: alertManager)
        .task {
            await getBackups()
        }
    }
}

#Preview {
    BackupList()
}
