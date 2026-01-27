//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 3/03/25.
//

import Foundation
extension String: URLConvertible {
    public var urlValue: URL? {
        if let url = URL(string: self) { return url }
        return self.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)
            .flatMap { URL(string: $0) }
    }
    
    public var urlStringValue: String { self }
}
