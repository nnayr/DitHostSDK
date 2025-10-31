//
//  InstanceInfo.swift
//  dithost-swift-sdk
//
//  Created by Ryan Coffman on 10/30/25.
//

import JSONSchema
import JSONSchemaBuilder

@Schemable
public enum InstanceStatus: Codable, Sendable {
  case starting
  case running
  case destroying
  case destroyed
  case errored

}

public struct InstanceInfo: Codable, Sendable {
  public var status: InstanceStatus
  public var ref: JSONValue

  public init(status: InstanceStatus, ref: JSONValue) {
    self.status = status
    self.ref = ref
  }
}
