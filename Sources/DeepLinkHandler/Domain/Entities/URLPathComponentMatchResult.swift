//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 4/03/25.
//

import Foundation
// MARK: - Path Component Match Result
enum URLPathComponentMatchResult {
    case matches((key: String, value: Any)?)
    case notMatches
}
