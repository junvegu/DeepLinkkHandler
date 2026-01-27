//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 4/03/25.
//

import Foundation

/// Represents a URL match result, including the pattern that matched and the extracted values.
public struct DeepLinkMatchResult {
    /// The matched URL pattern.
    public let pattern: String
    
    /// Extracted values from the URL placeholders.
    public let values: [String: Any]
    
    public let parameters: [String: String]
}
