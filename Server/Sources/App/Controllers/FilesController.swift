//
//  FileController.swift
//  App
//
//  Created by Vũ Quý Đạt  on 26/12/2020.
//

import Vapor

public enum FileController {
  private static let fileManager = FileManager.default
  private static let workingDir = DirectoryConfig.detect().workDir + "Public/store/"
  
  // MARK: - Synchronous Methods
  
  public static func getTemplateNames() -> [String]? {
    do {
      return try fileManager.contentsOfDirectory(atPath: workingDir)
    } catch {
      return nil
    }
  }
  
  public static func readFileSync(_ filename: String) -> Data? {
    return fileManager.contents(atPath: workingDir + filename)
  }
  
  @discardableResult public static func writeFileSync(named filename: String, with data: Data, overwrite : Bool = true) -> Bool {
    guard overwrite || !fileExists(filename) else { return false }
    return fileManager.createFile(
      atPath: workingDir + filename, contents: data)
  }
  
  // MARK: - Asynchronous Methods
  
  public static func readFileAsync(_ filename: String, on req: Request ) throws -> Future<Data> {
    try req.fileio().read(file: workingDir + filename)
  }
  
  public static func writeFileAsync(named filename: String,
                                    with data: Data,
                                    on req: Request,
                                    queue: DispatchQueue,
                                    overwrite : Bool = true) throws -> Future<Bool> {
    guard overwrite || !fileExists(filename) else {
      return req.future(false)
    }

    let promise = req.eventLoop.newPromise(of: Bool.self)

    queue.async {
      let result = fileManager.createFile(
        atPath: workingDir + filename, contents: data)
      promise.succeed(result: result)
    }

    return promise.futureResult
  }
}

// MARK: - Private Methods

extension FileController {
  private static func fileExists(_ filename: String) -> Bool {
    guard let directoryContents = getTemplateNames() else { return false }
    return directoryContents.contains(filename)
  }
}
