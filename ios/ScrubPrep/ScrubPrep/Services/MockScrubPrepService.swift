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

    func generateRapidFire(caseDescription: String, prep: ORPrep) async throws -> RapidFireResult {
        try await Task.sleep(nanoseconds: 400_000_000)
        let pairs = Array(prep.likelyQuestions.prefix(5))
        if pairs.count == 5 {
            return RapidFireResult(questions: pairs)
        }
        // Pad out to 5 with generic mock questions if a mock prep has fewer than 5 likely_questions.
        var padded = pairs
        var i = 0
        while padded.count < 5 {
            padded.append(QAPair(question: MockScrubPrepService.mockQuestions[i % MockScrubPrepService.mockQuestions.count], answer: "See your OR Prep review."))
            i += 1
        }
        return RapidFireResult(questions: padded)
    }

    // Mirrors the seed data in backend/scripts/seed-specialties.js / seed-case-types.js so
    // mock mode looks the same as talking to the real catalog.
    private static let mockSpecialties: [Specialty] = [
        Specialty(id: "mock_general_surgery", name: "General Surgery"),
        Specialty(id: "mock_cardiac_surgery", name: "Cardiac Surgery"),
        Specialty(id: "mock_thoracic_surgery", name: "Thoracic Surgery"),
        Specialty(id: "mock_ent", name: "ENT"),
        Specialty(id: "mock_urology", name: "Urology"),
        Specialty(id: "mock_orthopedics", name: "Orthopedics"),
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
    ]

    private static let mockCaseTypes: [CaseType] = mockCaseTypeNamesBySpecialtyIndex.flatMap { entry in
        entry.names.map { name in
            CaseType(name: name, specialty: mockSpecialties[entry.specialtyIndex], featured: mockFeaturedCaseTypeNames.contains(name))
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

    private static func questionTarget(for difficulty: PimpDifficulty) -> Int {
        switch difficulty {
        case .easy, .typical: return 5
        case .tough: return 6
        case .merciless: return 7
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
