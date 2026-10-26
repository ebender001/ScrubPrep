package dev.benderapps.scrubprep

import android.app.Application
import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.CreationExtras
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.compose.runtime.Composable
import dev.benderapps.scrubprep.data.ParseClient
import dev.benderapps.scrubprep.data.ParseScrubPrepService
import dev.benderapps.scrubprep.data.ScrubPrepService
import dev.benderapps.scrubprep.data.SessionStore
import dev.benderapps.scrubprep.data.SpecialtyCache
import dev.benderapps.scrubprep.data.SubscriptionManager
import dev.benderapps.scrubprep.model.ORPrep
import dev.benderapps.scrubprep.model.ScrubCase
import kotlinx.coroutines.flow.MutableSharedFlow

/** The case a prep / Quiz Me / Rapid Fire screen is showing. */
data class ActiveCase(val caseDescription: String, val prep: ORPrep)

/** Hand-rolled dependency container — one per process, created by [ScrubPrepApplication]. */
class AppContainer(context: Context) {
    val sessionStore = SessionStore(context)
    val specialtyCache = SpecialtyCache(context)

    /** Emitted whenever any backend call comes back with an invalid session token. */
    val invalidSession = MutableSharedFlow<Unit>(extraBufferCapacity = 1)

    val parseClient = ParseClient(sessionStore)
    val service: ScrubPrepService = ParseScrubPrepService(parseClient, invalidSession)
    val subscriptions = SubscriptionManager(context)

    /**
     * Handed to the next prep / Quiz Me / Rapid Fire screen. A full prep is too large to put
     * in a navigation argument; a screen that finds this null (process death) just pops.
     */
    @Volatile
    var activeCase: ActiveCase? = null

    /** A case updated elsewhere (e.g. notes saved from its prep screen), for the Cases list. */
    val caseUpdates = MutableSharedFlow<ScrubCase>(extraBufferCapacity = 8)
}

class ScrubPrepApplication : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}

@PublishedApi
internal val CreationExtras.container: AppContainer
    get() = (this[ViewModelProvider.AndroidViewModelFactory.APPLICATION_KEY] as ScrubPrepApplication).container

/** `viewModel()` for a view model built from the [AppContainer]. */
@Composable
inline fun <reified VM : ViewModel> containerViewModel(
    key: String? = null,
    crossinline build: (AppContainer) -> VM,
): VM = viewModel(
    key = key,
    factory = object : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>, extras: CreationExtras): T =
            build(extras.container) as T
    },
)
