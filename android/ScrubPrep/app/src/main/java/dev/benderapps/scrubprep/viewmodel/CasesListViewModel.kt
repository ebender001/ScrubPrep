package dev.benderapps.scrubprep.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dev.benderapps.scrubprep.AppContainer
import dev.benderapps.scrubprep.model.ScrubCase
import dev.benderapps.scrubprep.model.Specialty
import kotlinx.coroutines.launch

/** Sort choices for the Cases list's sort/filter menu. */
enum class CaseSortOrder(val title: String) {
    NewestFirst("Newest first"),
    OldestFirst("Oldest first"),
    NameAscending("Name A–Z"),
}

/** Backs the full Cases list — separate from the Home view model, which only needs the 5 most recent. */
class CasesListViewModel(private val container: AppContainer) : ViewModel() {
    var cases by mutableStateOf<List<ScrubCase>>(emptyList())
        private set
    var isLoading by mutableStateOf(true)
        private set
    var errorMessage by mutableStateOf<String?>(null)

    var searchText by mutableStateOf("")
    var sortOrder by mutableStateOf(CaseSortOrder.entries.firstOrNull {
        it.name == container.sessionStore.sortOrderName()
    } ?: CaseSortOrder.NewestFirst)
        private set

    /** `Specialty.id` to filter by, or `null` for all specialties. Not persisted. */
    var specialtyFilter by mutableStateOf<String?>(null)

    /** Show only cases with notes. Not persisted. */
    var hasNotesFilter by mutableStateOf(false)

    init {
        // A case updated elsewhere (e.g. notes saved from its prep screen) is swapped in
        // without a full reload.
        viewModelScope.launch { container.caseUpdates.collect(::replace) }
    }

    /** Specialties that actually appear in the user's saved cases, alphabetized. */
    val availableSpecialties: List<Specialty>
        get() = cases.mapNotNull { it.specialty }.distinct().sortedBy { it.name.lowercase() }

    val anyCaseHasNotes: Boolean get() = cases.any { it.hasNotes }

    val isFiltering: Boolean get() = specialtyFilter != null || hasNotesFilter

    val trimmedSearchText: String get() = searchText.trim()

    fun updateSortOrder(order: CaseSortOrder) {
        sortOrder = order
        container.sessionStore.saveSortOrderName(order.name)
    }

    /** The cases to display — filtered by search text and specialty, then sorted. */
    fun visibleCases(): List<ScrubCase> {
        val query = trimmedSearchText
        val filtered = cases.filter { scrubCase ->
            if (specialtyFilter != null && scrubCase.specialty?.id != specialtyFilter) return@filter false
            if (hasNotesFilter && !scrubCase.hasNotes) return@filter false
            if (query.isEmpty()) return@filter true
            scrubCase.prep.title.contains(query, ignoreCase = true) ||
                scrubCase.caseDescription.contains(query, ignoreCase = true) ||
                (scrubCase.notes?.contains(query, ignoreCase = true) ?: false)
        }
        return when (sortOrder) {
            CaseSortOrder.NewestFirst -> filtered.sortedByDescending { it.createdAt }
            CaseSortOrder.OldestFirst -> filtered.sortedBy { it.createdAt }
            CaseSortOrder.NameAscending -> filtered.sortedBy { it.prep.title.lowercase() }
        }
    }

    fun clearFilters() {
        specialtyFilter = null
        hasNotesFilter = false
    }

    fun load() {
        viewModelScope.launch {
            isLoading = true
            errorMessage = null
            try {
                cases = container.service.listCases()
                dropStaleFilters()
            } catch (e: Exception) {
                errorMessage = e.message ?: "Scrub Prep wasn't able to load your cases. Please try again."
            }
            isLoading = false
        }
    }

    private fun replace(updated: ScrubCase) {
        val index = cases.indexOfFirst { it.id == updated.id }
        if (index < 0) return
        cases = cases.toMutableList().also { it[index] = updated }
        dropStaleFilters()
    }

    fun markReviewed(scrubCase: ScrubCase) {
        viewModelScope.launch { runCatching { container.service.markCaseReviewed(scrubCase.id) } }
    }

    /** Removes locally only after the server confirms the delete succeeded. */
    fun delete(target: ScrubCase) {
        viewModelScope.launch {
            try {
                container.service.deleteCase(target.id)
                cases = cases.filterNot { it.id == target.id }
                dropStaleFilters()
            } catch (e: Exception) {
                errorMessage = e.message ?: "Scrub Prep wasn't able to delete this case. Please try again."
            }
        }
    }

    /** Clears a filter once no remaining case matches it. */
    private fun dropStaleFilters() {
        if (specialtyFilter != null && cases.none { it.specialty?.id == specialtyFilter }) specialtyFilter = null
        if (hasNotesFilter && !anyCaseHasNotes) hasNotesFilter = false
    }
}
