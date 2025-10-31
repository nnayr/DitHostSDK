//
//  AppDB.swift
//  dithost-swift-sdk
//
//  Created by Ryan Coffman on 10/30/25.
//

import JSONSchema

public struct VariableConfig: Codable {
  var id: String
  var config: JSONValue
}

public protocol BaseApp: Codable {
  var id: String { get }
  var instanceConfig: VariableConfig { get }
  var providerConfig: VariableConfig { get }
}

public protocol BaseAppFull: BaseApp {
  var provider: String? { get }
  var instanceInfo: InstanceInfo? { get }
}

public protocol AppDB {
  associatedtype App: BaseApp
  associatedtype AppFull: BaseAppFull

  func addApp(app: App) async throws
  func getApp(appID: String) async throws -> AppFull?
  func getAllApps() async throws -> [AppFull]
  func updateApp(appID: String, app: App) async throws
  func removeApp(appID: String) async throws
  func addInstanceInfo(appID: String, instanceInfo: InstanceInfo) async throws
  func removeInstanceInfo(appID: String) async throws
}
