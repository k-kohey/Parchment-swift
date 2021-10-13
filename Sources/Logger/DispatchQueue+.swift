// 
//  File.swift
//  
//
//  Created by k-kohey on 2021/10/13.
//

import Foundation

extension DispatchQueue {
    static let readWrite = DispatchQueue(label: "com.k-kohey.logger.readWrite", qos: .background)
    static let request = DispatchQueue(label: "com.k-kohey.logger.request", qos: .background)
}
