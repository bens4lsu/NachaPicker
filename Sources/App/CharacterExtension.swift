//
//  CharacterExtension.swift
//  App
//
//  Created by Ben Schultz on 3/27/20.
//

import Foundation
extension Character: Codable {
    public init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let string = try container.decode(String.self)
        guard string.count == 1 else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Multiple characters found when decoding a Character")
        }
        guard let character = string.first else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Empty String found when decoding a Character")
        }
        self = character
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()
        try container.encode(String(self))
    }
}
