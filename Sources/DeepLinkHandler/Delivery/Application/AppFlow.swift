//
//  File.swift
//
//
//  Created by Junior Quevedo Gutiérrez  on 4/03/25.
//

import Foundation
import UIKit

public protocol AppFlowRouter {
    /// Opens a route with all possible parameters
    func open(url: String,
              data: Data?,
              context: Context?,
              observer: Observer?,
              callback: AppNavigationCompletion?)
    
    /// Overload for opening a route with a `DeepLinkPath`
    func open(url: DeepLinkPath,
              data: Data?,
              context: Context?,
              observer: Observer?,
              callback: AppNavigationCompletion?)
    
    // MARK: - Async/Await Support
    /// Opens a route asynchronously and returns navigation result.
    @available(iOS 13.0, *)
    func open(url: String,
              data: Data?,
              context: Context?,
              observer: Observer?) async throws -> Data
    
    /// Overload for DeepLinkPath with async/await
    @available(iOS 13.0, *)
    func open(url: DeepLinkPath,
              data: Data?,
              context: Context?,
              observer: Observer?) async throws -> Data
    
    func subscribe(factory: @escaping () -> AppModule)

}

// MARK: - Default Implementations
public extension AppFlowRouter {
    /// Simplified call without observer & context
    func open(url: String, data: Data?, callback: AppNavigationCompletion?) {
        open(url: url, data: data, context: nil, observer: nil, callback: callback)
    }
    
    /// Simplified call for `DeepLinkPath` without observer & context
    func open(url: DeepLinkPath, data: Data?, callback: AppNavigationCompletion?) {
        open(url: url, data: data, context: nil, observer: nil, callback: callback)
    }
    
    /// Simplified call for `String` without `data`, observer & context
    func open(url: String, callback: AppNavigationCompletion?) {
        open(url: url, data: nil, context: nil, observer: nil, callback: callback)
    }
    
    /// Simplified call for `DeepLinkPath` without `data`, observer & context
    func open(url: DeepLinkPath, callback: AppNavigationCompletion?) {
        open(url: url, data: nil, context: nil, observer: nil, callback: callback)
    }
    
    // MARK: - Async Overloads
    /// Async call without observer & context
    @available(iOS 13.0, *)
    func open(url: String, data: Data?) async throws -> Data {
        try await open(url: url, data: data, context: nil, observer: nil)
    }
    
    /// Async call without observer, context & data
    @available(iOS 13.0, *)
    func open(url: String) async throws -> Data  {
        try await open(url: url, data: nil, context: nil, observer: nil)
    }
    
    /// Async call without observer & context for DeepLinkPath
    @available(iOS 13.0, *)
    func open(url: DeepLinkPath, data: Data?) async throws -> Data  {
        try await open(url: url, data: data, context: nil, observer: nil)
    }
    
    /// Async call without observer, context & data for DeepLinkPath
    @available(iOS 13.0, *)
    func open(url: DeepLinkPath) async throws -> Data  {
        try await open(url: url, data: nil, context: nil, observer: nil)
    }
}




public struct AppFlow {
    
    /// Setup navigation and configure deep link scheme
    /// - Parameters:
    ///   - window: The main window of the application
    ///   - scheme: The URL scheme to use for deep links (e.g., "myapp", "app"). Defaults to "app"
    /// - Note: This should be called once during app initialization, typically in AppDelegate or SceneDelegate
    public static func setupNavigation(window: UIWindow, scheme: String = "app") {
        // Configure the deep link scheme
        DeepLinkConfig.configure(scheme: scheme)
        
        let navigationController = UINavigationController()

        // Asignar el UINavigationController a la ventana
        window.rootViewController = navigationController
        let navigation = NavigationHandler(window: window)
        NavigationService.shared.handler = navigation
    }
    
    public static var router: AppFlowRouter {
        DeepLinkHandler.shared
    }
    
    public static var navigation: NavigationService {
        NavigationService.shared
    }
}


public struct NavigationService {
    
    static var shared: NavigationService = NavigationService()
    
    public var handler: ApplicationInteractor? = nil
    
    public func open() {
    }
    
    public func navigate(using transition: NavigationTransitions, viewController: UIViewController) {
        DispatchQueue.main.async {
            handler?.navigate(using: transition, viewController: viewController)
        }
    }
    
    public func navigate(to urlConvertible: URLConvertible,
                  with defaultTransition: NavigationTransitions,
                  viewController: UIViewController) {
        DispatchQueue.main.async {
            handler?.navigate(to: urlConvertible, with: defaultTransition, viewController: viewController)
        }
        
    }
}

public struct Context {
    /// The view value is a UIView that will be used as a container of the implementation.
    public let view: UIView?
    
    /// The parentViewController is used to add a viewController like a childviewcontroller
    public let parentViewController: UIViewController?
    
    /**
     Initialize the FAContext
     
     - Parameters:
     - view: The view value is an UIView that will be used as a container of the implementation
     - parentViewController: The value is a UIViewController that helps to add other viewController us a child view controller
     */
    public init(view: UIView? = nil,
                parentViewController: UIViewController? = nil) {
        self.view = view
        self.parentViewController = parentViewController
    }
}


import Foundation
public typealias Observer = ((Observable<[String: String]>) -> Void)?
public typealias AppNavigationCompletion = (Result<Data, Error>) -> Void

/// A modern observable class that allows multiple observers to react to value changes.
public class Observable<T> {
    /// List of observers that listen for value changes.
    private var observers: [(T?, T?) -> Void] = []
    
    /// The observed value that triggers updates when changed.
    public var value: T? {
        didSet {
            observers.forEach { $0(oldValue, value) }
        }
    }
    
    /// Initializes the observable with an optional initial value.
    public init(_ value: T? = nil) {
        self.value = value
    }
    
    /// Adds a new observer to listen for changes.
    /// - Parameter observer: A closure that receives the old and new values.
    public func bind(_ observer: @escaping (T?, T?) -> Void) {
        observers.append(observer)
        observer(nil, value) // Notify immediately with the initial value
    }
    
    /// Removes all observers to prevent memory leaks.
    public func removeObservers() {
        observers.removeAll()
    }
}
