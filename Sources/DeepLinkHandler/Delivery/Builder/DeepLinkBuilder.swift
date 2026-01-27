//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 4/03/25.
//

import Foundation
public class DeepLinkBuilder {
    
    private var deepLinkPath: DeepLinkPath
    private var pathSegments: [String] = []
    private var queryParams: [String: Any] = [:]
    
    /// Inicializa el builder con un `DeepLinkPath` predefinido.
    public init(_ path: DeepLinkPath) {
        self.deepLinkPath = path
    }
    
    /// Añade un segmento de ruta adicional (Ej: "oauth" → "oauth/1231231/")
    @discardableResult
    public func addPathSegment(_ segment: String) -> DeepLinkBuilder {
        pathSegments.append(segment)
        return self
    }
    
    /// Añade un parámetro a la URL del deep link.
    @discardableResult
    public func addParameter(key: String, value: Any) -> DeepLinkBuilder {
        queryParams[key] = value
        return self
    }
    
    /// Construye la URL final usando el scheme configurado
    /// Formato: `{scheme}://{path}/{segment1}/{segment2}?key1=value1&key2=value2`
    /// - Returns: URL completa con el scheme configurado en DeepLinkConfig
    public func build() -> String {
        // Construir el path completo con segmentos adicionales
        var fullPath = deepLinkPath.path
        
        // Agregar segmentos de ruta si existen
        if !pathSegments.isEmpty {
            // Asegurar que el path termine con / si vamos a agregar segmentos
            if !fullPath.hasSuffix("/") {
                fullPath.append("/")
            }
            fullPath.append(pathSegments.joined(separator: "/"))
        }
        
        // Construir URL completa con el scheme configurado
        var urlString = DeepLinkConfig.buildURL(from: fullPath)
        
        // Agregar query parameters si existen
        if !queryParams.isEmpty {
            let queryString = queryParams
                .map { "\($0.key)=\("\($0.value)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
                .joined(separator: "&")
            urlString.append("?\(queryString)")
        }
        
        return urlString
    }
}
