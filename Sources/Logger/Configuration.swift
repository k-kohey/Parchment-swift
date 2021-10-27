// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/26.
//

import os

private let l = os.Logger(subsystem: "com.k-kohey.logger", category: "Logger")

public struct Configuration {
    public static var shouldPrintDebugLog = false
}

var console: os.Logger? {
    Configuration.shouldPrintDebugLog ? l : nil
}
