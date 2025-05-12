//
//  System.swift
//  WineSystem
//
//  Created by 河野優輝 on 2024/11/20.
//

import Foundation
import SwiftUICore

struct Response: Codable {
    let message: String
}

struct Value: Decodable {
    var value: String
}

struct Item: Identifiable, Hashable, Decodable {
    var id: Int
    var name: String
}

struct System: Identifiable, Decodable {
    var id: Int
    var name: String
    var year: Int
}

struct User: Identifiable, Hashable, Decodable {
    var id: Int
    var name: String
    var roleId: Int
    var isEnabled: Bool

    private enum CodingKeys: String, CodingKey {
        case id, name, roleId = "role_id", isEnabled = "is_enabled"
    }
}

struct Permission: Identifiable, Codable, Hashable {
    var id: Int { resourceId }
    let resourceId: Int
    let actionIds: [Int]
    
    private enum CodingKeys: String, CodingKey {
        case resourceId = "resource_id", actionIds = "action_ids"
    }
}
struct Role: Identifiable, Codable {
    let id: Int
    let name: String
    let permissions: [Permission]
    
    private enum CodingKeys: String, CodingKey {
        case id, name, permissions
    }
}

struct ActionPermission: Identifiable {
    let id: Int
    var isPermitted: Bool
}
struct ResourcePermission: Identifiable {
    let id: Int
    var actionPermissions: [ActionPermission]
}

struct Action: Identifiable, Decodable {
    var id: Int
    var name: String
    var localizedActionName: LocalizedStringKey {
        LocalizedStringKey(name)
    }
}

struct Resource: Identifiable, Decodable {
    var id: Int
    var name: String
    var localizedResourceName: LocalizedStringKey {
        LocalizedStringKey(name)
    }
}


struct Material: Identifiable, Decodable {
    var id: Int
    var name: String
    var note: String
}

struct Tank: Identifiable, Decodable {
    var id: Int
    var name: String
    var note: String
    var materialId: Int?
    
    private enum CodingKeys: String, CodingKey {
        case id, name, note, materialId = "material_id"
    }
}

struct Sensor: Identifiable, Decodable {
    var id: Int
    var name: String
    var unit: String
    var tankId: Int?
    var position: String
    var date: Date
    
    private enum CodingKeys: String, CodingKey {
        case id, name, unit, tankId = "tank_id", position, date
    }
}

struct Work: Identifiable, Hashable, Decodable {
    var id: Int
    var name: String
    var localizedWorkName: LocalizedStringKey {
        LocalizedStringKey(name)
    }
}

struct Operation: Identifiable, Hashable, Decodable {
    var id: Int
    var name: String
    var workId: Int
    
    var localizedOperationName: LocalizedStringKey {
        LocalizedStringKey(name)
    }
    private enum CodingKeys: String, CodingKey {
        case id, name, workId = "work_id"
    }
}

struct Feature: Identifiable, Decodable {
    var id: Int
    var name: String
    var unit: String
}

struct Report: Identifiable, Decodable {
    var id: Int
    var date: Date
    var userId: Int
    var workId: Int
    var operationId: Int
    var kindId: Int
    var featureId: Int?
    var value: Double?
    var note: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, date
        case userId = "user_id"
        case workId = "work_id"
        case operationId = "operation_id"
        case kindId = "kind_id"
        case featureId = "feature_id"
        case value, note
    }
}

struct Backup: Decodable {
    var backups: [String]
}

var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .short
    return formatter
}

extension Role {
    func toResourcePermissions(
            resources: [Resource],
            actions: [Action]
        ) -> [ResourcePermission] {
            return resources.map { resource in
                let permittedActionIds = permissions
                    .first(where: { $0.resourceId == resource.id })?
                    .actionIds ?? []

                let actionPermissions = actions.map { action in
                    ActionPermission(
                        id: action.id,
                        isPermitted: permittedActionIds.contains(action.id)
                    )
                }

                return ResourcePermission(
                    id: resource.id,
                    actionPermissions: actionPermissions
                )
            }
        }
}
extension Array where Element == ResourcePermission {
    func toPermissions() -> [Permission] {
        self.compactMap { resource in
            let permittedActionIds = resource.actionPermissions
                .filter { $0.isPermitted }
                .map { $0.id }

            guard !permittedActionIds.isEmpty else { return nil }

            return Permission(
                resourceId: resource.id,
                actionIds: permittedActionIds
            )
        }
    }
}
