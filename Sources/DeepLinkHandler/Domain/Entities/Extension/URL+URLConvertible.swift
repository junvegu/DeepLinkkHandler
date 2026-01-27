//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 3/03/25.
//

import Foundation
extension URL: URLConvertible {
    public var urlValue: URL? { self }
    
    public var urlStringValue: String { self.absoluteString }
}
