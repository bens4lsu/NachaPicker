//
//  NacaFileLines.swift
//  App
//
//  Created by Ben Schultz on 3/23/20.
//

import Foundation
import Vapor

class NachaRecord: FixedLengthField {
        
    init(from string: String, type paramType: Int, validations: [FieldParseValidation]) throws {
        
        super.init("", size: 94)
        
        let typeFromString = Int(string.prefix(1))
        
        guard paramType == typeFromString else {
            throw Abort(.badRequest, reason: "Parse error on \(string).  Call to NACHA type \(paramType) parser, but first character is \(String(describing: typeFromString)).")
        }
        
        guard string.lengthOfBytes(using: .ascii) == 94 else {
            throw Abort(.badRequest, reason: "Parse error on \(text).  String is not equal to 94 characters.")
        }
        
        // test to make sure record is valid (numerics are all numeric, etc.)
        for validation in validations {
            let testStr = String(string[validation.lowerBound...validation.upperBound])
            let testResult = validation.routine(testStr, validation.compValue)
            switch testResult {
            case .error(let reason):
                throw Abort(.badRequest, reason: "Parse error on \(text).\nPosition \(validation.lowerBound + 1) to \(validation.upperBound + 1)\n\(reason)")
            case .success:
                break
            }
        }
        self.text = string
    }  // end init    
    
    required init(from decoder: Decoder) throws {
        var container = try decoder.unkeyedContainer()
        let string = try container.decode(String.self)
        guard string.count == 94 else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "NACHA record must be 94 characters")
        }
        super.init(string, size: 94)
    }
}

class NachaType1: NachaRecord {
    
    init(from string: String) throws {
        var validations = [FieldParseValidation]()
        
        validations.append(FieldParseValidation(lowerBound: 1, upperBound: 2, routine: FieldParseValidation.isConstant, compValue: "01"))
        validations.append(FieldParseValidation(lowerBound: 3, upperBound: 3, routine: FieldParseValidation.isConstant, compValue: " "))
        validations.append(FieldParseValidation(lowerBound: 4, upperBound: 12, routine: FieldParseValidation.isNumeric, compValue: nil))

        try super.init(from: string, type: 1, validations: validations)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class NachaType9: NachaRecord {
    
    init(from string: String) throws {
        let validations = [FieldParseValidation]()
        try super.init(from: string, type: 9, validations: validations)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
}

class NachaType5: NachaRecord {
    
    init(from string: String) throws {
        let validations = [FieldParseValidation]()
        try super.init(from: string, type: 5, validations: validations)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
}

class NachaType8: NachaRecord {
    
    var aeCount: Int? { return val(from: 4, to: 9) }
    var hash: Int? { return val(from: 10, to: 19) }
    var debitAmount: Double? { return val(from: 20, to: 31) }
    var creditAmount: Double? { return val(from: 32, to: 43) }
    
    init(from string: String) throws {
        let validations = [FieldParseValidation]()
        try super.init(from: string, type: 8, validations: validations)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
    
}

class NachaType6: NachaRecord {
    
    var uuid = UUID()
    
    var aba: String? { return val(from: 3, to: 11) }
    var accountNumber: String? { return val(from: 12, to: 28) }
    var amount: Double? { return val(from: 29, to: 38) }
    var idNumber: String? { return val(from: 39, to: 53 ) }
    var name: String? { return val(from: 54, to: 75) }
    var hash: Int? { return val(from: 4, to: 11) }
    var isDebit: Bool {
        let type: String? = val(from: 1, to: 2)
        return type == "27"
    }
    
    init(from string: String) throws {
        let validations = [FieldParseValidation]()
        try super.init(from: string, type: 6, validations: validations)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }

}

class NachaType7: NachaRecord {
    
    var hash: Int? { return val(from: 4, to: 11) }
    
    init(from string: String) throws {
        let validations = [FieldParseValidation]()
        try super.init(from: string, type: 7, validations: validations)
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}

class NachaFilePadding: NachaRecord {
    
    init() throws {
        let line = String(repeating: "9", count: 94)
        try super.init(from: line, type: 9, validations: [FieldParseValidation]())
    }
    
    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
