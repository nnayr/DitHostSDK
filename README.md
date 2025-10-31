# DitHostSDK Documentation

DitHostSDK is a Swift package for managing application deployment and configuration across multiple cloud providers. It provides a flexible, type-safe framework for mapping configurations, managing application lifecycles, and integrating with various deployment providers.

## Package Structure

The SDK is organized into three main targets:

- **DitHostSDK**: Core types and protocols
- **DitHostSDK-AWSProvider**: AWS deployment provider implementation  

## Core Types

### Configuration Management

#### `ConfigMapper`
A protocol for mapping configuration data from one format to another with type-safe validation.

```swift
public protocol ConfigMapper {
    associatedtype InputConfig: Schemable
    associatedtype OutputConfig
    
    func map(input: InputConfig.Schema.Output) throws -> OutputConfig
}
```

**Key Features:**
- Input validation through JSON Schema
- Type-safe configuration transformation
- Support for chaining multiple mappers
- Built-in JSON and Codable conversion methods

**Usage Example:**
```swift
struct MyConfigMapper: ConfigMapper {
    typealias InputConfig = RawConfig
    typealias OutputConfig = ProcessedConfig
    
    func map(input: RawConfig) throws -> ProcessedConfig {
        return ProcessedConfig(
            name: input.name,
            value: input.value * 2
        )
    }
}
```

#### `ChainedConfigMapper`
Enables composition of multiple configuration transformations in sequence.

```swift
public struct ChainedConfigMapper<FirstMapper: ConfigMapper, SecondMapper: ConfigMapper>: ConfigMapper
```

**Fluent API:**
```swift
let pipeline = firstMapper
    .then(secondMapper)
    .then(thirdMapper)

let result = try pipeline.validateAndMap(jsonValue: input)
```

#### `InstanceConfigMapper`
A specialized config mapper protocol for transforming configurations into `InstanceConfig` objects.

```swift
public protocol InstanceConfigMapper: ConfigMapper where OutputConfig == InstanceConfig
```

### Application Management

#### `VariableConfig`
Represents a variadic configuration type corresponding to a predefined config mapper in AppController. Use for defining configs for specific providers and InstanceConfig types

```swift
public struct VariableConfig: Codable {
    var id: String
    var config: JSONValue
}
```

#### `BaseApp`
Protocol defining the core properties of an application.

```swift
public protocol BaseApp: Codable {
    var id: String { get }
    var instanceConfig: VariableConfig { get }
    var providerConfig: VariableConfig { get }
}
```

#### `BaseAppFull`
Extended application protocol that includes deployment information.

```swift
public protocol BaseAppFull: BaseApp {
    var provider: String? { get }
    var instanceInfo: InstanceInfo? { get }
}
```

### Instance Management

#### `InstanceConfig`
Configuration for deployment instances, containing user data for initialization.

```swift
@Schemable
public struct InstanceConfig: Codable {
    public var userData: String
    
    public init(userData: String) {
        self.userData = userData
    }
}
```

#### `InstanceStatus`
Enumeration representing the current state of a deployed instance.

```swift
@Schemable
public enum InstanceStatus: Codable, Sendable {
    case starting
    case running
    case destroying
    case destroyed
    case errored
}
```

#### `InstanceInfo`
Information about a deployed instance, including its status and provider-specific reference data.

```swift
public struct InstanceInfo: Codable, Sendable {
    public var status: InstanceStatus
    public var ref: JSONValue
    
    public init(status: InstanceStatus, ref: JSONValue) {
        self.status = status
        self.ref = ref
    }
}
```

### Provider System

#### `Provider`
Protocol for implementing deployment providers (AWS, Azure, GCP, etc.).

```swift
public protocol Provider {
    associatedtype Config
    associatedtype Ref: Schemable

    func deploy(config: Config, instanceConfig: InstanceConfig) async throws -> InstanceInfo
    func getInfo(ref: Ref.Schema.Output) async throws -> InstanceInfo
    func destroy(ref: Ref.Schema.Output) async throws
}
```

#### `ConfigurableProvider`
Wrapper that combines a config mapper with a provider for type-safe deployment.

```swift
public class ConfigurableProvider<C: ConfigMapper, P: Provider> where C.OutputConfig == P.Config {
    func deploy(config: JSONValue, instanceConfig: InstanceConfig) async throws -> InstanceInfo
}
```

#### `AnyConfigurableProvider`
Type-erased wrapper for configurable providers, enabling heterogeneous provider collections.

```swift
public class AnyConfigurableProvider {
    func deploy(config: JSONValue, instanceConfig: InstanceConfig) async throws -> InstanceInfo
    func destroy(ref: JSONValue) async throws
}
```

### Database Layer

#### `AppDB`
Protocol for application persistence, supporting CRUD operations and instance management.

```swift
public protocol AppDB {
    associatedtype App: BaseApp
    associatedtype AppFull: BaseAppFull
    
    func addApp(app: App) async throws
    func getApp(appId: String) async throws -> AppFull?
    func getAllApps() async throws -> [AppFull]
    func updateApp(appId: String, app: App) async throws
    func removeApp(appId: String) async throws
    func addInstanceInfo(appId: String, instanceInfo: InstanceInfo) async throws
    func removeInstanceInfo(appId: String) async throws
}
```

### Control Layer

#### `AppController`
High-level controller for managing application lifecycles with multiple providers and databases.

```swift
public class AppController<DB: AppDB> {
    let providers: [String: AnyConfigurableProvider]
    let instanceConfigMappers: [String: InstanceConfigMapper]
    let appDB: DB
    
    public func addApp(app: DB.App) async throws
    public func getApp(appId: String) async throws -> DB.AppFull
    public func removeApp(appId: String, force: Bool = false) async throws
    public func startApp(app: DB.AppFull) async throws
    public func stopApp(app: DB.AppFull) async throws
}
```

## AWS Provider Integration

### `AWSProvider`
Implementation of the `Provider` protocol for AWS EC2 deployments.

```swift
public class AWSProvider: Provider {
    public typealias Config = AWSProviderConfig
    public typealias Ref = AWSProviderRef
    
    public func deploy(config: AWSProviderConfig, instanceConfig: InstanceConfig) async throws -> InstanceInfo
    public func getInfo(ref: AWSProviderRef.Schema.Output) async throws -> InstanceInfo
    public func destroy(ref: AWSProviderRef.Schema.Output) async throws
}
```

### `AWSProviderConfig`
Configuration structure for AWS deployments.

```swift
public struct AWSProviderConfig {
    public let imageId: String
    public let instanceType: String
    public let amiNamePattern: String?
}
```

**Features:**
- Support for explicit AMI IDs or glob pattern matching
- Automatic discovery of newest AMI matching patterns

### `AWSProviderRef`
Reference structure for AWS instances.

```swift
@Schemable
public struct AWSProviderRef {
    public let instanceId: String
}
```


## Error Types

### `AppControllerError`
Errors that can occur during application management operations.

```swift
public enum AppControllerError: Error {
    case appRunning(String)
    case appNotRunning(String)
    case appNotFound(String)
    case invalidProviderId(String)
    case invalidInstanceConfigType(String)
}
```

### `AWSProviderError`
AWS-specific deployment and management errors.

```swift
public enum AWSProviderError: Error, LocalizedError {
    case deploymentFailed(String)
    case instanceNotFound(String)
    case invalidConfiguration(String)
    case noAMIFound(String)
}
```

### `DatabaseError`
Generic database operation errors.

```swift
public struct DatabaseError: Error {
    let message: String
}
```

## Utility Functions

### Configuration Transcoding
Functions for converting between different `Codable` types using JSON as an intermediate format.

```swift
public func transcodeAsJson<Source: Codable, Target: Codable>(
    _ source: Source,
    to targetType: Target.Type
) throws -> Target

public func transcode<Source: Codable, Target: Codable>(
    _ source: Source,
    to targetType: Target.Type,
    encoder: JSONEncoder,
    decoder: JSONDecoder
) throws -> Target
```

## Dependencies

- **JSONSchema**: JSON schema validation and parsing
- **JSONSchemaBuilder**: Schema builder macros and utilities
- **AWS SDK for Swift**: AWS service integration (EC2)
- **GRDB**: SQLite database framework
- **Yams**: YAML parsing support
- **swift-glob**: Glob pattern matching for AMI discovery

