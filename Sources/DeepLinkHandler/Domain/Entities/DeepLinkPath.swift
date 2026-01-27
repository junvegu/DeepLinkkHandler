//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 4/03/25.
//

import Foundation
public struct DeepLinkPath {
    let path: String
    let tracingKey: String?
    public init(path: String, tracingKey: String?) {
        self.path = path
        self.tracingKey = tracingKey
    }
}
