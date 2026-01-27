//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 2/03/25.
//

import Foundation
import UIKit

public protocol ApplicationInteractor: AnyObject {
    /// `TabBarNavigator` allows interaction with the tab navigation of the app.
    var tabBarNavigator: TabBarNavigator? { get }

    /// Retrieves the top view controller from the navigation stack.
    var topViewController: UIViewController? { get }

    /// Retrieves the root view controller of the application.
    var rootViewController: UIViewController? { get }

    /**
     Displays a view controller based on a URL-based navigation structure.

     - Parameters:
        - urlConvertible: The navigation URL used to determine the transition.
        - viewController: The destination view controller to be presented.
     */
    func navigate(to urlConvertible: URLConvertible, viewController: UIViewController)

    /**
     Displays a view controller with a specified transition type.

     - Parameters:
        - urlConvertible: The navigation URL used to determine the transition.
        - defaultTransition: The default transition to apply if not specified in `urlConvertible`.
        - viewController: The destination view controller to be presented.
     */
    func navigate(to urlConvertible: URLConvertible,
                  with defaultTransition: NavigationTransitions,
                  viewController: UIViewController)

    /**
     Displays a view controller with an explicit transition type.

     - Parameters:
        - transition: The navigation transition to apply.
        - viewController: The destination view controller to be presented.
     */
    func navigate(using transition: NavigationTransitions, viewController: UIViewController)

    /// Displays the TabBar navigation interface.
    func showTabBarNavigator()
}

class NavigationHandler: ApplicationInteractor {
    var tabBarNavigator: TabBarNavigator?
    let window: UIWindow
    private let navigationActions: TabBarNavigationActions
    
    init(window: UIWindow,
         navigationActions: TabBarNavigationActions = TabBarNavigationActionsAdapter(),
         tabBarNavigator: TabBarNavigator? = nil) {
        self.window = window
        self.navigationActions = navigationActions
        self.tabBarNavigator = tabBarNavigator
    }

    var rootViewController: UIViewController? {
        window.rootViewController
    }

    var topViewController: UIViewController? {
        return navigationActions.topViewController(base: window.rootViewController)
    }

    func navigate(to urlConvertible: URLConvertible, viewController: UIViewController) {
        navigate(to: urlConvertible,
                 with: .push,
                 viewController: viewController)
    }

    func navigate(to urlConvertible: URLConvertible,
                  with defaultTransition: NavigationTransitions,
                  viewController: UIViewController) {
        let transitionType = TransitionTypeManager(urlConvertible: urlConvertible)
        let transition = transitionType.presentationMode(defaultTransition: defaultTransition)
        let modalPresentationStyle = transitionType.modalPresentationStyle()
        navigate(using: transition, presentationStyle: modalPresentationStyle, viewController: viewController)
    }

    func navigate(using transition: NavigationTransitions, viewController: UIViewController) {
        navigate(using: transition, presentationStyle: .fullscreen, viewController: viewController)
    }

    private func navigate(using transition: NavigationTransitions,
                          presentationStyle: ModalPresentationStyle,
                          viewController: UIViewController) {
        switch transition {
        case .push:
            navigationActions.push(window: window, viewController: viewController)
        case .modal:
            navigationActions.present(window: window, presentationStyle: presentationStyle, viewController: viewController)
        case .root:
            navigationActions.setRoot(window: window, viewController: viewController)
        }
    }

    func showTabBarNavigator() {
        guard let navigationController = tabBarNavigator?.tabBarController as? UINavigationController else { return }
        navigationController.popToRootViewController(animated: false)
        navigate(using: .root, presentationStyle: .fullscreen, viewController: navigationController)
    }
}
