//
//  Requests.swift
//  WineSystem
//
//  Created by 河野優輝 on 2025/05/03.
//

import Foundation

struct LoginRequest: Codable {
    var systemId: Int
    var userId: Int
    var password: String
}
struct SystemCreateRequest: Encodable {
    var name: String
    var year: Int
    var ownerName: String
    var password: String
    private enum CodingKeys: String, CodingKey {
        case name, year, ownerName = "owner_name", password
    }
}
struct UserCreateRequest: Encodable {
    var name: String
    var password: String
    var roleId: Int
    var isEnabled: Bool
    private enum CodingKeys: String, CodingKey {
        case name, password, roleId = "role_id", isEnabled = "is_enabled"
    }
}
struct NewMaterialRequest: Encodable {
    var name: String
    var note: String
}
struct NewTankRequest: Encodable {
    var name: String
    var note: String
    var materialId: Int?
    enum CodingKeys: String, CodingKey {
        case name, note, materialId = "material_id"
    }
}
struct NewSensorRequest: Encodable {
    var name: String
    var unit: String
    var tankId: Int?
    var position: String
    var date: Date
    enum CodingKeys: String, CodingKey {
        case name, unit, tankId = "tank_id", position, date
    }
}
struct RoleCreateRequest: Encodable {
    let name: String
}
struct NewReportRequest: Encodable {
    var date: Date
    var userId: Int
    var workId: Int
    var operationId: Int
    var kindId: Int
    var featureId: Int?
    var value: Double?
    var note: String
    private enum CodingKeys: String, CodingKey {
        case date, userId = "user_id"
        case workId = "work_id"
        case operationId = "operation_id"
        case kindId = "kind_id"
        case featureId = "feature_id", value,note
    }
}
struct SystemNameUpdateRequest: Encodable {
    var name: String
}
struct SystemYearUpdateRequest: Encodable {
    var year: Int
}
struct UserUpdateRequest: Encodable {
    var name: String
    var roleId: Int
    var isEnabled: Bool
    private enum CodingKeys: String, CodingKey {
        case name, roleId = "role_id", isEnabled = "is_enabled"
    }
}
struct UsernameUpdateRequest: Encodable {
    var name: String
}
struct PasswordUpdateRequest: Encodable {
    var oldPassword: String
    var newPassword: String
    private enum CodingKeys: String, CodingKey {
        case oldPassword = "old_password"
        case newPassword = "new_password"
    }
}

struct ResourceActionPair: Hashable, Encodable {
    var resourceId: Int
    var actionId: Int
    private enum CodingKeys: String, CodingKey {
        case resourceId = "resource_id", actionId = "action_id"
    }
}
struct RoleUpdateRequest: Encodable {
    var name: String
    var inserts: [Permission]
    var deletes: [Permission]
}
struct BackupCreateRequest: Encodable {
    
}
struct BackupUpdateRequest: Encodable {
    let filename: String
}
extension LoginRequest {
    init() {
        systemId = 0
        userId = 0
        password = ""
    }
}

extension SystemCreateRequest {
    init() {
        name = ""
        year = Calendar.current.component(.year, from: Date())
        ownerName = ""
        password = ""
    }
}
extension UserCreateRequest {
    init() {
        name = ""
        password = ""
        roleId = 0
        isEnabled = true
    }
}
extension SystemNameUpdateRequest {
    init(from system: System) {
        self.name = system.name
    }
}
extension SystemYearUpdateRequest {
    init(from system: System) {
        self.year = system.year
    }
}
extension UserUpdateRequest {
    init(from user: User) {
        self.name = user.name
        self.roleId = user.roleId
        self.isEnabled = user.isEnabled
    }
}
extension UsernameUpdateRequest {
    init(from username: String) {
        self.name = username
    }
}
extension PasswordUpdateRequest {
    init() {
        oldPassword = ""
        newPassword = ""
    }
}
extension RoleUpdateRequest {
    init(from role: Role) {
        self.name = role.name
        self.inserts = []
        self.deletes = []
    }
}
extension NewMaterialRequest {
    init(from material: Material) {
        self.name = material.name
        self.note = material.note
    }
}
extension NewSensorRequest {
    init(from sensor: Sensor) {
        self.name = sensor.name
        self.unit = sensor.unit
        self.tankId = sensor.tankId
        self.position = sensor.position
        self.date = sensor.date
    }
}
extension NewTankRequest {
    init(from tank: Tank) {
        self.name = tank.name
        self.materialId = tank.materialId
        self.note = tank.note
    }
}
extension NewReportRequest {
    init(from report: Report) {
        self.date = report.date
        self.userId = report.userId
        self.workId = report.workId
        self.operationId = report.operationId
        self.kindId = report.kindId
        self.featureId = report.featureId
        self.value = report.value
        self.note = report.note ?? ""
    }
}
