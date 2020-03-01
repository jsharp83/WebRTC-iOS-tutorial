//
//  DebugPrint.swift
//  WebRTCTutorial
//
//  Created by Eric on 2020/03/06.
//  Copyright © 2020 Eric. All rights reserved.
//

import Foundation

public func dLog(_ object: Any, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
  #if DEBUG
    let className = (fileName as NSString).lastPathComponent
    print("[\(className)] \(functionName) [#\(lineNumber)]| \(object)\n")
  #endif
}
