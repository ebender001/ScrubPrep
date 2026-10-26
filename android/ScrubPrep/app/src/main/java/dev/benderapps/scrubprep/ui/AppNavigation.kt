package dev.benderapps.scrubprep.ui

import androidx.compose.foundation.layout.consumeWindowInsets
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.automirrored.outlined.Assignment
import androidx.compose.material3.Icon
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LifecycleEventEffect
import kotlinx.coroutines.launch
import androidx.compose.runtime.rememberCoroutineScope
import androidx.navigation.NavBackStackEntry
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavGraphBuilder
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.navigation
import androidx.navigation.compose.rememberNavController
import dev.benderapps.scrubprep.ActiveCase
import dev.benderapps.scrubprep.ScrubPrepApplication
import dev.benderapps.scrubprep.containerViewModel
import dev.benderapps.scrubprep.ui.screens.AbbreviationsScreen
import dev.benderapps.scrubprep.ui.screens.CasesScreen
import dev.benderapps.scrubprep.ui.screens.EnergyDevicesScreen
import dev.benderapps.scrubprep.ui.screens.FirstDayScreen
import dev.benderapps.scrubprep.ui.screens.HomeScreen
import dev.benderapps.scrubprep.ui.screens.IncisionsScreen
import dev.benderapps.scrubprep.ui.screens.InstrumentsScreen
import dev.benderapps.scrubprep.ui.screens.LearnRoutes
import dev.benderapps.scrubprep.ui.screens.LearnScreen
import dev.benderapps.scrubprep.ui.screens.LearnSourcesScreen
import dev.benderapps.scrubprep.ui.screens.PositioningScreen
import dev.benderapps.scrubprep.ui.screens.PrepScreen
import dev.benderapps.scrubprep.ui.screens.QuizMeScreen
import dev.benderapps.scrubprep.ui.screens.RapidFireScreen
import dev.benderapps.scrubprep.ui.screens.SettingsScreen
import dev.benderapps.scrubprep.viewmodel.AuthViewModel
import dev.benderapps.scrubprep.viewmodel.CasesListViewModel
import dev.benderapps.scrubprep.viewmodel.HomeDestination
import dev.benderapps.scrubprep.viewmodel.HomeViewModel
import dev.benderapps.scrubprep.viewmodel.PimpMeViewModel
import dev.benderapps.scrubprep.viewmodel.RapidFireViewModel
import androidx.lifecycle.ViewModel

private enum class Tab(val graph: String, val start: String, val label: String, val icon: ImageVector) {
    Home("tab_home", "home", "Home", Icons.Filled.Home),
    Cases("tab_cases", "cases", "Cases", Icons.AutoMirrored.Outlined.Assignment),
    Learn("tab_learn", "learn", "Learn", Icons.AutoMirrored.Filled.MenuBook),
    Settings("tab_settings", "settings", "Settings", Icons.Filled.Settings),
}

/** Holds the case a screen was opened for, so a tab switch can't swap it out from under it. */
private class ActiveCaseViewModel(val case: ActiveCase?) : ViewModel()

/** Bottom tab bar: Home | Cases | Learn | Settings. Each tab keeps its own back stack. */
@Composable
fun MainScreen(auth: AuthViewModel) {
    val navController = rememberNavController()
    val backStackEntry by navController.currentBackStackEntryAsState()
    val destination = backStackEntry?.destination
    val isTopLevel = Tab.entries.any { it.start == destination?.route }

    // Refresh subscription entitlements on every foreground — the moment Play's own state
    // most needs re-checking (a renewal, cancellation or refund may have happened).
    val context = LocalContext.current
    val subscriptions = remember { (context.applicationContext as ScrubPrepApplication).container.subscriptions }
    val scope = rememberCoroutineScope()
    LifecycleEventEffect(Lifecycle.Event.ON_RESUME) {
        scope.launch { subscriptions.refreshEntitlements() }
    }

    Scaffold(
        bottomBar = {
            if (isTopLevel) {
                NavigationBar {
                    Tab.entries.forEach { tab ->
                        NavigationBarItem(
                            selected = destination?.hierarchy?.any { it.route == tab.graph } == true,
                            onClick = {
                                navController.navigate(tab.graph) {
                                    popUpTo(navController.graph.findStartDestination().id) { saveState = true }
                                    launchSingleTop = true
                                    restoreState = true
                                }
                            },
                            icon = { Icon(tab.icon, contentDescription = null) },
                            label = { Text(tab.label) },
                        )
                    }
                }
            }
        },
    ) { innerPadding ->
        NavHost(
            navController = navController,
            startDestination = Tab.Home.graph,
            modifier = Modifier.padding(innerPadding).consumeWindowInsets(innerPadding),
        ) {
            navigation(startDestination = Tab.Home.start, route = Tab.Home.graph) {
                composable("home") {
                    val vm = containerViewModel { HomeViewModel(it) }
                    HomeScreen(
                        viewModel = vm,
                        onNavigate = { destination ->
                            navController.navigate(
                                when (destination) {
                                    HomeDestination.Prep -> "home/prep"
                                    HomeDestination.QuizMe -> "home/quiz"
                                    HomeDestination.RapidFire -> "home/rapid"
                                },
                            )
                        },
                        onOpenFirstDay = { navController.navigate("home/firstDay") },
                    )
                }
                composable("home/firstDay") { FirstDayScreen(onBack = navController::popBackStack) }
                caseFlow(navController, prefix = "home")
            }
            navigation(startDestination = Tab.Cases.start, route = Tab.Cases.graph) {
                composable("cases") {
                    val container = (LocalContext.current.applicationContext as ScrubPrepApplication).container
                    val vm = containerViewModel { CasesListViewModel(it) }
                    CasesScreen(vm, onOpenCase = { scrubCase ->
                        vm.markReviewed(scrubCase)
                        container.activeCase = ActiveCase(scrubCase.caseDescription, scrubCase.prep)
                        navController.navigate("cases/prep")
                    })
                }
                caseFlow(navController, prefix = "cases")
            }
            navigation(startDestination = Tab.Learn.start, route = Tab.Learn.graph) {
                composable("learn") {
                    LearnScreen(onNavigate = { navController.navigate("learn/$it") })
                }
                composable("learn/${LearnRoutes.FirstDay}") { FirstDayScreen(navController::popBackStack) }
                composable("learn/${LearnRoutes.Instruments}") { InstrumentsScreen(navController::popBackStack) }
                composable("learn/${LearnRoutes.Abbreviations}") { AbbreviationsScreen(navController::popBackStack) }
                composable("learn/${LearnRoutes.Energy}") { EnergyDevicesScreen(navController::popBackStack) }
                composable("learn/${LearnRoutes.Positioning}") { PositioningScreen(navController::popBackStack) }
                composable("learn/${LearnRoutes.Incisions}") { IncisionsScreen(navController::popBackStack) }
                composable("learn/${LearnRoutes.Sources}") { LearnSourcesScreen(navController::popBackStack) }
            }
            navigation(startDestination = Tab.Settings.start, route = Tab.Settings.graph) {
                composable("settings") { SettingsScreen(auth) }
            }
        }
    }
}

/**
 * The prep → Quiz Me / Rapid Fire destinations, registered under each tab that can open
 * them (`home/…` and `cases/…`) so every tab keeps its own back stack.
 */
private fun NavGraphBuilder.caseFlow(navController: NavHostController, prefix: String) {
    composable("$prefix/prep") { entry ->
        val container = (LocalContext.current.applicationContext as ScrubPrepApplication).container
        val case = activeCaseFor(entry) ?: run { LaunchedEffect(Unit) { navController.popBackStack() }; return@composable }
        PrepScreen(
            caseDescription = case.caseDescription,
            prep = case.prep,
            onBack = navController::popBackStack,
            onQuizMe = {
                container.activeCase = case
                navController.navigate("$prefix/quiz")
            },
            onRapidFire = {
                container.activeCase = case
                navController.navigate("$prefix/rapid")
            },
        )
    }
    composable("$prefix/quiz") { entry ->
        val case = activeCaseFor(entry) ?: run { LaunchedEffect(Unit) { navController.popBackStack() }; return@composable }
        val vm = containerViewModel { PimpMeViewModel(it, case.caseDescription, case.prep) }
        QuizMeScreen(vm, onBack = navController::popBackStack)
    }
    composable("$prefix/rapid") { entry ->
        val case = activeCaseFor(entry) ?: run { LaunchedEffect(Unit) { navController.popBackStack() }; return@composable }
        val vm = containerViewModel { RapidFireViewModel(it, case.caseDescription, case.prep) }
        RapidFireScreen(vm, onBack = navController::popBackStack)
    }
}

@Composable
@Suppress("UNUSED_PARAMETER")
private fun activeCaseFor(entry: NavBackStackEntry): ActiveCase? =
    containerViewModel { ActiveCaseViewModel(it.activeCase) }.case
