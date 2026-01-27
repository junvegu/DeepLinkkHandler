//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 3/03/25.
//

import Foundation
// MARK: - URL Path Component
enum URLPathComponent {
    case plain(String)
    case placeholder(type: String?, key: String)
}

extension URLPathComponent {
    init(_ value: String) {
        // Support format: :id or :type:id (e.g., ":id", ":int:id", ":string:name")
        if value.hasPrefix(":") {
            let components = String(value.dropFirst()).split(separator: ":", maxSplits: 1)
            if components.count == 2 {
                // Format: :type:key (e.g., ":int:id")
                self = .placeholder(type: String(components[0]), key: String(components[1]))
            } else if components.count == 1 {
                // Format: :key (e.g., ":id")
                self = .placeholder(type: nil, key: String(components[0]))
            } else {
                self = .plain(value)
            }
        } else if value.hasPrefix("<") && value.hasSuffix(">") {
            // Support legacy format: <type:key> for backward compatibility
            let components = value.trimmingCharacters(in: ["<", ">"]).split(separator: ":")
            self = components.count == 2 ? .placeholder(type: String(components[0]), key: String(components[1])) : .plain(value)
        } else {
            self = .plain(value)
        }
    }
}
