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
        if value.hasPrefix("<") && value.hasSuffix(">") {
            let components = value.trimmingCharacters(in: ["<", ">"]).split(separator: ":")
            self = components.count == 2 ? .placeholder(type: String(components[0]), key: String(components[1])) : .plain(value)
        } else {
            self = .plain(value)
        }
    }
}
