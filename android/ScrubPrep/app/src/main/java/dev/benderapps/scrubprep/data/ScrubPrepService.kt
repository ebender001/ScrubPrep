package dev.benderapps.scrubprep.data

import dev.benderapps.scrubprep.model.CaseType
import dev.benderapps.scrubprep.model.ORPrep
import dev.benderapps.scrubprep.model.PimpAnswerResult
import dev.benderapps.scrubprep.model.PimpDifficulty
import dev.benderapps.scrubprep.model.PimpMeSession
import dev.benderapps.scrubprep.model.PimpSessionStart
import dev.benderapps.scrubprep.model.PimpSummary
import dev.benderapps.scrubprep.model.PimpTurn
import dev.benderapps.scrubprep.model.QAPair
import dev.benderapps.scrubprep.model.ScrubCase
import dev.benderapps.scrubprep.model.Specialty
import dev.benderapps.scrubprep.model.mapObjects
import dev.benderapps.scrubprep.model.toJsonArray
import kotlinx.coroutines.flow.MutableSharedFlow
import org.json.JSONObject

/**
 * Errors surfaced to the UI. Kept generic and friendly — never show raw backend/network
 * errors to the student. [Unrecognized] is the one deliberate exception: it carries the
 * backend's own (randomly-picked, witty) message verbatim — see backend/cloud/main.js's
 * UNRECOGNIZED_CASE_MESSAGES.
 */
sealed class ScrubPrepError(override val message: String) : Exception(message) {
    data object Network : ScrubPrepError("Check your connection and try again.")
    data object Server : ScrubPrepError("Scrub Prep wasn't able to generate your preparation session. Please try again.")
    class Unrecognized(message: String) : ScrubPrepError(message)
}

/** Talks to the backend's Cloud Functions. All OpenAI calls happen server-side. */
interface ScrubPrepService {
    suspend fun generatePrep(caseDescription: String): ORPrep
    suspend fun startPimpSession(caseDescription: String, prep: ORPrep, difficulty: PimpDifficulty): PimpSessionStart
    suspend fun answerPimpQuestion(sessionId: String, answer: String): PimpAnswerResult
    suspend fun generateRapidFire(caseDescription: String, prep: ORPrep, previousQuestions: List<String>): List<QAPair>
    suspend fun listCaseTypes(): List<CaseType>
    suspend fun listSpecialties(): List<Specialty>

    // Cases and Pimp Me sessions are backend-authoritative (not stored on the device) —
    // every one of these requires a signed-in user server-side.
    suspend fun listCases(): List<ScrubCase>
    suspend fun saveCase(caseDescription: String, prep: ORPrep, specialtyId: String?): ScrubCase
    suspend fun markCaseReviewed(caseId: String)

    /** Replaces the case's notes; "" clears them. */
    suspend fun saveCaseNotes(caseId: String, notes: String): ScrubCase
    suspend fun deleteCase(caseId: String)
    suspend fun listPimpMeSessions(caseDescription: String): List<PimpMeSession>
    suspend fun savePimpMeSession(
        caseDescription: String,
        difficulty: PimpDifficulty,
        transcript: List<PimpTurn>,
        summary: PimpSummary,
    ): PimpMeSession
    suspend fun deleteAccount()
}

// Custom Parse error code backend/cloud/main.js uses for "that wasn't a real procedure" —
// see UNRECOGNIZED_CASE_ERROR_CODE there. Kept in sync manually.
private const val UNRECOGNIZED_CASE_ERROR_CODE = 4001

class ParseScrubPrepService(
    private val client: ParseClient,
    /** Emitted whenever the backend rejects the stored session token. */
    private val invalidSession: MutableSharedFlow<Unit>,
) : ScrubPrepService {

    override suspend fun generatePrep(caseDescription: String): ORPrep = run {
        ORPrep.fromJson(client.callFunction("generateScrubPrep", JSONObject().put("caseDescription", caseDescription)))
    }

    override suspend fun startPimpSession(
        caseDescription: String,
        prep: ORPrep,
        difficulty: PimpDifficulty,
    ): PimpSessionStart = run {
        PimpSessionStart.fromJson(
            client.callFunction(
                "startPimpSession",
                JSONObject()
                    .put("caseDescription", caseDescription)
                    .put("prep", prep.toJson())
                    .put("difficulty", difficulty.raw),
            ),
        )
    }

    override suspend fun answerPimpQuestion(sessionId: String, answer: String): PimpAnswerResult = run {
        PimpAnswerResult.fromJson(
            client.callFunction("answerPimpQuestion", JSONObject().put("sessionId", sessionId).put("answer", answer)),
        )
    }

    override suspend fun generateRapidFire(
        caseDescription: String,
        prep: ORPrep,
        previousQuestions: List<String>,
    ): List<QAPair> = run {
        client.callFunction(
            "generateRapidFire",
            JSONObject()
                .put("caseDescription", caseDescription)
                .put("prep", prep.toJson())
                .put("previousQuestions", previousQuestions.toJsonArray()),
        ).getJSONArray("questions").mapObjects(QAPair::fromJson)
    }

    override suspend fun listCaseTypes(): List<CaseType> = run {
        client.callFunction("listCaseTypes").getJSONArray("caseTypes").mapObjects(CaseType::fromJson)
    }

    override suspend fun listSpecialties(): List<Specialty> = run {
        client.callFunction("listSpecialties").getJSONArray("specialties").mapObjects(Specialty::fromJson)
    }

    override suspend fun listCases(): List<ScrubCase> = run {
        client.callFunction("listCases").getJSONArray("cases").mapObjects(ScrubCase::fromJson)
    }

    override suspend fun saveCase(caseDescription: String, prep: ORPrep, specialtyId: String?): ScrubCase = run {
        val params = JSONObject().put("caseDescription", caseDescription).put("prep", prep.toJson())
        if (specialtyId != null) params.put("specialtyId", specialtyId)
        ScrubCase.fromJson(client.callFunction("saveCase", params).getJSONObject("case"))
    }

    override suspend fun markCaseReviewed(caseId: String) = run {
        client.callFunction("markCaseReviewed", JSONObject().put("caseId", caseId))
        Unit
    }

    override suspend fun saveCaseNotes(caseId: String, notes: String): ScrubCase = run {
        ScrubCase.fromJson(
            client.callFunction("saveCaseNotes", JSONObject().put("caseId", caseId).put("notes", notes))
                .getJSONObject("case"),
        )
    }

    override suspend fun deleteCase(caseId: String) = run {
        client.callFunction("deleteCase", JSONObject().put("caseId", caseId))
        Unit
    }

    override suspend fun listPimpMeSessions(caseDescription: String): List<PimpMeSession> = run {
        client.callFunction("listPimpMeSessions", JSONObject().put("caseDescription", caseDescription))
            .getJSONArray("sessions").mapObjects(PimpMeSession::fromJson)
    }

    override suspend fun savePimpMeSession(
        caseDescription: String,
        difficulty: PimpDifficulty,
        transcript: List<PimpTurn>,
        summary: PimpSummary,
    ): PimpMeSession = run {
        PimpMeSession.fromJson(
            client.callFunction(
                "savePimpMeSession",
                JSONObject()
                    .put("caseDescription", caseDescription)
                    .put("difficulty", difficulty.raw)
                    .put("transcript", transcript.toJsonArray { it.toJson() })
                    .put("summary", summary.toJson()),
            ).getJSONObject("session"),
        )
    }

    override suspend fun deleteAccount() = run {
        client.callFunction("deleteAccount")
        Unit
    }

    /**
     * Maps Parse / networking failures onto the UI-facing error type. A stale session token
     * makes Parse Server reject EVERY request carrying it, even calls to functions that
     * don't themselves require sign-in — [invalidSession] lets the auth layer force a
     * sign-out back to the sign-in screen instead of leaving the app signed-in-but-broken.
     */
    private suspend fun <T> run(operation: suspend () -> T): T {
        try {
            return operation()
        } catch (e: ParseApiException) {
            if (e.code == UNRECOGNIZED_CASE_ERROR_CODE) throw ScrubPrepError.Unrecognized(e.message.orEmpty())
            if (e.code == ParseApiException.INVALID_SESSION_TOKEN) invalidSession.tryEmit(Unit)
            throw ScrubPrepError.Server
        } catch (e: ParseNetworkException) {
            throw ScrubPrepError.Network
        } catch (e: org.json.JSONException) {
            throw ScrubPrepError.Server
        }
    }
}
