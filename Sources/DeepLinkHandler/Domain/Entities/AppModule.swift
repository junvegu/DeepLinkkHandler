//
//  File.swift
//  
//
//  Created by Junior Quevedo Gutiérrez  on 2/03/25.
//

import Foundation
public protocol AppModule: AnyObject {
    var urls: [DeepLinkModule] { get set }
}
