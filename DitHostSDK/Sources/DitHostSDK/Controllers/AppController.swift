//
//  AppController.swift
//  dithost-swift-sdk
//
//  Created by Ryan Coffman on 10/30/25.
//

import JSONSchema

public enum AppControllerError: Error {
  case appRunning(String)
  case appNotRunning(String)
  case appNotFound(String)
  case invalidProviderId(String)
  case invalidInstanceConfigType(String)
}

public class AppController<DB: AppDB> {
  let providers: [String: AnyConfigurableProvider]
  let instanceConfigMappers: [String: InstanceConfigMapper]

  let appDB: DB

  public init(
    appDB: DB, providers: [String: AnyConfigurableProvider],
    instanceConfigMappers: [String: InstanceConfigMapper]
  ) {
    self.appDB = appDB
    self.providers = providers
    self.instanceConfigMappers = instanceConfigMappers
  }

  public func addApp(app: DB.App) async throws {
    try await self.appDB.addApp(app: app)
  }

  public func getApp(appId: String) async throws -> DB.AppFull {
    guard let app = try await self.appDB.getApp(appID: appId) else {
      throw AppControllerError.appNotFound(appId)
    }
    return app
  }

  public func removeApp(appId: String, force: Bool = false) async throws {
    let app = try await self.getApp(appId: appId)
    if app.instanceInfo != nil {
      if force {
        try await self.stopApp(app: app)
      } else {
        throw AppControllerError.appRunning(appId)
      }
    }
    try await self.appDB.removeApp(appID: app.id)
  }

  public func startApp(app: DB.AppFull) async throws {
    if app.instanceInfo != nil {
      throw AppControllerError.appRunning(app.id)
    }
    let instanceConfig = try self.getInstanceConfig(app: app)
    let provider = try self.getProvider(providerId: app.providerConfig.id)
    let instanceInfo = try await provider.deploy(
      config: app.providerConfig.config, instanceConfig: instanceConfig)

    try await self.appDB.addInstanceInfo(appID: app.id, instanceInfo: instanceInfo)
  }

  public func stopApp(app: DB.AppFull) async throws {
    guard let instanceInfo = app.instanceInfo else {
      throw AppControllerError.appNotRunning(app.id)
    }
    let provider = try self.getProvider(providerId: app.providerConfig.id)
    try await provider.destroy(ref: instanceInfo.ref)
  }

  func getProvider(providerId: String) throws -> AnyConfigurableProvider {
    guard let provider = self.providers[providerId] else {
      throw AppControllerError.invalidProviderId(providerId)
    }
    return provider
  }

  func getInstanceConfig(app: DB.AppFull) throws -> InstanceConfig {
    guard let mapper = self.instanceConfigMappers[app.instanceConfig.id] else {
      throw AppControllerError.invalidInstanceConfigType(app.instanceConfig.id)
    }
    return try mapper.validateAndMap(jsonValue: app.instanceConfig.config)
  }
}

public class ConfigurableProvider<C: ConfigMapper, P: Provider> where C.OutputConfig == P.Config {
  let mapper: C
  let provider: P
  public init(mapper: C, provider: P) {
    self.mapper = mapper
    self.provider = provider
  }
  func deploy(config: JSONValue, instanceConfig: InstanceConfig) async throws -> InstanceInfo {
    let providerConfig = try self.mapper.validateAndMap(jsonValue: config)
    return try await self.provider.deploy(config: providerConfig, instanceConfig: instanceConfig)
  }
}

public class AnyConfigurableProvider {
  private let _deploy: (JSONValue, InstanceConfig) async throws -> InstanceInfo
  private let _destroy: (JSONValue) async throws -> Void
  public init<C: ConfigMapper, P: Provider>(_ provider: ConfigurableProvider<C, P>)
  where C.OutputConfig == P.Config {
    self._deploy = { config, instanceConfig in
      return try await provider.deploy(config: config, instanceConfig: instanceConfig)
    }
    self._destroy = { ref in
      try await provider.provider.destroy(ref: ref)

    }
  }

  func deploy(config: JSONValue, instanceConfig: InstanceConfig) async throws -> InstanceInfo {
    return try await _deploy(config, instanceConfig)
  }

  func destroy(ref: JSONValue) async throws {
    return try await _destroy(ref)
  }
}
