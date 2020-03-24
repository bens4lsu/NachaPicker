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
        
        guard text.lengthOfBytes(using: .ascii) == 94 else {
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
}

class NachaType1: NachaRecord {
    
    init(from string: String) throws {
        var validations = [FieldParseValidation]()
        
        validations.append(FieldParseValidation(lowerBound: 1, upperBound: 2, routine: FieldParseValidation.isConstant, compValue: "01"))
        validations.append(FieldParseValidation(lowerBound: 3, upperBound: 3, routine: FieldParseValidation.isConstant, compValue: " "))
        validations.append(FieldParseValidation(lowerBound: 4, upperBound: 12, routine: FieldParseValidation.isNumeric, compValue: nil))

        try super.init(from: string, type: 1, validations: validations)
    }
}

class NachaType9: NachaRecord {
    
    init(from string: String) throws {
        let validations = [FieldParseValidation]()
        try super.init(from: string, type: 9, validations: validations)
    }
}

class NachaType5: NachaRecord {
    
    init(from string: String) throws {
        let validations = [FieldParseValidation]()
        try super.init(from: string, type: 5, validations: validations)
    }
}

class NachaType8: NachaRecord {
    
    init(from string: String) throws {
        let validations = [FieldParseValidation]()
        try super.init(from: string, type: 8, validations: validations)
    }
}

class NachaType6: NachaRecord {
    
    init(from string: String) throws {
        let validations = [FieldParseValidation]()
        try super.init(from: string, type: 6, validations: validations)
    }
}

class NachaType7: NachaRecord {
    
    var idxLinkedType6: Int?
    
    init(from string: String) throws {
        let validations = [FieldParseValidation]()
        try super.init(from: string, type: 7, validations: validations)
    }
}

class NachaFilePadding: NachaRecord {
    
    init() throws {
        let line = String(repeating: "9", count: 94)
        try super.init(from: line, type: 9, validations: [FieldParseValidation]())
    }
}
