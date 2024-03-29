//
//  File.swift
//
//
//  Created by KaitoKitaya on 2024/03/10.
//

import Foundation

class Util {
  private init() {}
  static func debugPrint(title: String, printContent: (() -> Void)? = nil) {
    print("\n")
    print("===== START \(title) =====")
    if let printContent {
      printContent()
    }
    print("===== END \(title) =====")
    print("\n")
  }

  static public var emptyUri: URL {
    return URL(string: "")!
  }

}
