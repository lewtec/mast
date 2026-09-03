import Foundation

struct SetupPackage: Identifiable, Equatable {
    let id = UUID()
    var name: String
    var path: String
    var route: String
}
