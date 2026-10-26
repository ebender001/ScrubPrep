package dev.benderapps.scrubprep.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dev.benderapps.scrubprep.AppContainer
import dev.benderapps.scrubprep.model.ORPrep
import dev.benderapps.scrubprep.model.PimpDifficulty
import dev.benderapps.scrubprep.model.PimpProgress
import dev.benderapps.scrubprep.model.PimpSummary
import dev.benderapps.scrubprep.model.PimpTurn
import kotlinx.coroutines.launch

/**
 * Drives an interactive Quiz Me ("Pimp Me") session: difficulty selection, then one
 * question at a time, feedback after each answer, and a final readiness summary. Each
 * difficulty can only be completed once per case — once done it's locked from restarting
 * and instead shows its saved transcript.
 */
class PimpMeViewModel(
    private val container: AppContainer,
    val caseDescription: String,
    val prep: ORPrep,
) : ViewModel() {
    sealed interface Phase {
        data object PickingDifficulty : Phase
        data object Starting : Phase

        /** Showing a question, awaiting the student's answer. */
        data object Answering : Phase

        /** Showing feedback for the answer just submitted, before advancing. */
        data object ReviewingFeedback : Phase
        data class Completed(val summary: PimpSummary) : Phase

        /** Reviewing a previously-completed difficulty's saved transcript (read-only). */
        data class ReviewingTranscript(
            val difficulty: PimpDifficulty,
            val transcript: List<PimpTurn>,
            val summary: PimpSummary,
        ) : Phase
    }

    var difficulty by mutableStateOf(PimpDifficulty.Typical)
        private set
    var phase by mutableStateOf<Phase>(Phase.PickingDifficulty)
        private set
    var currentQuestion by mutableStateOf<String?>(null)
        private set
    var progress by mutableStateOf<PimpProgress?>(null)
        private set
    var answerText by mutableStateOf("")
    var isSubmitting by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)

    /** The question/answer/feedback just submitted — shown during [Phase.ReviewingFeedback]. */
    var lastTurn by mutableStateOf<PimpTurn?>(null)
        private set
    private val history = mutableListOf<PimpTurn>()

    /**
     * Set once the final question's feedback comes back, while that feedback is still being
     * shown — the session only actually completes (and gets saved) once the student taps
     * through past it.
     */
    private var pendingSummary by mutableStateOf<PimpSummary?>(null)

    /** Difficulties already completed for this case, across all sessions ever taken. */
    var completedDifficulties by mutableStateOf<Set<PimpDifficulty>>(emptySet())
        private set

    /** True until the initial fetch of completed difficulties finishes. */
    var isLoadingCompletedDifficulties by mutableStateOf(true)
        private set

    private var sessionId: String? = null
    private val service get() = container.service

    val isFinalFeedback: Boolean get() = pendingSummary != null
    val allDifficultiesCompleted: Boolean get() = completedDifficulties.size == PimpDifficulty.entries.size

    init {
        viewModelScope.launch {
            runCatching { service.listPimpMeSessions(caseDescription) }.onSuccess { sessions ->
                completedDifficulties = sessions.map { it.difficulty }.toSet()
                // Default selection should land on something startable, not a level already done.
                if (difficulty in completedDifficulties) {
                    PimpDifficulty.entries.firstOrNull { it !in completedDifficulties }?.let { difficulty = it }
                }
            }
            isLoadingCompletedDifficulties = false
        }
    }

    /** Tapping a completed difficulty shows its saved transcript; otherwise it's selected. */
    fun selectDifficulty(level: PimpDifficulty) {
        if (level in completedDifficulties) {
            viewModelScope.launch {
                val session = runCatching { service.listPimpMeSessions(caseDescription) }.getOrNull()
                    ?.firstOrNull { it.difficulty == level } ?: return@launch
                phase = Phase.ReviewingTranscript(level, session.transcript, session.summary)
            }
        } else {
            difficulty = level
        }
    }

    /** Returns from a transcript review or a just-finished summary to the difficulty picker. */
    fun backToDifficultyPicker() {
        phase = Phase.PickingDifficulty
    }

    fun start() {
        if (difficulty in completedDifficulties) return
        phase = Phase.Starting
        errorMessage = null
        history.clear()
        lastTurn = null
        viewModelScope.launch {
            try {
                val result = service.startPimpSession(caseDescription, prep, difficulty)
                sessionId = result.sessionId
                currentQuestion = result.question
                progress = result.progress
                phase = Phase.Answering
            } catch (e: Exception) {
                phase = Phase.PickingDifficulty
                errorMessage = friendlyMessage(e)
            }
        }
    }

    fun submitAnswer() {
        val trimmed = answerText.trim()
        val id = sessionId
        val question = currentQuestion
        if (id == null || question == null || trimmed.isEmpty()) return

        isSubmitting = true
        errorMessage = null
        viewModelScope.launch {
            try {
                val result = service.answerPimpQuestion(id, trimmed)
                isSubmitting = false
                progress = result.progress
                answerText = ""

                val turn = PimpTurn(
                    question = question,
                    answer = trimmed,
                    assessment = result.assessment,
                    feedback = result.feedback,
                    teachingPoint = result.teachingPoint,
                )
                lastTurn = turn
                history += turn

                if (result.done && result.summary != null) {
                    // Show this last turn's feedback first, same as any other question —
                    // completion (and the save) happens on continueToNextQuestion().
                    pendingSummary = result.summary
                } else {
                    currentQuestion = result.nextQuestion
                }
                phase = Phase.ReviewingFeedback
            } catch (e: Exception) {
                isSubmitting = false
                errorMessage = friendlyMessage(e)
            }
        }
    }

    /**
     * Advances from the feedback shown after an answer to the next question, or — if this
     * was the final question — completes the session. The summary shows immediately rather
     * than waiting on the save, which is a best-effort background persist.
     */
    fun continueToNextQuestion() {
        val summary = pendingSummary
        if (summary != null) {
            phase = Phase.Completed(summary)
            completedDifficulties = completedDifficulties + difficulty
            pendingSummary = null
            val completedTranscript = history.toList()
            val completedLevel = difficulty
            viewModelScope.launch {
                runCatching {
                    service.savePimpMeSession(caseDescription, completedLevel, completedTranscript, summary)
                }
            }
        } else {
            phase = Phase.Answering
        }
    }

    private fun friendlyMessage(error: Exception): String =
        error.message ?: "Scrub Prep wasn't able to continue this session. Please try again."
}
