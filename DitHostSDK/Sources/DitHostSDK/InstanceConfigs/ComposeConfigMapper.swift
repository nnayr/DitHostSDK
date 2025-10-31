//
//  ComposeConfigMapper.swift
//
//
//  Created by Ryan Coffman on 10/31/25.
//

import Foundation
import Yams

public struct ComposeConfigMapper: InstanceConfigMapper {
  public typealias InputConfig = ComposeConfig
  public typealias OutputConfig = InstanceConfig

  /// The destination path where the docker-compose file should be written in the cloud instance
  private let destinationPath: String

  /// Optional filename for the compose file (defaults to "docker-compose.yml")
  private let filename: String

  /// Optional additional packages to install (e.g., Docker, Docker Compose)
  private let additionalPackages: [String]

  /// Optional additional commands to run after writing the compose file
  private let additionalCommands: [String]

  public init(
    destinationPath: String = "/opt/docker",
    filename: String = "docker-compose.yml",
    additionalPackages: [String] = ["docker", "docker-compose"],
    additionalCommands: [String] = []
  ) {
    self.destinationPath = destinationPath
    self.filename = filename
    self.additionalPackages = additionalPackages
    self.additionalCommands = additionalCommands
  }

  public func map(input: ComposeConfig) throws -> InstanceConfig {
    // Convert ComposeConfig to YAML string
    let composeYaml = try YAMLEncoder().encode(input)

    // Create the full file path
    let fullPath = "\(destinationPath)/\(filename)"

    // Create a WriteFile configuration for the compose file
    let composeFile = WriteFile(
      content: composeYaml,
      path: fullPath
    )

    // Build the commands to run
    var commands = [
      "mkdir -p \(destinationPath)",
      "cd \(destinationPath)",
    ]

    // Add any additional commands provided during initialization
    commands.append(contentsOf: additionalCommands)

    // Create the CloudConfig with the compose file and necessary setup
    let cloudConfig = CloudConfig(
      packages: additionalPackages,
      packageUpgrade: true,
      writeFiles: [composeFile],
      bootcmd: commands
    )

    return InstanceConfig(userData: try cloudConfig.generateCloudConfig())
  }
}
