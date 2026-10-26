package dev.benderapps.scrubprep.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dev.benderapps.scrubprep.AppContainer
import dev.benderapps.scrubprep.model.ORPrep
import dev.benderapps.scrubprep.model.QAPair
import kotlinx.coroutines.launch

/**
 * Drives the Rapid Fire flow: fetch exactly 5 high-yield question/answer pairs, then step
 * through them one at a time — reveal the answer, advance, repeat. Unlike Quiz Me there's
 * nothing to grade or persist; "Go Again" generates a fresh set of 5 rather than replaying
 * the same ones.
 */
class RapidFireViewModel(
    private val container: AppContainer,
    val caseDescription: String,
    val prep: ORPrep,
) : ViewModel() {
    companion object {
        /** Caps the whole review (across every "Go Again" round) at 10 questions total. */
        const val MAX_TOTAL_QUESTIONS = 10
    }

    var isLoading by mutableStateOf(true)
        private set
    var questions by mutableStateOf<List<QAPair>>(emptyList())
        private set
    var currentIndex by mutableStateOf(0)
        private set
    var isAnswerRevealed by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)

    /**
     * Every question asked across all rounds this session — sent back on the next "Go Again"
     * so a fresh set doesn't just repeat the same five questions.
     */
    private val askedQuestions = mutableListOf<String>()

    val currentQuestion: QAPair? get() = questions.getOrNull(currentIndex)
    val isComplete: Boolean get() = questions.isNotEmpty() && currentIndex >= questions.size
    val isLastQuestion: Boolean get() = currentIndex == questions.size - 1
    val canGoAgain: Boolean get() = askedQuestions.size < MAX_TOTAL_QUESTIONS

    init {
        load()
    }

    /** Safe to call again after a failed attempt — that's how "Try Again" retries. */
    fun load() {
        if (questions.isNotEmpty()) return
        isLoading = true
        errorMessage = null
        viewModelScope.launch {
            try {
                val result = container.service.generateRapidFire(caseDescription, prep, askedQuestions.toList())
                questions = result
                askedQuestions += result.map { it.question }
            } catch (e: Exception) {
                errorMessage = e.message
                    ?: "Scrub Prep wasn't able to generate your rapid fire review. Please try again."
            }
            isLoading = false
        }
    }

    fun revealAnswer() {
        isAnswerRevealed = true
    }

    fun advance() {
        isAnswerRevealed = false
        currentIndex += 1
    }

    /** Starts a new round with a freshly-generated set, steering away from questions already asked. */
    fun restart() {
        if (!canGoAgain) return
        currentIndex = 0
        isAnswerRevealed = false
        questions = emptyList()
        load()
    }
}
