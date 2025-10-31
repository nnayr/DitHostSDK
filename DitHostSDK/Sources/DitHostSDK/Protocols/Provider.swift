//
//  File.swift
//  dithost-swift-sdk
//
//  Created by Ryan Coffman on 10/30/25.
//

import Foundation
import JSONSchema
import JSONSchemaBuilder

public protocol Provider {
  associatedtype Config
  associatedtype Ref: Schemable

  func deploy(config: Config, instanceConfig: InstanceConfig) async throws -> InstanceInfo
  func getInfo(ref: Ref.Schema.Output) async throws -> InstanceInfo
  func destroy(ref: Ref.Schema.Output) async throws
}

extension Provider {
  public func getInfo(ref: JSONValue) async throws -> InstanceInfo {
    return try await self.getInfo(ref: try Ref.schema.parseAndValidate(ref))
  }

  public func destroy(ref: JSONValue) async throws {
    return try await self.destroy(ref: try Ref.schema.parseAndValidate(ref))
  }
}
