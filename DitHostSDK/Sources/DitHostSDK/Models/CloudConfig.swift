//
//  CloudInitSchema.swift
//
//
//  Created by Ryan Coffman on 10/30/25.
//

import Foundation
import JSONSchemaBuilder
import Yams

/// Cloud-config schema based on https://raw.githubusercontent.com/canonical/cloud-init/main/cloudinit/config/schemas/schema-cloud-config-v1.json
/// This represents the comprehensive cloud-init configuration format used for initializing cloud instances
@Schemable
public struct CloudConfig: Codable {
  /// Description: Cloud-config schema
  /// Defines the structure for cloud-init user data configuration

  // MARK: - Core Properties

  /// Configuration version identifier
  public let cloudConfigVersion: String?

  /// Merge behavior for cloud-config data
  public let mergeHow: MergeStrategy?

  /// List of users to create on the system
  public let users: [User]?

  /// Groups to create on the system
  public let groups: [Group]?

  /// Packages to install
  public let packages: [String]?

  /// Package upgrade behavior
  public let packageUpgrade: Bool?

  /// Package repositories to configure
  public let packageRepos: [String]?

  /// Write files configuration
  public let writeFiles: [WriteFile]?

  /// SSH key configuration
  public let sshKeys: SSHKeys?

  /// Run commands during different boot phases
  public let runCmd: [String]?
  public let bootcmd: [String]?
  public let runcmd: [String]?

  /// Timezone configuration
  public let timezone: String?

  /// Locale configuration
  public let locale: String?

  /// NTP (Network Time Protocol) configuration
  public let ntp: NTPConfig?

  /// Hostname configuration
  public let hostname: String?

  /// Hosts file management
  public let manageEtcHosts: Bool?

  /// Network configuration
  public let network: NetworkConfiguration?

  /// Mount configuration
  public let mounts: [MountPoint]?

  /// Swap configuration
  public let swap: SwapConfig?

  /// Power state configuration (reboot, shutdown)
  public let powerState: PowerState?

  /// Phone home configuration for reporting status
  public let phoneHome: PhoneHome?

  public init(
    cloudConfigVersion: String? = nil,
    mergeHow: MergeStrategy? = nil,
    users: [User]? = nil,
    groups: [Group]? = nil,
    packages: [String]? = nil,
    packageUpgrade: Bool? = nil,
    packageRepos: [String]? = nil,
    writeFiles: [WriteFile]? = nil,
    sshKeys: SSHKeys? = nil,
    runCmd: [String]? = nil,
    bootcmd: [String]? = nil,
    runcmd: [String]? = nil,
    timezone: String? = nil,
    locale: String? = nil,
    ntp: NTPConfig? = nil,
    hostname: String? = nil,
    manageEtcHosts: Bool? = nil,
    network: NetworkConfiguration? = nil,
    mounts: [MountPoint]? = nil,
    swap: SwapConfig? = nil,
    powerState: PowerState? = nil,
    phoneHome: PhoneHome? = nil
  ) {
    self.cloudConfigVersion = cloudConfigVersion
    self.mergeHow = mergeHow
    self.users = users
    self.groups = groups
    self.packages = packages
    self.packageUpgrade = packageUpgrade
    self.packageRepos = packageRepos
    self.writeFiles = writeFiles
    self.sshKeys = sshKeys
    self.runCmd = runCmd
    self.bootcmd = bootcmd
    self.runcmd = runcmd
    self.timezone = timezone
    self.locale = locale
    self.ntp = ntp
    self.hostname = hostname
    self.manageEtcHosts = manageEtcHosts
    self.network = network
    self.mounts = mounts
    self.swap = swap
    self.powerState = powerState
    self.phoneHome = phoneHome
  }

  // MARK: - Coding Keys

  private enum CodingKeys: String, CodingKey {
    case cloudConfigVersion = "cloud_config_version"
    case mergeHow = "merge_how"
    case users
    case groups
    case packages
    case packageUpgrade = "package_upgrade"
    case packageRepos = "package_repos"
    case writeFiles = "write_files"
    case sshKeys = "ssh_keys"
    case runCmd = "run_cmd"
    case bootcmd
    case runcmd
    case timezone
    case locale
    case ntp
    case hostname
    case manageEtcHosts = "manage_etc_hosts"
    case network
    case mounts
    case swap
    case powerState = "power_state"
    case phoneHome = "phone_home"
  }

  public func generateCloudConfig() throws -> String {
    let yamlString = try YAMLEncoder().encode(self)
    return "#cloud-config\n\(yamlString)"
  }
}

// MARK: - Supporting Types

@Schemable
public enum MergeStrategy: String, Codable, CaseIterable {
  case list = "list"
  case dict = "dict"
  case str = "str"
  case replace = "replace"
}

@Schemable
public struct User: Codable {
  public let name: String
  public let gecos: String?
  public let homedir: String?
  public let primaryGroup: String?
  public let groups: [String]?
  public let selinuxUser: String?
  public let lockPasswd: Bool?
  public let inactive: Bool?
  public let passwd: String?
  public let noCreateHome: Bool?
  public let createHome: Bool?
  public let system: Bool?
  public let noUserGroup: Bool?
  public let sshAuthorizedKeys: [String]?
  public let sshImportId: [String]?
  public let sshRedirectUser: Bool?
  public let shell: String?
  public let sudo: [String]?
  public let uid: Int?

  private enum CodingKeys: String, CodingKey {
    case name, gecos, homedir, groups, passwd, shell, sudo, uid
    case primaryGroup = "primary_group"
    case selinuxUser = "selinux_user"
    case lockPasswd = "lock_passwd"
    case inactive
    case noCreateHome = "no_create_home"
    case createHome = "create_home"
    case system
    case noUserGroup = "no_user_group"
    case sshAuthorizedKeys = "ssh_authorized_keys"
    case sshImportId = "ssh_import_id"
    case sshRedirectUser = "ssh_redirect_user"
  }
}

@Schemable
public struct Group: Codable {
  public let name: String
  public let members: [String]?

  public init(name: String, members: [String]? = nil) {
    self.name = name
    self.members = members
  }
}

@Schemable
public struct WriteFile: Codable {
  public let content: String
  public let path: String
  public let owner: String?
  public let permissions: String?
  public let encoding: String?
  public let `defer`: Bool?

  public init(
    content: String,
    path: String,
    owner: String? = nil,
    permissions: String? = nil,
    encoding: String? = nil,
    defer: Bool? = nil
  ) {
    self.content = content
    self.path = path
    self.owner = owner
    self.permissions = permissions
    self.encoding = encoding
    self.`defer` = `defer`
  }
}

@Schemable
public struct SSHKeys: Codable {
  public let rsa_private: String?
  public let rsa_public: String?
  public let dsa_private: String?
  public let dsa_public: String?
  public let ecdsa_private: String?
  public let ecdsa_public: String?
  public let ed25519_private: String?
  public let ed25519_public: String?
}

@Schemable
public struct NTPConfig: Codable {
  public let enabled: Bool?
  public let servers: [String]?
  public let pools: [String]?

  public init(enabled: Bool? = nil, servers: [String]? = nil, pools: [String]? = nil) {
    self.enabled = enabled
    self.servers = servers
    self.pools = pools
  }
}

@Schemable
public struct NetworkConfiguration: Codable {
  public let version: Int?
  public let config: String?

  public init(version: Int? = nil, config: String? = nil) {
    self.version = version
    self.config = config
  }
}

@Schemable
public struct MountPoint: Codable {
  public let device: String
  public let mountpoint: String
  public let fstype: String?
  public let options: String?

  public init(device: String, mountpoint: String, fstype: String? = nil, options: String? = nil) {
    self.device = device
    self.mountpoint = mountpoint
    self.fstype = fstype
    self.options = options
  }
}

@Schemable
public struct SwapConfig: Codable {
  public let filename: String?
  public let size: String?
  public let maxsize: String?

  public init(filename: String? = nil, size: String? = nil, maxsize: String? = nil) {
    self.filename = filename
    self.size = size
    self.maxsize = maxsize
  }
}

@Schemable
public struct PowerState: Codable {
  public let delay: String?
  public let mode: PowerMode?
  public let message: String?
  public let timeout: Int?
  public let condition: String?

  public init(
    delay: String? = nil,
    mode: PowerMode? = nil,
    message: String? = nil,
    timeout: Int? = nil,
    condition: String? = nil
  ) {
    self.delay = delay
    self.mode = mode
    self.message = message
    self.timeout = timeout
    self.condition = condition
  }
}

@Schemable
public enum PowerMode: String, Codable, CaseIterable {
  case poweroff
  case halt
  case reboot
}

@Schemable
public struct PhoneHome: Codable {
  public let url: String?
  public let post: [String]?
  public let tries: Int?

  public init(url: String? = nil, post: [String]? = nil, tries: Int? = nil) {
    self.url = url
    self.post = post
    self.tries = tries
  }
}
