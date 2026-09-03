import Foundation

struct SetupPackage: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var path: String
    var route: String
    var languages: [String]

    init(name: String, path: String, route: String, languages: [String] = []) {
        self.name = name
        self.path = path
        self.route = route
        self.languages = languages
    }
}
