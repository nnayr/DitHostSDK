//
//  ComposeConfig.swift
//
//
//  Created by Ryan Coffman on 10/30/25.
//

import Foundation
import JSONSchemaBuilder

/// Docker Compose Configuration based on compose-spec JSON schema
/// This represents the comprehensive Docker Compose format for defining multi-container applications
///

@Schemable
public struct ComposeConfig: Codable {

  // MARK: - Top-level Properties

  /// Compose file format version
  public let version: String?

  /// Application name
  public let name: String?

  /// Services defined in the compose file
  public let services: [String: Service]?

  /// Networks defined in the compose file
  public let networks: [String: Network]?

  /// Volumes defined in the compose file
  public let volumes: [String: Volume]?

  public init(
    version: String? = nil,
    name: String? = nil,
    services: [String: Service]? = nil,
    networks: [String: Network]? = nil,
    volumes: [String: Volume]? = nil,
  ) {
    self.version = version
    self.name = name
    self.services = services
    self.networks = networks
    self.volumes = volumes
  }
}

// MARK: - Service Definition
@Schemable
public struct Service: Codable {

  // MARK: - Build Configuration
  public let build: BuildConfig?

  // MARK: - Container Configuration
  public let image: String?
  public let containerName: String?
  public let hostname: String?
  public let domainname: String?
  public let user: String?
  public let workingDir: String?
  public let entrypoint: StringOrArray?
  public let command: StringOrArray?
  public let environment: EnvironmentVariables?
  public let envFile: StringOrArray?

  // MARK: - Resource Configuration
  public let cpus: Double?
  public let cpuCount: Int?
  public let cpuPercent: Double?
  public let cpuShares: Int?
  public let cpuQuota: String?
  public let cpuPeriod: String?
  public let cpuset: String?
  public let memLimit: String?
  public let memReservation: String?
  public let memSwapLimit: String?
  public let memSwappiness: Int?
  public let oomKillDisable: Bool?
  public let oomScoreAdj: Int?

  // MARK: - Networking
  public let ports: [PortMapping]?
  public let expose: [String]?
  public let networks: NetworksConfig?
  public let networkMode: String?
  public let externalLinks: [String]?
  public let links: [String]?
  public let dns: StringOrArray?
  public let dnsSearch: StringOrArray?
  public let dnsOpt: [String]?
  public let extraHosts: StringOrArray?
  public let macAddress: String?

  // MARK: - Storage
  public let volumes: [VolumeMount]?
  public let volumesFrom: [String]?
  public let tmpfs: StringOrArray?
  public let devices: [String]?

  // MARK: - Dependencies and Lifecycle
  public let dependsOn: DependsOnConfig?
  public let restart: RestartPolicy?
  public let deploy: DeployConfig?

  // MARK: - Health and Monitoring
  public let healthcheck: HealthcheckConfig?

  // MARK: - Security and Permissions
  public let privileged: Bool?
  public let capAdd: [String]?
  public let capDrop: [String]?
  public let securityOpt: [String]?
  public let isolation: String?
  public let readOnly: Bool?
  public let shmSize: String?

  // MARK: - Logging
  public let logging: LoggingConfig?

  // MARK: - Runtime Configuration
  public let pid: String?
  public let ipc: String?
  public let uts: String?
  public let cgroupParent: String?
  public let runtime: String?
  public let sysctls: [String: String]?
  public let ulimits: [String: UlimitConfig]?

  // MARK: - Labels and Metadata
  public let labels: [String: String]?

  // MARK: - External Configuration
  public let configs: [ConfigMount]?
  public let secrets: [SecretMount]?

  // MARK: - Platform and Architecture
  public let platform: String?

  private enum CodingKeys: String, CodingKey {
    case build, image, hostname, domainname, user, entrypoint, command
    case environment, ports, expose, networks, volumes, restart, deploy
    case healthcheck, privileged, labels, configs, secrets, platform
    case containerName = "container_name"
    case workingDir = "working_dir"
    case envFile = "env_file"
    case cpus
    case cpuCount = "cpu_count"
    case cpuPercent = "cpu_percent"
    case cpuShares = "cpu_shares"
    case cpuQuota = "cpu_quota"
    case cpuPeriod = "cpu_period"
    case cpuset
    case memLimit = "mem_limit"
    case memReservation = "mem_reservation"
    case memSwapLimit = "memswap_limit"
    case memSwappiness = "mem_swappiness"
    case oomKillDisable = "oom_kill_disable"
    case oomScoreAdj = "oom_score_adj"
    case networkMode = "network_mode"
    case externalLinks = "external_links"
    case links, dns
    case dnsSearch = "dns_search"
    case dnsOpt = "dns_opt"
    case extraHosts = "extra_hosts"
    case macAddress = "mac_address"
    case volumesFrom = "volumes_from"
    case tmpfs, devices
    case dependsOn = "depends_on"
    case capAdd = "cap_add"
    case capDrop = "cap_drop"
    case securityOpt = "security_opt"
    case isolation
    case readOnly = "read_only"
    case shmSize = "shm_size"
    case logging, pid, ipc, uts
    case cgroupParent = "cgroup_parent"
    case runtime, sysctls, ulimits
  }
}

// MARK: - Build Configuration

@Schemable
public struct BuildConfig: Codable {
  public let context: String?
  public let dockerfile: String?
  public let args: [String: String]?
  public let target: String?
  public let network: String?
  public let ssh: [String]?
  public let cache_from: [String]?
  public let cache_to: [String]?
  public let extra_hosts: StringOrArray?
  public let isolation: String?
  public let privileged: Bool?
  public let labels: [String: String]?
  public let no_cache: Bool?
  public let pull: Bool?
  public let shm_size: String?
  public let ulimits: [String: UlimitConfig]?
  public let platforms: [String]?
}

// MARK: - Environment Variables

@Schemable
public enum EnvironmentVariables: Codable {
  case dictionary([String: String?])
  case array([String])

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let dict = try? container.decode([String: String?].self) {
      self = .dictionary(dict)
    } else if let array = try? container.decode([String].self) {
      self = .array(array)
    } else {
      throw DecodingError.typeMismatch(
        EnvironmentVariables.self,
        DecodingError.Context(
          codingPath: decoder.codingPath, debugDescription: "Expected dictionary or array")
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .dictionary(let dict):
      try container.encode(dict)
    case .array(let array):
      try container.encode(array)
    }
  }
}

// MARK: - String or Array Type

@Schemable
public enum StringOrArray: Codable {
  case string(String)
  case array([String])

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let string = try? container.decode(String.self) {
      self = .string(string)
    } else if let array = try? container.decode([String].self) {
      self = .array(array)
    } else {
      throw DecodingError.typeMismatch(
        StringOrArray.self,
        DecodingError.Context(
          codingPath: decoder.codingPath, debugDescription: "Expected string or array")
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .string(let string):
      try container.encode(string)
    case .array(let array):
      try container.encode(array)
    }
  }
}

// MARK: - Port Mapping

@Schemable
public struct PortMapping: Codable {
  public let published: String?
  public let target: Int?
  public let `protocol`: String?
  public let mode: String?
}

// MARK: - Networks Configuration

@Schemable
public enum NetworksConfig: Codable {
  case array([String])
  case dictionary([String: NetworkServiceConfig])

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let array = try? container.decode([String].self) {
      self = .array(array)
    } else if let dict = try? container.decode([String: NetworkServiceConfig].self) {
      self = .dictionary(dict)
    } else {
      throw DecodingError.typeMismatch(
        NetworksConfig.self,
        DecodingError.Context(
          codingPath: decoder.codingPath, debugDescription: "Expected array or dictionary")
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .array(let array):
      try container.encode(array)
    case .dictionary(let dict):
      try container.encode(dict)
    }
  }
}

@Schemable
public struct NetworkServiceConfig: Codable {
  public let aliases: [String]?
  public let ipv4Address: String?
  public let ipv6Address: String?
  public let linkLocalIPs: [String]?
  public let priority: Int?

  private enum CodingKeys: String, CodingKey {
    case aliases
    case ipv4Address = "ipv4_address"
    case ipv6Address = "ipv6_address"
    case linkLocalIPs = "link_local_ips"
    case priority
  }
}

// MARK: - Volume Mount

@Schemable
public struct VolumeMount: Codable {
  public let type: String?
  public let source: String?
  public let target: String?
  public let readOnly: Bool?
  public let bind: BindOptions?
  public let volume: VolumeOptions?
  public let tmpfs: TmpfsOptions?

  private enum CodingKeys: String, CodingKey {
    case type, source, target, bind, volume, tmpfs
    case readOnly = "read_only"
  }
}

@Schemable
public struct BindOptions: Codable {
  public let propagation: String?
  public let createHostPath: Bool?
  public let selinux: String?

  private enum CodingKeys: String, CodingKey {
    case propagation, selinux
    case createHostPath = "create_host_path"
  }
}

@Schemable
public struct VolumeOptions: Codable {
  public let nocopy: Bool?
}

@Schemable
public struct TmpfsOptions: Codable {
  public let size: String?
  public let mode: String?
}

// MARK: - Depends On Configuration

@Schemable
public enum DependsOnConfig: Codable {
  case array([String])
  case dictionary([String: DependencyCondition])

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let array = try? container.decode([String].self) {
      self = .array(array)
    } else if let dict = try? container.decode([String: DependencyCondition].self) {
      self = .dictionary(dict)
    } else {
      throw DecodingError.typeMismatch(
        DependsOnConfig.self,
        DecodingError.Context(
          codingPath: decoder.codingPath, debugDescription: "Expected array or dictionary")
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .array(let array):
      try container.encode(array)
    case .dictionary(let dict):
      try container.encode(dict)
    }
  }
}

@Schemable
public struct DependencyCondition: Codable {
  public let condition: String?
  public let restart: Bool?
}

// MARK: - Restart Policy

@Schemable
public enum RestartPolicy: String, Codable, CaseIterable {
  case no = "no"
  case always = "always"
  case onFailure = "on-failure"
  case unlessStopped = "unless-stopped"
}

// MARK: - Deploy Configuration

@Schemable
public struct DeployConfig: Codable {
  public let mode: String?
  public let replicas: Int?
  public let labels: [String: String]?
  public let updateConfig: UpdateConfig?
  public let rollbackConfig: RollbackConfig?
  public let resources: ResourceConfig?
  public let restartPolicy: DeployRestartPolicy?
  public let placement: PlacementConfig?
  public let endpointMode: String?

  private enum CodingKeys: String, CodingKey {
    case mode, replicas, labels, resources, placement
    case updateConfig = "update_config"
    case rollbackConfig = "rollback_config"
    case restartPolicy = "restart_policy"
    case endpointMode = "endpoint_mode"
  }
}
@Schemable
public struct UpdateConfig: Codable {
  public let parallelism: Int?
  public let delay: String?
  public let failureAction: String?
  public let monitor: String?
  public let maxFailureRatio: Double?
  public let order: String?

  private enum CodingKeys: String, CodingKey {
    case parallelism, delay, monitor, order
    case failureAction = "failure_action"
    case maxFailureRatio = "max_failure_ratio"
  }
}

@Schemable
public struct RollbackConfig: Codable {
  public let parallelism: Int?
  public let delay: String?
  public let failureAction: String?
  public let monitor: String?
  public let maxFailureRatio: Double?
  public let order: String?

  private enum CodingKeys: String, CodingKey {
    case parallelism, delay, monitor, order
    case failureAction = "failure_action"
    case maxFailureRatio = "max_failure_ratio"
  }
}

@Schemable
public struct ResourceConfig: Codable {
  public let limits: ResourceLimits?
  public let reservations: ResourceReservations?
}

@Schemable
public struct ResourceLimits: Codable {
  public let cpus: String?
  public let memory: String?
  public let pids: Int?
}

@Schemable
public struct ResourceReservations: Codable {
  public let cpus: String?
  public let memory: String?
  public let genericResources: [GenericResource]?

  private enum CodingKeys: String, CodingKey {
    case cpus, memory
    case genericResources = "generic_resources"
  }
}

@Schemable
public struct GenericResource: Codable {
  public let discreteResourceSpec: DiscreteResourceSpec?

  private enum CodingKeys: String, CodingKey {
    case discreteResourceSpec = "discrete_resource_spec"
  }
}

@Schemable
public struct DiscreteResourceSpec: Codable {
  public let kind: String?
  public let value: Int?
}

@Schemable
public struct DeployRestartPolicy: Codable {
  public let condition: String?
  public let delay: String?
  public let maxAttempts: Int?
  public let window: String?

  private enum CodingKeys: String, CodingKey {
    case condition, delay, window
    case maxAttempts = "max_attempts"
  }
}

@Schemable
public struct PlacementConfig: Codable {
  public let constraints: [String]?
  public let preferences: [PlacementPreference]?
  public let maxReplicasPerNode: Int?

  private enum CodingKeys: String, CodingKey {
    case constraints, preferences
    case maxReplicasPerNode = "max_replicas_per_node"
  }
}

@Schemable
public struct PlacementPreference: Codable {
  public let spread: String?
}

// MARK: - Healthcheck Configuration

@Schemable
public struct HealthcheckConfig: Codable {
  public let test: StringOrArray?
  public let interval: String?
  public let timeout: String?
  public let retries: Int?
  public let startPeriod: String?
  public let startInterval: String?
  public let disable: Bool?

  private enum CodingKeys: String, CodingKey {
    case test, interval, timeout, retries, disable
    case startPeriod = "start_period"
    case startInterval = "start_interval"
  }
}

// MARK: - Logging Configuration

@Schemable
public struct LoggingConfig: Codable {
  public let driver: String?
  public let options: [String: String]?
}

// MARK: - Ulimit Configuration

@Schemable
public struct UlimitConfig: Codable {
  public let soft: Int?
  public let hard: Int?
}

// MARK: - Config and Secret Mounts

@Schemable
public struct ConfigMount: Codable {
  public let source: String?
  public let target: String?
  public let uid: String?
  public let gid: String?
  public let mode: String?
}

@Schemable
public struct SecretMount: Codable {
  public let source: String?
  public let target: String?
  public let uid: String?
  public let gid: String?
  public let mode: String?
}

// MARK: - Top-level Network Definition

@Schemable
public struct Network: Codable {
  public let driver: String?
  public let driverOpts: [String: String]?
  public let attachable: Bool?
  public let ipam: IPAMConfig?
  public let external: ExternalConfig?
  public let `internal`: Bool?
  public let labels: [String: String]?
  public let enableIpv6: Bool?
  public let name: String?

  private enum CodingKeys: String, CodingKey {
    case driver, attachable, ipam, external, `internal`, labels, name
    case driverOpts = "driver_opts"
    case enableIpv6 = "enable_ipv6"
  }
}

@Schemable
public struct IPAMConfig: Codable {
  public let driver: String?
  public let config: [IPAMSubnetConfig]?
  public let options: [String: String]?
}

@Schemable
public struct IPAMSubnetConfig: Codable {
  public let subnet: String?
  public let ipRange: String?
  public let gateway: String?
  public let auxAddresses: [String: String]?

  private enum CodingKeys: String, CodingKey {
    case subnet, gateway
    case ipRange = "ip_range"
    case auxAddresses = "aux_addresses"
  }
}

// MARK: - Top-level Volume Definition

@Schemable
public struct Volume: Codable {
  public let driver: String?
  public let driverOpts: [String: String]?
  public let external: ExternalConfig?
  public let labels: [String: String]?
  public let name: String?

  private enum CodingKeys: String, CodingKey {
    case driver, external, labels, name
    case driverOpts = "driver_opts"
  }
}

// MARK: - External Configuration

@Schemable
public enum ExternalConfig: Codable {
  case boolean(Bool)
  case object(ExternalObjectConfig)

  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let bool = try? container.decode(Bool.self) {
      self = .boolean(bool)
    } else if let object = try? container.decode(ExternalObjectConfig.self) {
      self = .object(object)
    } else {
      throw DecodingError.typeMismatch(
        ExternalConfig.self,
        DecodingError.Context(
          codingPath: decoder.codingPath, debugDescription: "Expected boolean or object")
      )
    }
  }

  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .boolean(let bool):
      try container.encode(bool)
    case .object(let object):
      try container.encode(object)
    }
  }
}

@Schemable
public struct ExternalObjectConfig: Codable {
  public let name: String?
}
