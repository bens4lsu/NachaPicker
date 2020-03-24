import Routing
import Vapor

/// Register your application's routes here.
///
/// [Learn More →](https://docs.vapor.codes/3.0/getting-started/structure/#routesswift)
public func routes(_ router: Router) throws {
    router.get("hello") { req in
        return "Hello, world!"
    }
    
    func todo() {
        // parse input string into lines
        let x = "sss"
        
        x.components(separatedBy: .newlines)
    }
}
