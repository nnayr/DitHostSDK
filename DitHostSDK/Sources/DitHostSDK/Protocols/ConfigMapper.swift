//
//  ConfigMapper.swift
//
//
//  Created by Ryan Coffman on 10/30/25.
//

import Foundation
import JSONSchema
import JSONSchemaBuilder

/// A protocol for mapping configuration data from one format to another.
///
/// ConfigMapper enables type-safe transformation of configuration data by defining:
/// - An input configuration type that conforms to `Schemable` for validation
/// - An output configuration type for the transformed result
/// - A mapping function that performs the transformation
///
/// # Example Usage
/// ```swift
/// struct MyConfigMapper: ConfigMapper {
///   typealias InputConfig = RawConfig
///   typealias OutputConfig = ProcessedConfig
///
///   func map(input: RawConfig) throws -> ProcessedConfig {
///     return ProcessedConfig(
///       name: input.name,
///       value: input.value * 2
///     )
///   }
/// }
/// ```
public protocol ConfigMapper {
  /// The input configuration type that must be validatable through a schema
  associatedtype InputConfig: Schemable

  /// The output configuration type after transformation
  associatedtype OutputConfig

  /// Maps validated input configuration to the desired output format
  /// - Parameter input: The validated input configuration data
  /// - Returns: The transformed output configuration
  /// - Throws: Any error that occurs during the mapping process
  func map(input: InputConfig.Schema.Output) throws -> OutputConfig
}

/// Default implementations for ConfigMapper providing convenient validation and mapping methods
extension ConfigMapper {
  /// Validates JSON data against the input schema and maps it to the output configuration
  /// - Parameter jsonValue: The JSON data to validate and transform
  /// - Returns: The mapped output configuration
  /// - Throws: Schema validation errors or mapping errors
  public func validateAndMap(jsonValue: JSONValue) throws -> OutputConfig {
    let input = try InputConfig.schema.parseAndValidate(jsonValue)
    return try self.map(input: input)
  }

  /// Validates codable configuration data and maps it to the output configuration
  /// - Parameter config: The codable configuration data to validate and transform
  /// - Returns: The mapped output configuration
  /// - Throws: JSON conversion errors, schema validation errors, or mapping errors
  public func validateAndMap(config: any Codable) throws -> OutputConfig {
    let jsonValue = try transcodeAsJson(config, to: JSONValue.self)
    return try validateAndMap(jsonValue: jsonValue)
  }
}

// MARK: - Codable Transcoding

/// Transcodes from one Codable type to another using JSON as an intermediate format.
///
/// This function provides a convenient way to convert between different `Codable` types by:
/// 1. Encoding the source object to JSON data using `JSONEncoder`
/// 2. Decoding the JSON data to the target type using `JSONDecoder`
///
/// This approach is useful when you have two similar `Codable` types that share common
/// structure but may have different property names or minor structural differences.
///
/// - Parameters:
///   - source: The source object to transcode from
///   - targetType: The target type to transcode to
/// - Returns: An instance of the target type
/// - Throws: `EncodingError` if the source cannot be encoded, or `DecodingError` if the JSON cannot be decoded to the target type
///
/// # Example Usage
/// ```swift
/// struct SourceConfig: Codable {
///   let name: String
///   let value: Int
/// }
///
/// struct TargetConfig: Codable {
///   let name: String
///   let value: Int
/// }
///
/// let source = SourceConfig(name: "test", value: 42)
/// let target = try transcode(source, to: TargetConfig.self)
/// ```
public func transcodeAsJson<Source: Codable, Target: Codable>(
  _ source: Source,
  to targetType: Target.Type
) throws -> Target {
  return try transcode(source, to: targetType, encoder: JSONEncoder(), decoder: JSONDecoder())
}

/// Transcodes from one Codable type to another with custom encoder and decoder configurations.
///
/// This function provides full control over the transcoding process by allowing you to specify
/// custom `JSONEncoder` and `JSONDecoder` instances. This is useful when you need:
/// - Custom key encoding/decoding strategies (e.g., snake_case conversion)
/// - Specific date formatting strategies
/// - Custom data encoding formats
/// - Non-conforming float handling
///
/// - Parameters:
///   - source: The source object to transcode from
///   - targetType: The target type to transcode to
///   - encoder: Custom JSONEncoder to use for encoding the source
///   - decoder: Custom JSONDecoder to use for decoding to the target
/// - Returns: An instance of the target type
/// - Throws: `EncodingError` if the source cannot be encoded, or `DecodingError` if the JSON cannot be decoded to the target type
///
/// # Example Usage
/// ```swift
/// let encoder = JSONEncoder()
/// encoder.keyEncodingStrategy = .convertToSnakeCase
///
/// let decoder = JSONDecoder()
/// decoder.keyDecodingStrategy = .convertFromSnakeCase
/// decoder.dateDecodingStrategy = .iso8601
///
/// let target = try transcode(source, to: TargetConfig.self, encoder: encoder, decoder: decoder)
/// ```
public func transcode<Source: Codable, Target: Codable>(
  _ source: Source,
  to targetType: Target.Type,
  encoder: JSONEncoder,
  decoder: JSONDecoder
) throws -> Target {
  let data = try encoder.encode(source)
  return try decoder.decode(targetType, from: data)
}

// MARK: - Chainable Config Mapper

/// A configuration mapper that chains two mappers together in sequence.
///
/// `ChainedConfigMapper` enables composition of multiple configuration transformations by:
/// - Taking the output of the first mapper as input to the second mapper
/// - Maintaining type safety through generic constraints
/// - Providing the same `ConfigMapper` interface for further chaining
///
/// The generic constraints ensure that:
/// - The first mapper's output type is `Codable` (required for transcoding)
/// - The second mapper's input type matches the first mapper's output type
/// - The second mapper's input type conforms to `Schemable` for validation
///
/// # Example Usage
/// ```swift
/// let chainedMapper = ChainedConfigMapper(
///   first: rawToProcessedMapper,
///   second: processedToFinalMapper
/// )
///
/// let result = try chainedMapper.validateAndMap(jsonValue: inputJSON)
/// ```
public struct ChainedConfigMapper<FirstMapper: ConfigMapper, SecondMapper: ConfigMapper>:
  ConfigMapper
where
  FirstMapper.OutputConfig: Codable, SecondMapper.InputConfig: Schemable,
  SecondMapper.InputConfig.Schema.Output == FirstMapper.OutputConfig
{

  /// The input configuration type, inherited from the first mapper
  public typealias InputConfig = FirstMapper.InputConfig

  /// The output configuration type, inherited from the second mapper
  public typealias OutputConfig = SecondMapper.OutputConfig

  /// The first mapper in the chain
  private let firstMapper: FirstMapper

  /// The second mapper in the chain
  private let secondMapper: SecondMapper

  /// Creates a new chained config mapper
  /// - Parameters:
  ///   - first: The first mapper to apply
  ///   - second: The second mapper to apply to the first mapper's output
  public init(first: FirstMapper, second: SecondMapper) {
    self.firstMapper = first
    self.secondMapper = second
  }

  /// Maps input configuration through both mappers in sequence
  /// - Parameter input: The input configuration to transform
  /// - Returns: The final output after both transformations
  /// - Throws: Any error from either mapper in the chain
  public func map(input: FirstMapper.InputConfig.Schema.Output) throws -> SecondMapper.OutputConfig
  {
    let intermediateOutput = try firstMapper.map(input: input)
    return try secondMapper.map(input: intermediateOutput)
  }
}

/// Extension providing chainable methods for ConfigMapper implementations
extension ConfigMapper {
  /// Chains this config mapper with another mapper using fluent syntax.
  ///
  /// Creates a `ChainedConfigMapper` that applies this mapper first, then the next mapper
  /// to the result. The output type of this mapper must be `Codable` and match the input
  /// type of the next mapper for type safety.
  ///
  /// - Parameter nextMapper: The mapper to chain after this one
  /// - Returns: A chained config mapper that applies both transformations in sequence
  ///
  /// # Example Usage
  /// ```swift
  /// let pipeline = firstMapper
  ///   .then(secondMapper)
  ///   .then(thirdMapper)
  ///
  /// let result = try pipeline.validateAndMap(jsonValue: input)
  /// ```
  public func then<NextMapper: ConfigMapper>(
    _ nextMapper: NextMapper
  ) -> ChainedConfigMapper<Self, NextMapper>
  where
    OutputConfig: Codable, NextMapper.InputConfig: Schemable,
    NextMapper.InputConfig.Schema.Output == OutputConfig
  {
    return ChainedConfigMapper(first: self, second: nextMapper)
  }
}

/// A specialized config mapper protocol for transforming configurations into instance configurations.
///
/// This protocol constrains the output type to `InstanceConfig`, making it useful for mappers
/// that specifically handle instance-level configuration transformations.
///
/// # Example Usage
/// ```swift
/// struct DatabaseInstanceMapper: InstanceConfigMapper {
///   typealias InputConfig = DatabaseRawConfig
///
///   func map(input: DatabaseRawConfig) throws -> InstanceConfig {
///     return InstanceConfig(
///       instanceId: input.databaseName,
///       region: input.region,
///       resources: ResourceConfig(cpu: input.cpu, memory: input.memory)
///     )
///   }
/// }
/// ```
public protocol InstanceConfigMapper: ConfigMapper where OutputConfig == InstanceConfig {

}
