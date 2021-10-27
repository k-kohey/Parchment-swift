// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/26.
//

import os

private let l = os.Logger(subsystem: "com.k-kohey.logger", category: "global")

public struct Configuration {
    static var shouldPrintDebugLog = false
}

var console: os.Logger? {
    Configuration.shouldPrintDebugLog ? l : nil
}
