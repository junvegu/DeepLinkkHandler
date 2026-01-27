//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 3/03/25.
//

import Foundation

// MARK: - URLConvertible Protocol
/// A protocol that allows different types to be converted into a valid URL.
public protocol URLConvertible {
    /// Returns the URL representation of the conforming type.
    var urlValue: URL? { get }
    
    /// Returns the string representation of the URL.
    var urlStringValue: String { get }
    
    /// Extracts the query parameters from the URL.
    /// - Note: If the URL has no query string, this will return an empty dictionary.
    var queryParameters: [String: String] { get }
    
    /// Extracts query items from the URL using `URLComponents`.
    var queryItems: [URLQueryItem]? { get }
}

// MARK: - Default Implementations
extension URLConvertible {
    public var queryParameters: [String: String] {
        var parameters = [String: String]()
        self.urlValue?.query?.components(separatedBy: "&").forEach { component in
            guard let separatorIndex = component.firstIndex(of: "=") else { return }
            let key = String(component[..<separatorIndex])
            let value = component[component.index(after: separatorIndex)...]
                .removingPercentEncoding ?? String(component[component.index(after: separatorIndex)...])
            parameters[key] = value
        }
        return parameters
    }

    public var queryItems: [URLQueryItem]? {
        return URLComponents(string: self.urlStringValue)?.queryItems
    }
}
