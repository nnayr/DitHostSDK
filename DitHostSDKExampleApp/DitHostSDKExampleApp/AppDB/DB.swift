import DitHostSDK
import Foundation
//
//  GRDBAppDB.swift
//  DitHostSDKExampleApp
//
//  Created by Ryan Coffman on 10/31/25.
//
import GRDB

public struct DBApp: Codable, FetchableRecord, PersistableRecord, TableRecord, BaseApp {
  public var provider: String?

  public var id: String
  public var instanceConfig: VariableConfig
  public var providerConfig: VariableConfig

  public static let instanceInfo = hasOne(DBAppInstanceInfo.self)
}

public struct DBAppInstanceInfo: Codable, FetchableRecord, PersistableRecord, TableRecord {
  public var appID: String
  public var instanceInfo: DitHostSDK.InstanceInfo
}

public struct ExampleDB {
  let dbWriter: any DatabaseWriter
  private var migrator: DatabaseMigrator {
    var migrator = DatabaseMigrator()
    migrator.eraseDatabaseOnSchemaChange = true
    migrator.registerMigration("init") { db in
      try db.create(table: "app") { t in
        t.column("id", .text).primaryKey()
        t.column("instanceConfig", .jsonText).notNull()
        t.column("providerConfig", .jsonText).notNull()
      }
      try db.create(table: "instance_info") { t in
        t.column("appID", .text).primaryKey().references("app", column: "id")
        t.column("instanceInfo", .jsonText).notNull()
      }
    }
    return migrator
  }

  public init(_ dbWriter: any DatabaseWriter) throws {
    self.dbWriter = dbWriter
    try migrator.migrate(dbWriter)
  }
}

public struct DBAppFull: BaseAppFull, FetchableRecord {
  public var id: String

  public var instanceConfig: DitHostSDK.VariableConfig

  public var providerConfig: DitHostSDK.VariableConfig

  public var provider: String?

  public var instanceInfo: DitHostSDK.InstanceInfo?

}
extension ExampleDB: AppDB {

  public typealias App = DBApp
  public typealias AppFull = DBAppFull

  public func addApp(app: DBApp) async throws {
    try await dbWriter.write { db in
      try app.insert(db)
    }
  }

  public func getApp(appID: String) async throws -> DBAppFull? {
    return try await dbWriter.read { db in
      // Get the app record
      return try DBApp.including(optional: DBApp.instanceInfo).filter(Column("appID") == appID)
        .asRequest(of: DBAppFull.self).fetchOne(db)
    }
  }

  public func getAllApps() async throws -> [DBAppFull] {
    return try await dbWriter.read { db in
      let apps = try DBApp.including(optional: DBApp.instanceInfo).asRequest(of: DBAppFull.self)
        .fetchAll(db)

      return apps
    }
  }

  public func updateApp(appID: String, app: DBApp) async throws {
    try await dbWriter.write { db in
      var updatedApp = app
      updatedApp.id = appID  // Ensure the ID matches
      try updatedApp.update(db)
    }
  }

  public func removeApp(appID: String) async throws {
    try await dbWriter.write { db in
      // Remove the app
      try DBApp.deleteOne(db, key: appID)
    }
  }

  public func addInstanceInfo(appID: String, instanceInfo: DitHostSDK.InstanceInfo) async throws {
    try await dbWriter.write { db in
      let instanceInfoRecord = DBAppInstanceInfo(
        appID: appID,
        instanceInfo: instanceInfo
      )
      try instanceInfoRecord.insert(db)
    }
  }

  public func removeInstanceInfo(appID: String) async throws {
    try await dbWriter.write { db in
      try DBAppInstanceInfo
        .filter(Column("appID") == appID)
        .deleteAll(db)
    }
  }
}
