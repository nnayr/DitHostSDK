//
//  InstanceConfig.swift
//
//
//  Created by Ryan Coffman on 10/30/25.
//

import Foundation
import JSONSchemaBuilder
import Yams

@Schemable
public struct InstanceConfig: Codable {
  public var userData: String

  public init(userData: String) {
    self.userData = userData
  }
}
