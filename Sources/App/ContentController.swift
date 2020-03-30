//
//  ContentController.swift
//  App
//
//  Created by Ben Schultz on 3/27/20.
//

import Foundation
import Vapor
import Leaf

class ContentController: RouteCollection {
    
    var cache = [SavedInput]()
    
    func boot(router: Router) throws {
        router.get(use: renderHome)
        router.post(use: processFile)
        router.post("updated", use: processRemovals)
    }
    
    func renderHome(_ req: Request) throws -> Future<View> {
        return try req.view().render("input-file")
    }
    
    func processFile(_ req: Request) throws -> Future<View> {
        let optAchFile: String? = try? req.content.syncGet(at: "fileToParse")
        guard let ach = optAchFile else {
            throw Abort(.badRequest, reason: "No ach input received")
        }
        
        let achLines = ach.components(separatedBy: .newlines)
        let nacha = try parseLines(lines: achLines)
        try nacha.validateStructure()
        let saved = SavedInput(nacha)
        cache.append(saved)
        
        let context = PickerContext(uuid: saved.uuid, lines: nacha.context())
        return try req.view().render("pick-payments", context)
    }
    
    func processRemovals(_ req: Request) throws -> Future<Response> {
        let id: String? = try? req.content.syncGet(at: "uuid")
        
        guard let unId = id, let uuid = UUID(unId) else {
            throw Abort (.badRequest, reason: "Could not get id from original input file.")
        }
        
        let nacha = cache.filter({ $0.uuid == uuid }).map({ return $0.nacha })[0]
        for line in nacha.context() {
            let name = "row-" + line.uuid.description
            let sentValue: String? = try? req.content.syncGet(at: name)
            if sentValue != nil {
                nacha.removeDetail(withId: line.uuid)
            }
        }
        
        nacha.updateValues()
        removeCache(for: uuid)
        return try nacha.out().encode(for: req)
       
    }
    
    
    func parseLines(lines: [String]) throws -> NachaAll {
        let nacha = NachaAll()
        for line in lines {
            if line.trimmingCharacters(in: .whitespaces).lengthOfBytes(using: .ascii) > 0 {

                let type = Int(line.prefix(1)) ?? -1
                
                guard type == 1 || type >= 5 else {
                    throw Abort(.badRequest, reason: "Invalid file format on line \(line).  First character must be 1, 5, 6, 7, 8. or 9")
                }
                
                if type == 1 {
                    try nacha.files.append(NachaFile(NachaType1(from: line)))
                }
                else if type == 5 {
                    
                    guard let file = nacha.files.last else {
                        throw Abort(.badRequest, reason: "Line \(line)\nspecifies a type 5 record with no preceding type 1.")
                    }
                    
                    try file.groups.append(NachaGroup(NachaType5(from: line)))
                }
                else if type == 6 {
                    
                    guard let group = nacha.files.last?.groups.last else {
                        throw Abort(.badRequest, reason: "Line \(line)\nspecifies a type 6 record with no preceding type 5.")
                    }
                    
                    try group.details.append(NachaDetails(NachaType6(from: line)))
                }
                else if type == 7 {
                    
                    guard let detail = nacha.files.last?.groups.last?.details.last else {
                        throw Abort(.badRequest, reason: "Line \(line)\nspecifies a type 7 record with no preceding type 6.")
                    }
                    
                    try detail.type7s.append(NachaType7(from: line))
                }
                else if type == 8 {
                    
                    guard let group = nacha.files.last?.groups.last else {
                        throw Abort(.badRequest, reason: "Line \(line)\nspecifies a type 8 record with no preceding type 5.")
                    }
                    
                    try group.type8 = NachaType8(from: line)
                }
                else if type == 9 {
                    
                    guard let file = nacha.files.last else {
                        throw Abort(.badRequest, reason: "Line \(line)\nspecifies a type 8 record with no preceding type 1.")
                    }
                    
                    if line != String(repeating: "9", count: 94) {
                        try file.type9 = NachaType9(from: line)
                    }
                    
                }
            }
        }
        
        return nacha
    }
    
    func removeCache(for id: UUID) {
        cache = cache.filter({ !$0.isOutdated && $0.uuid != id })
    }
}

