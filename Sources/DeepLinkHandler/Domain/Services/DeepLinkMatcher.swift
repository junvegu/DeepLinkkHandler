//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 4/03/25.
//

import Foundation

/// A class that matches URLs against a predefined set of patterns and extracts values.
///
/// `DeepLinkMatcher` is responsible for matching incoming URLs with registered patterns,
/// extracting relevant parameters, and returning a structured result.
open class DeepLinkMatcher {
    
    public typealias URLPattern = String
    public typealias URLValueConverter = (_ pathComponents: [String], _ index: Int) -> Any?
    
    /// Default converters for extracting typed values from URL paths.
    static let defaultValueConverters: [String: URLValueConverter] = [
        "string": { $0[$1] },
        "int": { Int($0[$1]) },
        "float": { Float($0[$1]) },
        "uuid": { UUID(uuidString: $0[$1]) },
        "path": { $0[$1..<$0.count].joined(separator: "/") }
    ]
    
    /// Custom value converters, extendable by the user.
    open var valueConverters: [String: URLValueConverter] = DeepLinkMatcher.defaultValueConverters
    
    /// Initializes a new instance of `DeepLinkMatcher`.
    public init() {}
    
    /// Matches a given URL against a set of patterns and extracts values.
    ///
    /// - Parameters:
    ///   - url: The URL to match.
    ///   - candidates: A list of possible URL patterns.
    /// - Returns: A match result if a pattern is found, otherwise `nil`.
    ///
    /// ### Example Usage:
    /// ```swift
    /// let matcher = DeepLinkMatcher()
    /// let matchResult = matcher.match("myapp://profile/123", from: ["myapp://profile/:id"])
    /// print(matchResult?.values) // Output: ["id": 123]
    /// ```
    open func match(_ url: URLConvertible, from candidates: [URLPattern]) -> DeepLinkMatchResult? {
        let normalizedURL = self.normalizeURL(url)
        let urlScheme = normalizedURL.urlValue?.scheme
        let configuredScheme = DeepLinkConfig.scheme
        
        // Extract path components, handling URLs with or without scheme
        let pathComponents: [String]
        if let scheme = urlScheme, scheme == configuredScheme {
            // URL has the configured scheme, extract path normally
            pathComponents = self.extractPathComponents(from: normalizedURL)
        } else if urlScheme == nil {
            // URL doesn't have a scheme, treat as path-only and extract directly
            pathComponents = self.extractPathComponents(from: normalizedURL)
        } else {
            // URL has a different scheme, don't match
            return nil
        }
        
        let queryParams = url.queryParameters
        var results = [DeepLinkMatchResult]()
        
        for candidate in candidates {
            // Check if candidate has the configured scheme
            let candidateScheme = candidate.urlValue?.scheme
            guard candidateScheme == configuredScheme else { continue }
            
            if let result = self.matchPathComponents(pathComponents, with: candidate, parameters: queryParams) {
                results.append(result)
            }
        }
        
        return results.max { self.countPlainPathComponents(in: $0.pattern) < self.countPlainPathComponents(in: $1.pattern) }
    }
    
    private func matchPathComponents(_ pathComponents: [String], with candidate: URLPattern, parameters: [String: String]) -> DeepLinkMatchResult? {
        let normalizedCandidate = self.normalizeURL(candidate).urlStringValue
        let candidatePathComponents = self.extractPathComponents(from: normalizedCandidate)
        let convertedCandidatePathComponents = candidatePathComponents.map(URLPathComponent.init)
        
        guard self.ensureComponentCount(pathComponents, convertedCandidatePathComponents) else { return nil }
        
        var extractedValues: [String: Any] = [:]
        
        for index in 0..<min(pathComponents.count, convertedCandidatePathComponents.count) {
            let result = self.evaluatePathComponent(at: index, from: pathComponents, with: convertedCandidatePathComponents)
            
            switch result {
            case let .matches(placeholderValue):
                if let (key, value) = placeholderValue {
                    extractedValues[key] = value
                }
            case .notMatches:
                return nil
            }
        }
        
        return DeepLinkMatchResult(pattern: candidate, values: extractedValues, parameters: parameters)
    }
    
    private func normalizeURL(_ url: URLConvertible) -> URLConvertible {
        guard url.urlValue != nil else { return url }
        var urlString = url.urlStringValue
        urlString = urlString.components(separatedBy: ["?", "#"]).first ?? urlString
        urlString = urlString.replacingOccurrences(of: "://+", with: "://", options: .regularExpression)
        urlString = urlString.replacingOccurrences(of: "(?<!:)/{2,}", with: "/", options: .regularExpression)
        
        return urlString
    }
    
    private func ensureComponentCount(_ components: [String], _ candidateComponents: [URLPathComponent]) -> Bool {
        return components.count == candidateComponents.count || (candidateComponents.contains { if case .placeholder("path", _) = $0 { return true } else { return false } } && components.count > candidateComponents.count)
    }
    
    private func extractPathComponents(from url: URLConvertible) -> [String] {
        return url.urlStringValue
            .split(separator: "/")
            .filter { !$0.isEmpty }
            .map(String.init)
    }
    
    private func evaluatePathComponent(at index: Int, from pathComponents: [String], with candidateComponents: [URLPathComponent]) -> URLPathComponentMatchResult {
        let pathComponent = pathComponents[index]
        let candidateComponent = candidateComponents[index]
        
        switch candidateComponent {
        case let .plain(value):
            return pathComponent == value ? .matches(nil) : .notMatches
        case let .placeholder(type, key):
            return type.flatMap { valueConverters[$0] }?(pathComponents, index).map { .matches((key, $0)) } ?? .notMatches
        }
    }
    
    private func countPlainPathComponents(in pattern: URLPattern) -> Int {
        return extractPathComponents(from: pattern).filter { $0 != "" }.count
    }
}
