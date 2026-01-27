//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 3/03/25.
//

import Foundation

/// Configuration for DeepLinkHandler
/// Allows configuring the URL scheme and base URL used for deep links
public struct DeepLinkConfig {
    /// The URL scheme to use for deep links (e.g., "myapp", "app")
    public static var scheme: String = "app"
    
    /// The base URL format (kept for backward compatibility)
    public static var baseURL: String {
        return "\(scheme)://"
    }
    
    /// Configure the deep link scheme
    /// - Parameter scheme: The URL scheme to use (without ://)
    /// - Example: configure(scheme: "myapp") will use "myapp://" as the base URL
    public static func configure(scheme: String) {
        DeepLinkConfig.scheme = scheme
    }
    
    /// Builds a complete URL from a path by prepending the configured scheme
    /// - Parameter path: The path component (e.g., "profile/:id")
    /// - Returns: Complete URL with scheme (e.g., "app://profile/:id")
    public static func buildURL(from path: String) -> String {
        // Remove leading slash if present
        let cleanPath = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return "\(scheme)://\(cleanPath)"
    }
    
    /// Initializes configuration with a custom scheme
    /// - Parameter scheme: The URL scheme to use (without ://)
    public init(scheme: String = "app") {
        DeepLinkConfig.scheme = scheme
    }
}
