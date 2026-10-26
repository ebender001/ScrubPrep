package dev.benderapps.scrubprep.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dev.benderapps.scrubprep.AppContainer
import dev.benderapps.scrubprep.data.PHIDetector
import dev.benderapps.scrubprep.data.findCase
import dev.benderapps.scrubprep.model.ScrubCase
import kotlinx.coroutines.launch

/**
 * Backs the My Notes sheet. The prep screen only knows the case description, not the saved
 * case, so the case (and its current notes) is looked up by description when the sheet opens.
 */
class CaseNotesViewModel(
    private val container: AppContainer,
    private val caseDescription: String,
) : ViewModel() {
    enum class LoadState {
        Loading,
        Loaded,

        /** No saved case matches — e.g. the save after Prepare Me failed silently. */
        NotSaved,
        Failed,
    }

    var loadState by mutableStateOf(LoadState.Loading)
        private set
    var isSaving by mutableStateOf(false)
        private set
    var draft by mutableStateOf("")
    var errorMessage by mutableStateOf<String?>(null)

    /**
     * Likely patient identifiers found in the draft on the last save attempt — the save is
     * blocked (nothing is sent) while this is non-empty.
     */
    var phiFindings by mutableStateOf<List<PHIDetector.Finding>>(emptyList())

    private var scrubCase: ScrubCase? = null
    private var savedNotes by mutableStateOf("")

    val hasChanges: Boolean get() = draft != savedNotes

    init {
        load()
    }

    fun load() {
        viewModelScope.launch {
            loadState = LoadState.Loading
            try {
                val found = container.service.findCase(caseDescription)
                if (found == null) {
                    loadState = LoadState.NotSaved
                    return@launch
                }
                scrubCase = found
                savedNotes = found.notes.orEmpty()
                draft = savedNotes
                loadState = LoadState.Loaded
            } catch (e: Exception) {
                loadState = LoadState.Failed
            }
        }
    }

    /** Calls [onSaved] with the updated case; the sheet only dismisses on success. */
    fun save(onSaved: (ScrubCase) -> Unit) {
        val current = scrubCase ?: return
        // Checked on-device so a note with likely PHI never leaves the phone.
        val findings = PHIDetector.findings(draft)
        if (findings.isNotEmpty()) {
            phiFindings = findings
            return
        }
        viewModelScope.launch {
            isSaving = true
            try {
                val updated = container.service.saveCaseNotes(current.id, draft)
                scrubCase = updated
                savedNotes = updated.notes.orEmpty()
                container.caseUpdates.tryEmit(updated)
                onSaved(updated)
            } catch (e: Exception) {
                errorMessage = e.message ?: "Scrub Prep wasn't able to save your notes. Please try again."
            }
            isSaving = false
        }
    }
}
