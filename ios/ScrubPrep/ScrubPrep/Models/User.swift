import Foundation
import ParseSwift

/// This app's `ParseUser` type — standard ParseSwift boilerplate (every property must be
/// optional so the compiler-synthesized memberwise initializer works, per ParseObject's
/// requirements). Backs both email/password accounts and Sign in with Apple accounts
/// (`authData` holds the `"apple"` entry for the latter; email-only fields stay nil).
struct User: ParseUser {
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    var originalData: Data?

    var username: String?
    var email: String?
    var emailVerified: Bool?
    var password: String?
    var authData: [String: [String: String]?]?
}
