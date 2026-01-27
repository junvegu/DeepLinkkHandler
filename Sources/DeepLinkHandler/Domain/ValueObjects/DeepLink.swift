//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 4/03/25.
//

import Foundation

@propertyWrapper
public struct DeepLink {
    let path: String
    let tracingKey: String?
    
    public init(_ path: String, tracing: String? = nil) {
        self.path = path
        self.tracingKey = tracing
    }
    
    public var wrappedValue: DeepLinkPath {
        return DeepLinkPath(path: path, tracingKey: tracingKey)
    }
}
