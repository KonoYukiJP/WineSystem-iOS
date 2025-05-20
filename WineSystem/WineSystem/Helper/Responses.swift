//
//  System.swift
//  WineSystem
//
//  Created by 河野優輝 on 2024/11/20.
//

import Foundation
import SwiftUICore

struct Response: Decodable {
    let message: String
}
struct LoginResponse: Decodable {
    let token: String
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
struct Permission: Identifiable, Codable {
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

struct Permissions {
    var resources: [PResource]
    struct PResource: Identifiable {
        let id: Int
        var isExpanded: Bool
        var actions: [PAction]
    }
    struct PAction: Identifiable {
        let id: Int
        var isPermitted: Bool
    }
}
struct Resource: Identifiable, Decodable {
    var id: Int
    var name: String
    var localizedName: LocalizedStringKey { LocalizedStringKey(name) }
}
struct Action: Identifiable, Decodable {
    var id: Int
    var name: String
    var localizedName: LocalizedStringKey { LocalizedStringKey(name) }
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
    var operationIds: [Int]
    var localizedName: LocalizedStringKey { LocalizedStringKey(name) }
    private enum CodingKeys: String, CodingKey {
        case id, name, operationIds = "operation_ids"
    }
}
struct Operation: Identifiable, Hashable, Decodable {
    let id: Int
    let name: String
    let targetType: TargetType
    let featureIds: [Int]
    var localizedName: LocalizedStringKey { LocalizedStringKey(name) }
    enum TargetType: String, Decodable {
        case tank
        case material
        case features
    }
    private enum CodingKeys: String, CodingKey {
        case id, name, targetType = "target_type", featureIds = "feature_ids"
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
    var note: String
    
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
    ) -> Permissions {
        let resourcePermissions = resources.map { resource in
            let permittedActionIds = permissions
                .first(where: { $0.resourceId == resource.id })?
                .actionIds ?? []

            let actionPermissions = actions.map { action in
                Permissions.PAction(
                    id: action.id,
                    isPermitted: permittedActionIds.contains(action.id)
                )
            }

            return Permissions.PResource(
                id: resource.id,
                isExpanded: false,
                actions: actionPermissions
            )
        }

        return Permissions(resources: resourcePermissions)
    }
}
extension Permissions {
    init(resources: [Resource], actions: [Action]) {
        self.resources = resources.map { resource in
            let actionPermissions = actions.map { action in
                PAction(id: action.id, isPermitted: false)
            }
            return PResource(
                id: resource.id,
                isExpanded: true,
                actions: actionPermissions
            )
        }
    }
    func toPermissions() -> [Permission] {
        resources.compactMap { resource in
            let permittedActionIds = resource.actions
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
