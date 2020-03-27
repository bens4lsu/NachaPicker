import Routing
import Vapor
import Leaf

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    
    func parseLines(lines: [String]) throws -> NachaAll {
        let nacha = NachaAll()
        for line in lines {
            
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
        
        return nacha
    }
    
    
    router.get { req -> Future<View> in
        return try req.view().render("input-file")
    }
    
    router.post { req -> Future<Response> in
        let optAchFile: String? = try? req.content.syncGet(at: "fileToParse")
        guard let ach = optAchFile else {
            throw Abort(.badRequest, reason: "No ach input received")
        }
        
        let achLines = ach.components(separatedBy: .newlines)
        let nacha = try parseLines(lines: achLines)
        
        return try nacha.out().encode(for: req)
    }
}
