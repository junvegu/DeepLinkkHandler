//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 2/03/25.
//

import Foundation
import UIKit
public protocol TabBarNavigationActions {
    /**
     Returns the top view controller in the current view controller stack.
     */
    func topViewController(base: UIViewController?) -> UIViewController?

    /**
     Pushes a view controller onto the navigation stack.
     */
    func push(window: UIWindow, viewController: UIViewController)

    /**
     Presents a view controller modally. This creates a new navigation controller with the view controller as the root.
     */
    func present(window: UIWindow,
                 presentationStyle: ModalPresentationStyle,
                 viewController: UIViewController)

    /**
     Replaces the current window's root view controller with a new navigation controller.
     */
    func setRoot(window: UIWindow, viewController: UIViewController)
}

public protocol TabBarNavigator {
    /// The main tab bar view controller.
    var tabBarController: UIViewController { get }

    /// The currently selected view controller in the tab bar.
    var selectedViewController: UIViewController? { get }

    /**
     Changes the currently selected tab.

     - Parameters:
        - urlConvertible: The navigation URL associated with the tab item.
     */
    func switchTab(to urlConvertible: URLConvertible)
}

struct TabBarNavigationActionsAdapter: TabBarNavigationActions {
    /**
     Returns the top view controller in the current view controller stack.
     */
    func topViewController(base: UIViewController?) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }

        if let tab = base as? UITabBarController, let selected = tab.selectedViewController {
            return topViewController(base: selected)
        }

        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }

        return base
    }

    /**
     Pushes a view controller onto the navigation stack.
     */
    func push(window: UIWindow, viewController: UIViewController) {
        guard let rootViewController = window.rootViewController else { return }
        let navigationController = rootViewController as? UINavigationController
        let baseViewController = topViewController(base: navigationController)
        baseViewController?.navigationController?.pushViewController(viewController, animated: true)
    }

    /**
     Presents a view controller modally with the specified presentation style.
     */
    func present(window: UIWindow, presentationStyle: ModalPresentationStyle, viewController: UIViewController) {
        let navigationController = viewController as? UINavigationController
            ?? UINavigationController(rootViewController: viewController)
        navigationController.modalPresentationStyle = presentationStyle.value
        guard let rootViewController = window.rootViewController else { return }
        let baseViewController = topViewController(base: rootViewController)
        baseViewController?.present(navigationController, animated: true, completion: nil)
    }

    /**
     Replaces the current window's root view controller with a new navigation controller.
     */
    func setRoot(window: UIWindow, viewController: UIViewController) {
        let navigationController = viewController is UINavigationController ? viewController : UINavigationController(rootViewController: viewController)
        window.rootViewController = navigationController
        window.makeKeyAndVisible()
    }
}
