import Foundation
import ParseSwift

/// This app's `ParseUser` type — standard ParseSwift boilerplate (every property must be
/// optional so the compiler-synthesized memberwise initializer works, per ParseObject's
/// requirements). Backs both email/password accounts and Sign in with Apple accounts
/// (`authData` holds the `"apple"` entry for the latter; email-only fields stay nil).
/// `nonisolated`: see ORPrep's note — every ParseUser operation (login, signup, save,
/// logout...) runs through ParseSwift's async command execution on its own background
/// executor, which can't use a MainActor-isolated ParseUser conformance under strict
/// concurrency checking.
nonisolated struct User: ParseUser {
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

    /// Whether this account has ever had a case saved for free — set server-side (see
    /// backend/cloud/scrubPrep/subscriptions.js's `markComplimentaryCaseUsed`, called from
    /// `saveCase`), read-only from the client SDK (a `beforeSave` guard on `_User` rejects
    /// any non-Master-Key write touching it). `nil` decodes the same as `false` — a value
    /// this app treats identically (see HomeViewModel.refreshComplimentaryCaseStatus).
    var hasUsedComplimentaryCase: Bool?
}
