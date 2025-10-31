//
//  DitHostSDKExampleAppApp.swift
//  DitHostSDKExampleApp
//
//  Created by Ryan Coffman on 10/30/25.
//

import AWSEC2
import DitHostSDK
import DitHostSDK_AWSProvider
import GRDB
import JSONSchemaBuilder
import SwiftUI

@main
struct DitHostSDKExampleAppApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

@Schemable
struct AWSConfig {
  var instanceType: String
}

class AWSConfigMapper: ConfigMapper {

  typealias InputConfig = AWSConfig
  typealias OutputConfig = AWSProvider.Config

  func map(input: AWSConfig) throws -> AWSProvider.Config {
    return AWSProvider.Config(
      instanceType: input.instanceType, amiNamePattern: "al2023-ami-2023.*-x86_64")
  }
}
struct ExampleApp {

  public static func initDB() -> ExampleDB {
    do {

      // Create the "Application Support/Database" directory if needed
      let fileManager = FileManager.default
      let appSupportURL = try fileManager.url(
        for: .applicationSupportDirectory, in: .userDomainMask,
        appropriateFor: nil, create: true)
      let directoryURL = appSupportURL.appendingPathComponent("Database", isDirectory: true)
      try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)

      // Open or create the database
      let databaseURL = directoryURL.appendingPathComponent("db.sqlite")
      let dbPool = try DatabasePool(path: databaseURL.path)

      // Create the AppDatabase (migrations run automatically in the initializer)
      let db = try ExampleDB(dbPool)

      return db
    } catch {
      // Replace this implementation with code to handle the error appropriately.
      // fatalError() causes the application to generate a crash log and terminate.
      //
      // Typical reasons for an error here include:
      // * The parent directory cannot be created, or disallows writing.
      // * The database is not accessible, due to permissions or data protection when the device is locked.
      // * The device is out of space.
      // * The database could not be migrated to its latest schema version.
      // Check the error message to determine what the actual problem was.
      fatalError("Unresolved error \(error)")
    }
  }
  private static func initAppController() -> AppController<ExampleDB> {
    do {

      let db = initDB()
      let awsProvider = AWSProvider(ec2Client: try EC2Client(region: "us-east-1"))
      let providers = [
        "aws": AnyConfigurableProvider(
          ConfigurableProvider(mapper: AWSConfigMapper(), provider: awsProvider))
      ]
      let instanceConfigMappers = ["docker-compose": ComposeConfigMapper()]

      let appController = AppController(
        appDB: db, providers: providers, instanceConfigMappers: instanceConfigMappers)
      return appController
    } catch {
      fatalError("\(error)")
    }
  }
}
