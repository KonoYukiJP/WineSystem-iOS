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

struct Label: Decodable {
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

struct Permission: Codable, Hashable {
    let resourceId: Int
    let actionId: Int
    
    private enum CodingKeys: String, CodingKey {
        case resourceId = "resource_id", actionId = "action_id"
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
    var actionName: String
    var isPermitted: Bool
    var localizedActionName: LocalizedStringKey {
        LocalizedStringKey(actionName)
    }
    
}
struct ResourcePermission: Identifiable {
    let id: Int
    var resourceName: String
    var actionPermissions: [ActionPermission]
    var localizedResourceName: LocalizedStringKey {
        LocalizedStringKey(resourceName)
    }
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
    var username: String
    var workId: Int
    var workName: String
    var operationId: Int
    var operationName: String
    var kindId: Int
    var kindName: String
    var featureId: Int?
    var featureName: String?
    var value: Double?
    var unit: String?
    var note: String?
    
    private enum CodingKeys: String, CodingKey {
        case id, date
        case userId = "user_id", username
        case workId = "work_id", workName = "work_name"
        case operationId = "operation_id", operationName = "operation_name"
        case kindId = "kind_id", kindName = "kind_name"
        case featureId = "feature_id", featureName = "feature_name"
        case value, unit, note
    }
}

 var dateFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.dateStyle = .long
    formatter.timeStyle = .short
    return formatter
}


