package dev.benderapps.scrubprep.ui.screens

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.horizontalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.KeyboardArrowRight
import androidx.compose.material.icons.filled.ArrowDropDown
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.AutoAwesome
import androidx.compose.material.icons.filled.LockOpen
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.ui.text.input.KeyboardCapitalization
import dev.benderapps.scrubprep.model.CaseType
import dev.benderapps.scrubprep.model.ScrubCase
import dev.benderapps.scrubprep.model.Specialty
import dev.benderapps.scrubprep.ui.components.CardSurface
import dev.benderapps.scrubprep.ui.components.LoadingView
import dev.benderapps.scrubprep.ui.components.PrimaryButton
import dev.benderapps.scrubprep.ui.components.PrivacyNote
import dev.benderapps.scrubprep.ui.components.ScreenScaffold
import dev.benderapps.scrubprep.ui.components.ScrollColumn
import dev.benderapps.scrubprep.ui.components.SecondaryText
import dev.benderapps.scrubprep.ui.theme.InfoBlue
import dev.benderapps.scrubprep.ui.theme.QuizOrange
import dev.benderapps.scrubprep.ui.theme.RapidYellow
import dev.benderapps.scrubprep.viewmodel.HomeDestination
import dev.benderapps.scrubprep.viewmodel.HomeViewModel
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

@Composable
fun HomeScreen(
    viewModel: HomeViewModel,
    onNavigate: (HomeDestination) -> Unit,
    onOpenFirstDay: () -> Unit,
    onPurchaseCompleted: () -> Unit = viewModel::resumeAfterSubscribing,
) {
    LaunchedEffect(viewModel) {
        viewModel.loadCases()
        viewModel.events.collect(onNavigate)
    }

    Box(Modifier.fillMaxSize()) {
        ScreenScaffold(
            title = "Scrub Prep",
            actions = {
                if (viewModel.specialties.isNotEmpty()) {
                    SpecialtyMenu(viewModel.specialties, viewModel.selectedSpecialty, viewModel::selectSpecialty)
                }
            },
        ) {
            ScrollColumn(spacing = 24) {
                AnimatedVisibility(viewModel.selectedSpecialty == null) {
                    Text(
                        "Pick a specialty to get started",
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary,
                    )
                }

                CaseEntryCard(
                    caseDescription = viewModel.caseDescription,
                    onCaseDescriptionChange = { viewModel.caseDescription = it },
                    exampleChips = viewModel.exampleChips,
                    selectedSpecialty = viewModel.selectedSpecialty,
                    onSubmit = viewModel::prepareCase,
                )

                Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                    // Not disabled — the card keeps full color and its trailing lock icon
                    // signals the locked state; startQuizMe() no-ops until the case is prepared.
                    ActionCard(
                        title = "Quiz Me",
                        subtitle = "Test me before I scrub.",
                        description = "Interactive questions tailored to your case.",
                        icon = Icons.Filled.LocalFireDepartment,
                        tint = QuizOrange,
                        isLocked = !viewModel.isCurrentCasePrepared,
                        lockedMessage = "Unlocks after Prepare Me",
                        onClick = viewModel::startQuizMe,
                    )
                    ActionCard(
                        title = "Rapid Fire",
                        subtitle = "2 minutes before the OR.",
                        description = "Five high-yield questions. No lengthy explanations.",
                        icon = Icons.Filled.Bolt,
                        tint = RapidYellow,
                        isLocked = !viewModel.isCurrentCasePrepared,
                        lockedMessage = "Unlocks after Prepare Me",
                        onClick = viewModel::startRapidFire,
                    )
                    ActionCard(
                        title = "First Day?",
                        subtitle = "New to the surgery rotation?",
                        description = "Learn rounds, scrubbing, OR etiquette, presentations, and what your team expects.",
                        icon = Icons.Filled.AutoAwesome,
                        tint = InfoBlue,
                        onClick = onOpenFirstDay,
                    )
                }

                if (viewModel.recentCases.isNotEmpty()) {
                    RecentCasesSection(
                        recentCases = viewModel.recentCases,
                        onReview = viewModel::reviewRecentCase,
                        onQuizMe = viewModel::startQuizMeFromRecentCase,
                        onRapidFire = viewModel::startRapidFireFromRecentCase,
                    )
                }
            }
        }

        if (viewModel.isGenerating) {
            Box(Modifier.fillMaxSize().background(MaterialTheme.colorScheme.background.copy(alpha = 0.96f)).clickable(enabled = false) {}) {
                LoadingView(
                    title = if (viewModel.isPreparingComplimentaryCase) {
                        "Preparing your free case…\nSubsequent cases require a subscription"
                    } else {
                        "Preparing your case…"
                    },
                    messages = viewModel.loadingMessages,
                    onCancel = viewModel::cancelPreparing,
                )
            }
        }
    }

    viewModel.errorMessage?.let { message ->
        AlertDialog(
            onDismissRequest = { viewModel.errorMessage = null },
            title = { Text("Couldn't prepare this case") },
            text = { Text(message) },
            confirmButton = { TextButton(onClick = { viewModel.errorMessage = null }) { Text("OK") } },
        )
    }

    if (viewModel.showPaywall) {
        PaywallSheet(onDismiss = { viewModel.showPaywall = false }, onPurchaseCompleted = onPurchaseCompleted)
    }
}

/**
 * The specialty filter shown as a drop-down in the toolbar. Picking a specialty narrows the
 * case-entry card's quick-pick chips to it; picking the selected one again clears the filter.
 */
@Composable
private fun SpecialtyMenu(specialties: List<Specialty>, selected: Specialty?, onSelect: (Specialty) -> Unit) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        TextButton(onClick = { expanded = true }) {
            Text(selected?.name ?: "Specialty", maxLines = 1, style = MaterialTheme.typography.titleSmall)
            Icon(Icons.Filled.ArrowDropDown, contentDescription = null)
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            specialties.sortedBy { it.name.lowercase() }.forEach { specialty ->
                DropdownMenuItem(
                    text = { Text(specialty.name) },
                    trailingIcon = { if (specialty == selected) Icon(Icons.Filled.Check, contentDescription = "Selected") },
                    onClick = {
                        expanded = false
                        onSelect(specialty)
                    },
                )
            }
        }
    }
}

/** The dominant "What are you scrubbing on?" card on the Home screen. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun CaseEntryCard(
    caseDescription: String,
    onCaseDescriptionChange: (String) -> Unit,
    exampleChips: List<CaseType>,
    selectedSpecialty: Specialty?,
    onSubmit: () -> Unit,
) {
    val focusManager = LocalFocusManager.current
    val isSpecialtySelected = selectedSpecialty != null

    // Doubles as the instructions and the specialty-specific example, so the student sees
    // what to enter right where they type.
    val placeholder = if (selectedSpecialty == null) {
        "Select a specialty first"
    } else {
        val example = selectedSpecialty.displayedExampleCaseDescription
        if (exampleChips.isEmpty()) "e.g. $example" else "Type a case or tap one below, e.g. $example"
    }

    CardSurface(cornerRadius = 20) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Text("What are you scrubbing on?", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)

            OutlinedTextField(
                value = caseDescription,
                onValueChange = onCaseDescriptionChange,
                enabled = isSpecialtySelected,
                placeholder = { Text(placeholder) },
                minLines = 3,
                shape = RoundedCornerShape(12.dp),
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences),
                trailingIcon = {
                    if (caseDescription.isNotEmpty()) {
                        IconButton(onClick = { onCaseDescriptionChange("") }) {
                            Icon(Icons.Filled.Cancel, contentDescription = "Clear", tint = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth(),
            )

            if (exampleChips.isNotEmpty()) {
                Row(
                    Modifier.horizontalScroll(rememberScrollState()),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    exampleChips.forEach { chip ->
                        Text(
                            chip.name,
                            style = MaterialTheme.typography.labelLarge,
                            modifier = Modifier
                                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f), CircleShape)
                                .clickable { onCaseDescriptionChange(chip.fullName) }
                                .padding(horizontal = 12.dp, vertical = 7.dp),
                        )
                    }
                }
            }

            PrimaryButton(
                text = "Prepare Me",
                enabled = isSpecialtySelected && caseDescription.isNotBlank(),
                onClick = {
                    focusManager.clearFocus()
                    onSubmit()
                },
            )
            PrivacyNote()
        }
    }
}

/** The Quiz Me / Rapid Fire / First Day cards on the Home screen. */
@Composable
private fun ActionCard(
    title: String,
    subtitle: String,
    description: String,
    icon: ImageVector,
    tint: Color,
    onClick: () -> Unit,
    /** Drives the trailing lock icon for cards gated behind Prepare Me; `null` shows a chevron. */
    isLocked: Boolean? = null,
    lockedMessage: String? = null,
) {
    CardSurface(onClick = onClick) {
        Row(Modifier.padding(16.dp), horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(
                Modifier.size(40.dp).background(tint.copy(alpha = 0.15f), RoundedCornerShape(10.dp)),
                contentAlignment = Alignment.Center,
            ) { Icon(icon, contentDescription = null, tint = tint, modifier = Modifier.size(24.dp)) }

            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(title, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
                Text(subtitle, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                Text(description, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                if (isLocked == true && lockedMessage != null) {
                    Text(
                        lockedMessage,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                        modifier = Modifier.padding(top = 1.dp),
                    )
                }
            }

            when (isLocked) {
                null -> Icon(Icons.AutoMirrored.Outlined.KeyboardArrowRight, contentDescription = null, tint = MaterialTheme.colorScheme.onSurfaceVariant)
                true -> Icon(Icons.Filled.Lock, contentDescription = "Locked", tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.6f))
                false -> Icon(Icons.Filled.LockOpen, contentDescription = "Unlocked", tint = tint)
            }
        }
    }
}

/** The "Recent Cases" list on the Home screen — the 5 most recently updated cases. */
@Composable
private fun RecentCasesSection(
    recentCases: List<ScrubCase>,
    onReview: (ScrubCase) -> Unit,
    onQuizMe: (ScrubCase) -> Unit,
    onRapidFire: (ScrubCase) -> Unit,
) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text("Recent Cases", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        recentCases.take(5).forEach { scrubCase ->
            CardSurface(cornerRadius = 14) {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text(scrubCase.prep.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
                    SecondaryText(formatDate(scrubCase), Modifier)
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                        SmallOutlinedButton("Review") { onReview(scrubCase) }
                        SmallOutlinedButton("Quiz Me") { onQuizMe(scrubCase) }
                        SmallOutlinedButton("Rapid Fire") { onRapidFire(scrubCase) }
                    }
                }
            }
        }
    }
}

@Composable
private fun SmallOutlinedButton(text: String, onClick: () -> Unit) {
    OutlinedButton(
        onClick = onClick,
        contentPadding = androidx.compose.foundation.layout.PaddingValues(horizontal = 12.dp, vertical = 0.dp),
        modifier = Modifier.height(34.dp),
    ) { Text(text, style = MaterialTheme.typography.labelMedium) }
}

private val dateFormatter = DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.getDefault())

internal fun formatDate(scrubCase: ScrubCase): String =
    dateFormatter.format(scrubCase.createdAt.atZone(ZoneId.systemDefault()))
