// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/26.
//

public struct Configuration {
    public static var debugMode = false
}

import os

enum ConsoleLoggerCategory: String {
    case logger
}

private var loggers: [ConsoleLoggerCategory: os.Logger] = [
    .logger: os.Logger(subsystem: "com.k-kohey.logger", category: ConsoleLoggerCategory.logger.rawValue)
]

func console(_ category: ConsoleLoggerCategory = .logger) -> os.Logger? {
    if let logger = loggers[category], Configuration.debugMode {
        return logger
    } else  {
        return nil
    }
}

func assertionIfDebugMode(_ msg: String) {
    assert(Configuration.debugMode, msg)
}
