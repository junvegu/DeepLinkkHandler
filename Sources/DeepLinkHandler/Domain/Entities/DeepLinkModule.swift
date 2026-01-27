//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 4/03/25.
//

import Foundation

/// Protocolo que los módulos deben implementar

public protocol DeepLinkModule {
    /// La URL base del deeplink
    var url: URLPattern { get }
    
    /// Lista de parámetros requeridos en query params
    var parameters: [String] { get }
    
    /// Tipo de Deeplink (navegación o servicio)
    var type: DeeplinkType { get }
    
    /// Método para manejar el deeplink si pasa la validación
    func handle(
        fullPath: URLConvertible,
        values: [String: Any],
        data: Data?,
        completion: AppNavigationCompletion?
    )
}
