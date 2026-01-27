// The Swift Programming Language
// https://docs.swift.org/swift-book


import Foundation

private var handlerFactories = [URLPattern: URLOpenHandlerFactory]()

/// A singleton class responsible for handling deep link registration and processing.
///
/// This class provides a mechanism to register deep link handlers and process incoming deep links.
/// It uses a lazy-loaded registry to instantiate `DeepLinkModule` handlers dynamically only when needed.
public final class DeepLinkHandler {
    
    /// Shared singleton instance of `DeepLinkHandler`.
    public static let shared = DeepLinkHandler()
    
    /// A registry mapping deep link URLs to their respective factory methods for creating `DeepLinkModule` instances.
    private var registry: [String: () -> DeepLinkModule] = [:]
    
    /// URL matcher responsible for resolving deep link patterns.
    private let matcher = DeepLinkMatcher()
    
    /// Configuration settings for deep link handling.
    public var config = DeepLinkConfig()
    
    /// Private initializer to enforce singleton usage.
    private init() {}
    
    // MARK: - Helper Methods
    
    /// Builds a complete URL from a path or URL string.
    /// If the input already contains a scheme (contains "://"), returns it as-is.
    /// Otherwise, builds a complete URL using the configured scheme.
    ///
    /// - Parameter urlOrPath: A URL string or path (with or without scheme)
    /// - Returns: Complete URL with scheme
    private func buildCompleteURL(from urlOrPath: String) -> String {
        return urlOrPath.contains("://") 
            ? urlOrPath 
            : DeepLinkConfig.buildURL(from: urlOrPath)
    }
    
    // MARK: - Module Registration
    
    /// Registers a module containing deep link handlers.
    ///
    /// - Parameter factory: A factory function returning an instance of `AppModule`.
    /// - Note: This method extracts all deep link handlers from the module and registers them lazily.
    ///   The URL paths from modules are automatically prefixed with the configured scheme.
    ///
    /// ### Example Usage:
    /// ```swift
    /// DeepLinkHandler.shared.registerModule {
    ///     MyModule()
    /// }
    /// ```
    public func registerModule(factory: @escaping () -> AppModule) {
        let moduleInstance = factory()
        
        for deepLink in moduleInstance.urls {
            // Build complete URL with configured scheme
            let completeURL = DeepLinkConfig.buildURL(from: deepLink.url)
            registry[completeURL] = { deepLink }
        }
    }
    
    // MARK: - Deep Link Opening Methods
    
    /// Opens a deep link using a `DeepLinkPath`.
    ///
    /// - Parameters:
    ///   - deepLink: The `DeepLinkPath` instance representing the deep link.
    ///   - completion: Completion handler returning a `Result<Data, Error>`.
    ///
    /// ### Example Usage:
    /// ```swift
    /// DeepLinkHandler.shared.open(DeepLinkPath(path: "myapp://profile")) { result in
    ///     switch result {
    ///     case .success(let data):
    ///         print("Success: \(data)")
    ///     case .failure(let error):
    ///         print("Error: \(error.localizedDescription)")
    ///     }
    /// }
    /// ```
    public func open(
        _ deepLink: DeepLinkPath,
        completion: AppNavigationCompletion?
    ) {
        let url = buildCompleteURL(from: deepLink.path)
        open(url: url, data: nil, completion: completion)
    }
    
    /// Opens a deep link using a URL string.
    ///
    /// - Parameters:
    ///   - url: The deep link URL string.
    ///   - completion: Completion handler returning a `Result<Data, Error>`.
    ///
    /// ### Example Usage:
    /// ```swift
    /// DeepLinkHandler.shared.open(url: "myapp://settings") { result in
    ///     print(result)
    /// }
    /// ```
    public func open(
        url: String,
        completion: AppNavigationCompletion?
    ) {
        let completeURL = buildCompleteURL(from: url)
        open(url: completeURL, data: nil, completion: completion)
    }
    
    /// Opens a deep link using a URL string and optional payload data.
    ///
    /// - Parameters:
    ///   - url: The deep link URL string.
    ///   - data: Optional `Data` payload to be passed to the handler.
    ///   - completion: Completion handler returning a `Result<Data, Error>`.
    ///
    /// - Note: If no matching handler is found, an appropriate `DeepLinkError` is returned.
    ///
    /// ### Example Usage:
    /// ```swift
    /// DeepLinkHandler.shared.open(url: "myapp://checkout", data: myData) { result in
    ///     if case .failure(let error) = result {
    ///         print("Failed: \(error.localizedDescription)")
    ///     }
    /// }
    /// ```
    public func open(
        url: String,
        data: Data?,
        completion: AppNavigationCompletion?
    ) {
        let completeURL = buildCompleteURL(from: url)
        
        // Attempt to find a matching route using DeepLinkMatcher
        guard let matchResult = matcher.match(completeURL, from: Array(registry.keys)) else {
            completion?(.failure(DeepLinkError.handlerNotFound(url: completeURL)))
            return
        }
        
        // Retrieve the corresponding deep link handler factory
        guard let factory = registry[matchResult.pattern] else {
            completion?(.failure(DeepLinkError.unmatchedPattern(url: url)))
            return
        }
        
        let handler = factory()
        
        // Validate required parameters
        let missingParams = handler.parameters.filter { matchResult.parameters[$0] == nil }
        
        guard missingParams.isEmpty else {
            completion?(.failure(DeepLinkError.missingParameters(params: missingParams)))
            return
        }
        
        let convert: URLConvertible = completeURL
        
        // Call the handler with resolved parameters
        handler.handle(fullPath: convert, values: matchResult.values, data: data, completion: completion)
    }
}

extension DeepLinkHandler: AppFlowRouter {
    @available(iOS 13.0, *)
    public func open(url: DeepLinkPath, data: Data?, context: Context?, observer: Observer?) async throws -> Data {
        try await withUnsafeThrowingContinuation { continuation in
            let completeURL = buildCompleteURL(from: url.path)
            open(url: completeURL, data: data) { result in
                  continuation.resume(with: result)
              }
          }
    }
    
    @available(iOS 13.0, *)
    public func open(url: String, data: Data?, context: Context?, observer: Observer?) async throws -> Data {
        try await withUnsafeThrowingContinuation { continuation in
            let completeURL = buildCompleteURL(from: url)
            open(url: completeURL, data: data) { result in
                  continuation.resume(with: result)
              }
          }
    }
    
   
    
   
    
    public func open(url: DeepLinkPath, data: Data?, context: Context?, observer: Observer?, callback: AppNavigationCompletion?) {
        let completeURL = buildCompleteURL(from: url.path)
        open(url: completeURL, data: data, completion: callback)
    }
    
    public func subscribe(factory: @escaping () -> any AppModule) {
        let moduleInstance = factory()
        for deepLink in moduleInstance.urls {
            // Build complete URL with configured scheme
            let completeURL = DeepLinkConfig.buildURL(from: deepLink.url)
            registry[completeURL] = { deepLink }
        }
    }
    
    public func open(
        url: String,
        data: Data?,
        context: Context?,
        observer: Observer?,
        callback: AppNavigationCompletion?
    ) {
        let completeURL = buildCompleteURL(from: url)
        
        // Attempt to find a matching route using DeepLinkMatcher
        guard let matchResult = matcher.match(completeURL, from: Array(registry.keys)) else {
            callback?(.failure(DeepLinkError.handlerNotFound(url: completeURL)))
            return
        }
        
        // Retrieve the corresponding deep link handler factory
        guard let factory = registry[matchResult.pattern] else {
            callback?(.failure(DeepLinkError.unmatchedPattern(url: url)))
            return
        }
        
        let handler = factory()
        
        // Validate required parameters
        let missingParams = handler.parameters.filter { matchResult.parameters[$0] == nil }
        
        guard missingParams.isEmpty else {
            callback?(.failure(DeepLinkError.missingParameters(params: missingParams)))
            return
        }
        
        let convert: URLConvertible = completeURL
        
        // Call the handler with resolved parameters
        handler.handle(fullPath: convert, values: matchResult.values, data: data, completion: callback)
    }
    
    
}

// MARK: - Deep Link Error Handling

/// Enum representing possible errors encountered during deep link handling.
public enum DeepLinkError: Error {
    
    /// No registered handler was found for the given deep link URL.
    case handlerNotFound(url: String)
    
    /// A matching pattern was found, but no handler was associated with it.
    case unmatchedPattern(url: String)
    
    /// Required parameters for the deep link were missing.
    case missingParameters(params: [String])
}

extension DeepLinkError: LocalizedError {
    
    /// Provides a human-readable description of the error.
    public var errorDescription: String? {
        switch self {
        case .handlerNotFound(let url):
            return "No handler was found for the URL: \(url)"
        case .unmatchedPattern(let url):
            return "A matching pattern was found, but no handler is associated with: \(url)"
        case .missingParameters(let params):
            return "Missing required parameters: \(params.joined(separator: ", "))"
        }
    }
}
