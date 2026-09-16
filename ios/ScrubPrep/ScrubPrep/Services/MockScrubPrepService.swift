import Foundation

/// Bundled mock data so the UI can be built and tested without hitting the backend
/// (spec §22). Conforms to the exact same Codable models the real service uses.
final class MockScrubPrepService: ScrubPrepServicing {
    private struct MockPimpSession {
        let difficulty: PimpDifficulty
        var turnIndex: Int
    }

    private var sessions: [String: MockPimpSession] = [:]

    private static let mockQuestions = [
        "What structures define the boundaries of the operative field here?",
        "What's the most important structure to protect during this step?",
        "What would make you convert to an open approach?",
        "What's the most common complication of this operation?",
        "How would you manage unexpected bleeding at this step?",
        "Why is this operation indicated for this patient?",
    ]

    func generatePrep(caseDescription: String) async throws -> ORPrep {
        try await Task.sleep(nanoseconds: 700_000_000)
        return MockScrubPrepService.prep(for: caseDescription)
    }

    func startPimpSession(caseDescription: String, prep: ORPrep, difficulty: PimpDifficulty) async throws -> PimpSessionStart {
        try await Task.sleep(nanoseconds: 400_000_000)
        let sessionId = UUID().uuidString
        sessions[sessionId] = MockPimpSession(difficulty: difficulty, turnIndex: 0)
        let total = MockScrubPrepService.questionTarget(for: difficulty)
        return PimpSessionStart(
            sessionId: sessionId,
            question: MockScrubPrepService.mockQuestions[0],
            progress: PimpProgress(index: 0, total: total),
            done: false
        )
    }

    func answerPimpQuestion(sessionId: String, answer: String) async throws -> PimpAnswerResult {
        try await Task.sleep(nanoseconds: 500_000_000)
        guard var session = sessions[sessionId] else {
            throw ScrubPrepError.invalidResponse
        }
        session.turnIndex += 1
        let total = MockScrubPrepService.questionTarget(for: session.difficulty)
        let isFinal = session.turnIndex >= total
        sessions[sessionId] = session

        let feedback = "Good — you're on the right track. Here's a quick refinement."
        let teachingPoint = "Remember to name the specific structures at risk, not just the general area."

        if isFinal {
            return PimpAnswerResult(
                sessionId: sessionId,
                assessment: .partiallyCorrect,
                feedback: feedback,
                teachingPoint: teachingPoint,
                nextQuestion: nil,
                done: true,
                progress: PimpProgress(index: total, total: total),
                summary: PimpSummary(
                    strong: ["Indications for surgery", "Basic operative sequence"],
                    review: ["Arterial anatomy", "Complication management"],
                    twoMinuteReview: [
                        "Review the key anatomic landmarks before you scrub in.",
                        "Know the most feared complication and how it's recognized.",
                    ]
                )
            )
        } else {
            let nextQuestion = MockScrubPrepService.mockQuestions[session.turnIndex % MockScrubPrepService.mockQuestions.count]
            return PimpAnswerResult(
                sessionId: sessionId,
                assessment: .partiallyCorrect,
                feedback: feedback,
                teachingPoint: teachingPoint,
                nextQuestion: nextQuestion,
                done: false,
                progress: PimpProgress(index: session.turnIndex, total: total),
                summary: nil
            )
        }
    }

    func generateRapidFire(caseDescription: String, prep: ORPrep, previousQuestions: [String]) async throws -> RapidFireResult {
        try await Task.sleep(nanoseconds: 400_000_000)
        let genericPairs = MockScrubPrepService.mockQuestions.map { QAPair(question: $0, answer: "See your OR Prep review.") }
        let pool = prep.likelyQuestions + genericPairs

        let excluded = Set(previousQuestions)
        let fresh = pool.filter { !excluded.contains($0.question) }
        // Several "Go Again" rounds in a row can exhaust the small mock pool — fall back to
        // reusing it rather than return fewer than 5. The real backend's anti-repeat prompt
        // instruction (not this mock) is what actually matters in production.
        let source = fresh.count >= 5 ? fresh : pool
        return RapidFireResult(questions: Array(source.prefix(5)))
    }

    // Mirrors the seed data in backend/scripts/seed-specialties.js / seed-case-types.js so
    // mock mode looks the same as talking to the real catalog.
    private static let mockSpecialties: [Specialty] = [
        Specialty(id: "mock_general_surgery", name: "General Surgery", exampleCaseDescription: "Lap chole for acute cholecystitis"),
        Specialty(id: "mock_cardiac_surgery", name: "Cardiac Surgery", exampleCaseDescription: "CABG \u{00D7}3 for multivessel CAD"),
        Specialty(id: "mock_thoracic_surgery", name: "Thoracic Surgery", exampleCaseDescription: "VATS right upper lobectomy for lung cancer"),
        Specialty(id: "mock_ent", name: "ENT", exampleCaseDescription: "Tonsillectomy for recurrent tonsillitis"),
        Specialty(id: "mock_urology", name: "Urology", exampleCaseDescription: "TURP for BPH with urinary retention"),
        Specialty(id: "mock_orthopedics", name: "Orthopedics", exampleCaseDescription: "Total knee arthroplasty for end-stage osteoarthritis"),
        Specialty(id: "mock_vascular_surgery", name: "Vascular Surgery", exampleCaseDescription: "CEA for symptomatic carotid stenosis"),
    ]

    private static let mockFeaturedCaseTypeNames: Set<String> = ["Lap Chole", "Appendectomy", "Inguinal Hernia", "Colectomy"]

    private static let mockCaseTypeNamesBySpecialtyIndex: [(specialtyIndex: Int, names: [String])] = [
        (0, [
            "Lap Chole", "Appendectomy", "Inguinal Hernia", "Colectomy", "Umbilical Hernia Repair",
            "Ventral Hernia Repair", "Small Bowel Resection", "Whipple Procedure", "Splenectomy",
            "Nissen Fundoplication", "Thyroidectomy", "Roux-en-Y Gastric Bypass", "Sleeve Gastrectomy",
            "Exploratory Laparotomy",
        ]),
        (1, [
            "CABG", "Aortic Valve Replacement", "Mitral Valve Repair", "Mitral Valve Replacement", "TAVR",
            "Ascending Aortic Aneurysm Repair", "Maze Procedure", "LVAD Placement", "Pericardiectomy",
        ]),
        (2, [
            "Lobectomy", "Pneumonectomy", "Wedge Resection", "VATS Wedge Resection", "Esophagectomy",
            "Mediastinoscopy", "Decortication", "Thymectomy", "Tracheostomy",
        ]),
        (3, [
            "Tonsillectomy", "Septoplasty", "Adenoidectomy", "Myringotomy with Tube Placement", "Tympanoplasty",
            "Mastoidectomy", "Functional Endoscopic Sinus Surgery", "Parotidectomy", "Neck Dissection",
            "Laryngectomy", "Uvulopalatopharyngoplasty",
        ]),
        (4, [
            "TURP", "Nephrectomy", "Radical Prostatectomy", "Cystectomy", "Ureteroscopy with Laser Lithotripsy",
            "Percutaneous Nephrolithotomy", "Circumcision", "Vasectomy", "Orchiectomy", "Pyeloplasty",
            "Transurethral Resection of Bladder Tumor",
        ]),
        (5, [
            "Total Knee Arthroplasty", "ACL Reconstruction", "Total Hip Arthroplasty", "Rotator Cuff Repair",
            "Hip Fracture ORIF", "Ankle Fracture ORIF", "Lumbar Spinal Fusion", "Carpal Tunnel Release",
            "Meniscus Repair", "Shoulder Arthroplasty", "Distal Radius Fracture ORIF", "Laminectomy",
        ]),
        (6, [
            "CEA", "AAA Repair", "EVAR", "Fem-Pop Bypass", "Lower Extremity Amputation",
            "AV Fistula Creation", "Thrombectomy", "Varicose Vein Ablation", "Carotid Artery Stenting",
            "Peripheral Angioplasty",
        ]),
    ]

    // Mirrors backend/scripts/seed-case-types.js's fullName values. Falls back to `name`
    // itself (via the dictionary lookup below) for procedures with no common abbreviation.
    private static let mockFullNamesByName: [String: String] = [
        "Lap Chole": "Laparoscopic Cholecystectomy",
        "Inguinal Hernia": "Inguinal Hernia Repair",
        "Whipple Procedure": "Pancreaticoduodenectomy (Whipple Procedure)",
        "CABG": "Coronary Artery Bypass Grafting",
        "TAVR": "Transcatheter Aortic Valve Replacement",
        "Maze Procedure": "Maze Procedure for Atrial Fibrillation",
        "LVAD Placement": "Left Ventricular Assist Device (LVAD) Placement",
        "Lobectomy": "Pulmonary Lobectomy",
        "Wedge Resection": "Pulmonary Wedge Resection",
        "VATS Wedge Resection": "Video-Assisted Thoracoscopic (VATS) Wedge Resection",
        "Decortication": "Pulmonary Decortication",
        "Myringotomy with Tube Placement": "Myringotomy with Tympanostomy Tube Placement",
        "Functional Endoscopic Sinus Surgery": "Functional Endoscopic Sinus Surgery (FESS)",
        "Uvulopalatopharyngoplasty": "Uvulopalatopharyngoplasty (UPPP)",
        "TURP": "Transurethral Resection of the Prostate",
        "Percutaneous Nephrolithotomy": "Percutaneous Nephrolithotomy (PCNL)",
        "Transurethral Resection of Bladder Tumor": "Transurethral Resection of Bladder Tumor (TURBT)",
        "Total Knee Arthroplasty": "Total Knee Arthroplasty (Total Knee Replacement)",
        "ACL Reconstruction": "Anterior Cruciate Ligament (ACL) Reconstruction",
        "Total Hip Arthroplasty": "Total Hip Arthroplasty (Total Hip Replacement)",
        "Hip Fracture ORIF": "Open Reduction and Internal Fixation (ORIF) of Hip Fracture",
        "Ankle Fracture ORIF": "Open Reduction and Internal Fixation (ORIF) of Ankle Fracture",
        "Shoulder Arthroplasty": "Shoulder Arthroplasty (Shoulder Replacement)",
        "Distal Radius Fracture ORIF": "Open Reduction and Internal Fixation (ORIF) of Distal Radius Fracture",
        "CEA": "Carotid Endarterectomy",
        "AAA Repair": "Open Abdominal Aortic Aneurysm Repair",
        "EVAR": "Endovascular Aneurysm Repair",
        "Fem-Pop Bypass": "Femoral-Popliteal Bypass",
        "Lower Extremity Amputation": "Lower Extremity Amputation (Above- or Below-Knee)",
        "AV Fistula Creation": "Arteriovenous (AV) Fistula Creation for Dialysis Access",
        "Thrombectomy": "Thrombectomy for Acute Limb Ischemia",
        "Carotid Artery Stenting": "Carotid Artery Stenting (CAS)",
        "Peripheral Angioplasty": "Peripheral Angioplasty and Stenting",
    ]

    private static let mockCaseTypes: [CaseType] = mockCaseTypeNamesBySpecialtyIndex.flatMap { entry in
        entry.names.map { name in
            CaseType(
                name: name,
                fullName: mockFullNamesByName[name] ?? name,
                specialty: mockSpecialties[entry.specialtyIndex],
                featured: mockFeaturedCaseTypeNames.contains(name)
            )
        }
    }

    func listCaseTypes() async throws -> [CaseType] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return MockScrubPrepService.mockCaseTypes
    }

    func listSpecialties() async throws -> [Specialty] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return MockScrubPrepService.mockSpecialties
    }

    // MARK: - Cases / Pimp Me sessions (in-memory only, not persisted across launches —
    // the real backend is what actually persists this data; this just lets previews/dev
    // exercise the same flows without hitting the network).

    private var mockCases: [ScrubCase] = []
    private var mockPimpMeSessions: [PimpMeSession] = []

    func listCases() async throws -> [ScrubCase] {
        try await Task.sleep(nanoseconds: 200_000_000)
        return mockCases.sorted { $0.updatedAt > $1.updatedAt }
    }

    func saveCase(caseDescription: String, prep: ORPrep) async throws -> ScrubCase {
        try await Task.sleep(nanoseconds: 200_000_000)
        mockHasUsedComplimentaryCase = true
        let normalized = ScrubCase.normalize(caseDescription)
        if let index = mockCases.firstIndex(where: { ScrubCase.normalize($0.caseDescription) == normalized }) {
            let existing = mockCases[index]
            let updated = ScrubCase(
                id: existing.id,
                caseDescription: caseDescription,
                prep: prep,
                createdAt: existing.createdAt,
                updatedAt: Date(),
                lastReviewedAt: nil
            )
            mockCases[index] = updated
            return updated
        }
        let newCase = ScrubCase(
            id: UUID().uuidString,
            caseDescription: caseDescription,
            prep: prep,
            createdAt: Date(),
            updatedAt: Date(),
            lastReviewedAt: nil
        )
        mockCases.append(newCase)
        return newCase
    }

    func markCaseReviewed(caseId: String) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
        guard let index = mockCases.firstIndex(where: { $0.id == caseId }) else { return }
        let existing = mockCases[index]
        mockCases[index] = ScrubCase(
            id: existing.id,
            caseDescription: existing.caseDescription,
            prep: existing.prep,
            createdAt: existing.createdAt,
            updatedAt: existing.updatedAt,
            lastReviewedAt: Date()
        )
    }

    func deleteCase(caseId: String) async throws {
        try await Task.sleep(nanoseconds: 100_000_000)
        guard let removed = mockCases.first(where: { $0.id == caseId }) else { return }
        mockCases.removeAll { $0.id == caseId }
        let normalized = ScrubCase.normalize(removed.caseDescription)
        mockPimpMeSessions.removeAll { ScrubCase.normalize($0.caseDescription) == normalized }
    }

    func listPimpMeSessions(caseDescription: String) async throws -> [PimpMeSession] {
        try await Task.sleep(nanoseconds: 200_000_000)
        let normalized = ScrubCase.normalize(caseDescription)
        return mockPimpMeSessions.filter { ScrubCase.normalize($0.caseDescription) == normalized }
    }

    func savePimpMeSession(
        caseDescription: String,
        difficulty: PimpDifficulty,
        transcript: [PimpTurn],
        summary: PimpSummary
    ) async throws -> PimpMeSession {
        try await Task.sleep(nanoseconds: 200_000_000)
        let normalized = ScrubCase.normalize(caseDescription)
        if let index = mockPimpMeSessions.firstIndex(where: {
            ScrubCase.normalize($0.caseDescription) == normalized && $0.difficulty == difficulty
        }) {
            let updated = PimpMeSession(
                id: mockPimpMeSessions[index].id,
                caseDescription: caseDescription,
                difficulty: difficulty,
                transcript: transcript,
                summary: summary,
                completedAt: Date()
            )
            mockPimpMeSessions[index] = updated
            return updated
        }
        let newSession = PimpMeSession(
            id: UUID().uuidString,
            caseDescription: caseDescription,
            difficulty: difficulty,
            transcript: transcript,
            summary: summary,
            completedAt: Date()
        )
        mockPimpMeSessions.append(newSession)
        return newSession
    }

    // MARK: - Subscription/paywall (in-memory only — lets the paywall UI be previewed/dev-
    // tested without StoreKit or the real backend).

    private var mockHasUsedComplimentaryCase = false
    private var mockIsSubscribed = false

    func getAccessStatus() async throws -> AccessStatus {
        try await Task.sleep(nanoseconds: 150_000_000)
        return currentMockAccessStatus()
    }

    func syncSubscriptionStatus(_ report: ReportedSubscriptionStatus) async throws -> AccessStatus {
        try await Task.sleep(nanoseconds: 150_000_000)
        mockIsSubscribed = report.status == "active" || report.status == "grace_period"
        return currentMockAccessStatus()
    }

    private func currentMockAccessStatus() -> AccessStatus {
        AccessStatus(
            canGenerateNewCase: mockIsSubscribed || !mockHasUsedComplimentaryCase,
            hasUsedComplimentaryCase: mockHasUsedComplimentaryCase,
            subscription: mockIsSubscribed
                ? AccessStatus.Subscription(
                    isActive: true,
                    status: "active",
                    productId: "dev.benderapps.ScrubPrep.subscription.monthly",
                    expiresAt: Date().addingTimeInterval(30 * 24 * 60 * 60),
                    accessEndsAt: nil,
                    autoRenewStatus: true,
                    autoRenewProductId: "dev.benderapps.ScrubPrep.subscription.monthly"
                )
                : .none
        )
    }

    private static func questionTarget(for difficulty: PimpDifficulty) -> Int {
        switch difficulty {
        case .easy: return 4
        case .typical: return 5
        case .tough: return 6
        }
    }

    // MARK: - Mock case matching

    static func prep(for caseDescription: String) -> ORPrep {
        let lowered = caseDescription.lowercased()
        if lowered.contains("chole") || lowered.contains("gallbladder") {
            return .mockLapChole
        } else if lowered.contains("append") {
            return .mockAppendectomy
        } else if lowered.contains("hernia") {
            return .mockInguinalHernia
        } else if lowered.contains("colectomy") || lowered.contains("colon") {
            return .mockRightColectomy
        }
        return .mockLapChole
    }
}
