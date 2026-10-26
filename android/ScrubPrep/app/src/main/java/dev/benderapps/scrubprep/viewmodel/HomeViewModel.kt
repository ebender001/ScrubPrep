package dev.benderapps.scrubprep.viewmodel

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dev.benderapps.scrubprep.ActiveCase
import dev.benderapps.scrubprep.AppContainer
import dev.benderapps.scrubprep.data.findCase
import dev.benderapps.scrubprep.model.CaseType
import dev.benderapps.scrubprep.model.ORPrep
import dev.benderapps.scrubprep.model.ScrubCase
import dev.benderapps.scrubprep.model.Specialty
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.launch

enum class HomeDestination { Prep, QuizMe, RapidFire }

class HomeViewModel(private val container: AppContainer) : ViewModel() {
    var caseDescription by mutableStateOf("")
    var isGenerating by mutableStateOf(false)
        private set

    /**
     * True while [isGenerating] is specifically generating this account's complimentary
     * (free) case — set right before the actual generatePrep call, once we've confirmed this
     * is a genuinely new case and the free allowance hasn't been used yet.
     */
    var isPreparingComplimentaryCase by mutableStateOf(false)
        private set
    var errorMessage by mutableStateOf<String?>(null)

    /**
     * Set when this is a genuinely NEW case (not already in history) and neither an active
     * subscription nor an unused complimentary case allows it. Checked entirely client-side,
     * before any network/AI request.
     */
    var showPaywall by mutableStateOf(false)

    private var generatedPrep: ORPrep? = null

    /**
     * The (trimmed) case description [generatedPrep] was actually prepared for — Quiz Me and
     * Rapid Fire are only enabled once this matches the current [caseDescription], so those
     * features are never reachable until Prepare Me has been tapped for that exact case.
     */
    private var preparedCaseDescription by mutableStateOf<String?>(null)

    /** Backend-authoritative — not cached locally. */
    var recentCases by mutableStateOf<List<ScrubCase>>(emptyList())
        private set

    var exampleChips by mutableStateOf<List<CaseType>>(emptyList())
        private set
    var specialties by mutableStateOf(container.specialtyCache.load())
        private set
    var selectedSpecialty by mutableStateOf<Specialty?>(null)
        private set

    private var allCaseTypes: List<CaseType> = emptyList()
    private var generationJob: Job? = null
    private var currentRequestId = 0L
    private var hasUsedComplimentaryCase = false

    val events: SharedFlow<HomeDestination> get() = _events
    private val _events = MutableSharedFlow<HomeDestination>(extraBufferCapacity = 1)

    val loadingMessages = listOf(
        "Reviewing the operation",
        "Identifying key anatomy",
        "Finding likely questions",
        "Building your prep",
    )

    private val service get() = container.service
    private val hasActiveSubscription get() = container.subscriptions.hasActiveSubscription

    init {
        val persistedId = container.specialtyCache.loadSelectedId()
        if (persistedId != null) selectedSpecialty = specialties.firstOrNull { it.id == persistedId }
        loadCaseTypes()
        refreshSpecialties()
    }

    /** True once the prep was actually prepared for the case description currently entered. */
    val isCurrentCasePrepared: Boolean
        get() = preparedCaseDescription != null && preparedCaseDescription == caseDescription.trim()

    /**
     * Fetches the signed-in user's saved cases. Failure is silent — "never let a decorative
     * fetch block or error out the primary flow"; Recent Cases just stays empty/stale.
     */
    fun loadCases() {
        viewModelScope.launch {
            runCatching { service.listCases() }.onSuccess { recentCases = it }
        }
    }

    fun reviewRecentCase(scrubCase: ScrubCase) = openRecentCase(scrubCase, HomeDestination.Prep)
    fun startQuizMeFromRecentCase(scrubCase: ScrubCase) = openRecentCase(scrubCase, HomeDestination.QuizMe)
    fun startRapidFireFromRecentCase(scrubCase: ScrubCase) = openRecentCase(scrubCase, HomeDestination.RapidFire)

    private fun openRecentCase(scrubCase: ScrubCase, destination: HomeDestination) {
        viewModelScope.launch {
            runCatching { service.markCaseReviewed(scrubCase.id) }
            caseDescription = scrubCase.caseDescription
            generatedPrep = scrubCase.prep
            preparedCaseDescription = scrubCase.caseDescription.trim()
            container.activeCase = ActiveCase(scrubCase.caseDescription, scrubCase.prep)
            _events.emit(destination)
            loadCases()
        }
    }

    /**
     * Fetches the full case type catalog used to filter quick-picks once a specialty is
     * selected. Failure is silent — the specialty menu still works for browsing.
     */
    private fun loadCaseTypes() {
        viewModelScope.launch {
            val caseTypes = runCatching { service.listCaseTypes() }.getOrNull() ?: return@launch
            allCaseTypes = caseTypes
            selectedSpecialty?.let { exampleChips = matchingChips(it) }
        }
    }

    /**
     * Shows the cached specialty list instantly (if any), then always refreshes from the
     * network so a backend-side catalog change eventually reaches the UI. Also re-resolves
     * the persisted/current selection against the fresh list.
     */
    private fun refreshSpecialties() {
        viewModelScope.launch {
            val fetched = runCatching { service.listSpecialties() }.getOrNull()
            if (fetched.isNullOrEmpty()) return@launch
            specialties = fetched
            container.specialtyCache.save(fetched)

            val targetId = selectedSpecialty?.id ?: container.specialtyCache.loadSelectedId()
            if (targetId != null) {
                selectedSpecialty = fetched.firstOrNull { it.id == targetId }
                selectedSpecialty?.let { if (allCaseTypes.isNotEmpty()) exampleChips = matchingChips(it) }
            }
        }
    }

    /**
     * Tapping the already-selected specialty clears back to the no-selection state. Either
     * way, the case description is cleared. The selection is persisted across launches.
     */
    fun selectSpecialty(specialty: Specialty) {
        caseDescription = ""
        if (selectedSpecialty == specialty) {
            selectedSpecialty = null
            exampleChips = emptyList()
            container.specialtyCache.saveSelectedId(null)
            return
        }
        selectedSpecialty = specialty
        exampleChips = matchingChips(specialty)
        container.specialtyCache.saveSelectedId(specialty.id)
    }

    private fun matchingChips(specialty: Specialty) = allCaseTypes.filter { it.specialty == specialty }

    fun prepareCase() {
        resolvePrep { prep ->
            generatedPrep = prep
            container.activeCase = ActiveCase(caseDescription.trim(), prep)
            _events.tryEmit(HomeDestination.Prep)
        }
    }

    /** Quiz Me tapped on Home — only reachable once [isCurrentCasePrepared]; never calls the AI. */
    fun startQuizMe() = startFromPreparedCase(HomeDestination.QuizMe)

    /** Rapid Fire tapped on Home — same precondition as [startQuizMe]. */
    fun startRapidFire() = startFromPreparedCase(HomeDestination.RapidFire)

    private fun startFromPreparedCase(destination: HomeDestination) {
        val prep = generatedPrep
        if (!isCurrentCasePrepared || prep == null) return
        container.activeCase = ActiveCase(caseDescription.trim(), prep)
        _events.tryEmit(destination)
    }

    /**
     * Resolves an [ORPrep] for the current [caseDescription] — reusing a cached one from
     * history if this exact case was already prepared, otherwise generating a new one —
     * then hands it to [onReady]. Prepare Me is the only thing on Home that can trigger AI
     * generation.
     */
    private fun resolvePrep(onReady: (ORPrep) -> Unit) {
        val trimmed = caseDescription.trim()
        if (trimmed.isEmpty() || isGenerating) return

        errorMessage = null
        isGenerating = true
        isPreparingComplimentaryCase = false

        val requestId = ++currentRequestId
        generationJob = viewModelScope.launch {
            try {
                // Already prepared this case? Reuse it — no network/OpenAI hit, and no
                // subscription/complimentary check either: reviewing an existing case must
                // stay free, including after a subscription lapses.
                val existing = service.findCase(trimmed)
                if (existing != null) {
                    if (requestId != currentRequestId) return@launch
                    runCatching { service.markCaseReviewed(existing.id) }
                    isGenerating = false
                    preparedCaseDescription = trimmed
                    onReady(existing.prep)
                    return@launch
                }

                // Only a genuinely NEW case reaches this gate — checked entirely client-side,
                // before any AI request. An active subscription always allows it; a
                // non-subscriber needs their complimentary case not yet used, read fresh off
                // their own `_User` row rather than a value that might be stale.
                if (!hasActiveSubscription) {
                    refreshComplimentaryCaseStatus()
                    if (requestId != currentRequestId) return@launch
                    if (hasUsedComplimentaryCase) {
                        isGenerating = false
                        showPaywall = true
                        return@launch
                    }
                    // No active subscription, and the complimentary case hasn't been used
                    // yet — this generation IS the free case.
                    isPreparingComplimentaryCase = true
                }

                val prep = service.generatePrep(trimmed)
                if (requestId != currentRequestId) return@launch
                runCatching { service.saveCase(trimmed, prep, selectedSpecialty?.id) }
                isGenerating = false
                isPreparingComplimentaryCase = false
                preparedCaseDescription = trimmed
                onReady(prep)
                loadCases()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                if (requestId != currentRequestId) return@launch
                isGenerating = false
                isPreparingComplimentaryCase = false
                errorMessage = e.message
                    ?: "Scrub Prep wasn't able to generate your preparation session. Please try again."
            }
        }
    }

    private suspend fun refreshComplimentaryCaseStatus() {
        runCatching { container.parseClient.fetchCurrentUser() }
            .onSuccess { hasUsedComplimentaryCase = it.optBoolean("hasUsedComplimentaryCase", false) }
    }

    /**
     * Called when the paywall confirms an active subscription — dismisses it and resumes the
     * exact same case-generation attempt that triggered it, exactly once.
     */
    fun resumeAfterSubscribing() {
        showPaywall = false
        prepareCase()
    }

    /** Bails out of an in-progress generation (Cancel returns to an interactive Home). */
    fun cancelPreparing() {
        generationJob?.cancel()
        generationJob = null
        currentRequestId++
        isGenerating = false
        isPreparingComplimentaryCase = false
    }
}
