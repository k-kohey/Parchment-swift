//
//  File.swift
//  
//
//  Created by k-kohey on 2022/12/30.
//

import Foundation

struct Field: Codable, Equatable {
    let name: String
    let type: String
    let description: String
    let nullable: Bool
}

public struct EventDefinision: Codable, Equatable {
    let name: String
    let properties: [Field]
    let description: String
    let discussion: String
}
