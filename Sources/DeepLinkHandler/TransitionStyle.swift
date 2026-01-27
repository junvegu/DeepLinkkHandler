//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 2/03/25.
//

import Foundation
import UIKit

// MARK: NavigationTransitions Enum

/**
 This enum defines all transitions managed by the SDK.
 */
public enum NavigationTransitions: String {
    /// Changes the root of the navigation to the new flow.
    case root

    /// Pushes a flow onto the current navigation stack.
    case push

    /// Presents a flow modally.
    case modal
}

/**
 Enum containing presentation styles used for `NavigationTransitions.modal` transitions.
 For other `NavigationTransitions` values, this property will be ignored.
 */
public enum ModalPresentationStyle: String {
    /// Presents the view controller covering the entire screen, removing the previous controller from the view hierarchy (Default).
    case fullscreen

    /// Presents the view controller covering the entire screen while keeping the previous controller in the view hierarchy.
    case overFullscreen

    case pageSheet
    case formSheet
    case none
    
    /// Returns the corresponding `UIModalPresentationStyle` value for UIKit.
    var value: UIModalPresentationStyle {
        switch self {
        case .fullscreen:
            return .fullScreen
        case .overFullscreen:
            return .overFullScreen
        case .pageSheet:
            return .pageSheet
        case .formSheet:
            return .formSheet
        case .none:
            return .none
        }
    }
}

// MARK: TransitionTypeManager Class

class TransitionTypeManager {
    let urlConvertible: URLConvertible

    init(urlConvertible: URLConvertible) {
        self.urlConvertible = urlConvertible
    }

    /// Determines the navigation transition mode based on the URL parameters, falling back to the default if none is specified.
    public func presentationMode(defaultTransition: NavigationTransitions = .push) -> NavigationTransitions {
        guard let mode = urlConvertible.queryParameters["presentation"],
              let transitionMode = NavigationTransitions(rawValue: mode) else {
            return defaultTransition
        }
        return transitionMode
    }

    /// Determines the modal presentation style based on the URL parameters, defaulting to `.fullscreen` if unspecified.
    public func modalPresentationStyle() -> ModalPresentationStyle {
        guard let presentation = urlConvertible.queryParameters["modalPresentationStyle"],
              let modalStyle = ModalPresentationStyle(rawValue: presentation) else {
            return .fullscreen
        }
        return modalStyle
    }
}
