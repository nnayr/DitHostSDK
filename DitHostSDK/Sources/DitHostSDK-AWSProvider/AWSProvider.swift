//
//  AWSProvider.swift
//
//
//  Created by Ryan Coffman on 10/30/25.
//

import AWSEC2
import DitHostSDK
import Foundation
import Glob
import JSONSchema
import JSONSchemaBuilder

public struct AWSProviderConfig {
  public let imageId: String?
  public let instanceType: String
  public let amiNamePattern: String?

  public init(
    imageId: String? = nil, instanceType: String = "t3.micro", amiNamePattern: String? = nil
  ) {
    self.imageId = imageId
    self.instanceType = instanceType
    self.amiNamePattern = amiNamePattern
  }
}

@Schemable
public struct AWSProviderRef {
  public let instanceId: String

  public init(instanceId: String) {
    self.instanceId = instanceId
  }
}

public enum AWSProviderError: Error, LocalizedError {
  case deploymentFailed(String)
  case instanceNotFound(String)
  case invalidConfiguration(String)
  case noAMIFound(String)

  public var errorDescription: String? {
    switch self {
    case .deploymentFailed(let message):
      return "Deployment failed: \(message)"
    case .instanceNotFound(let message):
      return "Instance not found: \(message)"
    case .invalidConfiguration(let message):
      return "Invalid configuration: \(message)"
    case .noAMIFound(let message):
      return "No AMI found: \(message)"
    }
  }
}

public class AWSProvider: Provider {

  public typealias Config = AWSProviderConfig
  public typealias Ref = AWSProviderRef

  private let ec2Client: EC2Client

  public init(ec2Client: EC2Client) {
    self.ec2Client = ec2Client
  }

  /// Finds the newest AMI that matches the given glob pattern
  /// - Parameter namePattern: A glob pattern to match AMI names against (e.g., "ubuntu-*-22.04-*")
  /// - Returns: The AMI ID of the newest matching image, or nil if no matches found
  func findNewestAMI(matching namePattern: String) async throws -> String? {
    // Create describe images input to get all available AMIs
    let describeImagesInput = DescribeImagesInput(
      owners: ["amazon", "self"]  // Include Amazon and self-owned AMIs
    )

    var allImages: [EC2ClientTypes.Image] = []

    // Use paginated API to get all images
    let paginator = ec2Client.describeImagesPaginated(input: describeImagesInput)
    for try await page in paginator {
      if let images = page.images {
        allImages.append(contentsOf: images)
      }
    }
    let pattern = try Glob.Pattern(namePattern)
    // Filter images that match the glob pattern and have valid names and creation dates
    let matchingImages = allImages.compactMap {
      image -> (image: EC2ClientTypes.Image, date: Date)? in
      guard let imageName = image.name,
        let creationDateString = image.creationDate
      else {
        return nil
      }

      // Use swift-glob for pattern matching
      if pattern.match(imageName) {
        return nil
      }

      // Parse the creation date (format: "2024-10-30T12:00:00.000Z")
      let formatter = ISO8601DateFormatter()
      formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

      guard let creationDate = formatter.date(from: creationDateString) else {
        return nil
      }

      return (image: image, date: creationDate)
    }

    // Find the image with the most recent creation date
    let newestImage = matchingImages.max { $0.date < $1.date }

    return newestImage?.image.imageId
  }

  /// Deploys a new instance using the specified configuration
  /// Either config.imageId or config.amiNamePattern must be provided
  public func deploy(config: AWSProviderConfig, instanceConfig: DitHostSDK.InstanceConfig)
    async throws -> InstanceInfo
  {

    let imageId: String

    if config.imageId != nil {
      // Use the provided imageId
      imageId = config.imageId!
    } else if let amiNamePattern = config.amiNamePattern {
      // Find the newest AMI matching the pattern
      guard let foundImageId = try await findNewestAMI(matching: amiNamePattern) else {
        throw AWSProviderError.noAMIFound(amiNamePattern)
      }
      imageId = foundImageId
    } else {
      throw AWSProviderError.invalidConfiguration(
        "Either imageId or amiNamePattern must be provided")
    }

    // Create RunInstances input
    let runInstancesInput = RunInstancesInput(
      imageId: imageId,
      instanceType: .init(rawValue: config.instanceType),
      maxCount: 1,
      minCount: 1,
      userData: try instanceConfig.userData.base64EncodedString()
    )

    // Run the instance
    let result = try await ec2Client.runInstances(input: runInstancesInput)

    guard let instance = result.instances?.first,
      let instanceId = instance.instanceId
    else {
      throw AWSProviderError.deploymentFailed("Failed to create instance")
    }

    let ref = AWSProviderRef(instanceId: instanceId)

    return InstanceInfo(
      status: .starting,
      ref: JSONValue.object([
        "instanceId": .string(ref.instanceId)
      ])
    )
  }

  public func getInfo(ref: AWSProviderRef) async throws -> InstanceInfo {
    let describeInput = DescribeInstancesInput(instanceIds: [ref.instanceId])
    let result = try await ec2Client.describeInstances(input: describeInput)

    guard let reservation = result.reservations?.first,
      let instance = reservation.instances?.first
    else {
      throw AWSProviderError.instanceNotFound("Instance \(ref.instanceId) not found")
    }

    let status: InstanceStatus = {
      switch instance.state?.name {
      case .pending:
        return .starting
      case .running:
        return .running
      case .stopping:
        return .destroying
      case .terminated:
        return .destroyed
      case .stopped:
        return .errored
      default:
        return .errored
      }
    }()

    return InstanceInfo(
      status: status,
      ref: JSONValue.object([
        "instanceId": .string(ref.instanceId)
      ])
    )
  }

  public func destroy(ref: AWSProviderRef) async throws {
    let terminateInput = TerminateInstancesInput(instanceIds: [ref.instanceId])
    _ = try await ec2Client.terminateInstances(input: terminateInput)
  }
}
