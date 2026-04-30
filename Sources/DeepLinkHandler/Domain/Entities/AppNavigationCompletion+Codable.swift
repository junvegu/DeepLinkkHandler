//
//  AppNavigationCompletion+Codable.swift
//

import Foundation

// MARK: - Encode

public extension Optional where Wrapped == AppNavigationCompletion {
    func succeed<T: Encodable>(_ value: T) {
        let data = (try? JSONEncoder().encode(value)) ?? Data()
        self?(.success(data))
    }
}

// MARK: - Decode

public extension Data {
    func decode<T: Decodable>(_ type: T.Type) -> T? {
        try? JSONDecoder().decode(type, from: self)
    }
}
