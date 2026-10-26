package dev.benderapps.scrubprep.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.Box
import dev.benderapps.scrubprep.containerViewModel
import dev.benderapps.scrubprep.ui.components.EmptyState
import dev.benderapps.scrubprep.ui.components.ErrorStateView
import dev.benderapps.scrubprep.ui.components.PrivacyNote
import dev.benderapps.scrubprep.viewmodel.CaseNotesViewModel
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.StickyNote2

/** The My Notes sheet for a case. Edits a draft; nothing is saved until Save is tapped. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CaseNotesSheet(caseDescription: String, caseTitle: String, onDismiss: () -> Unit) {
    val viewModel = containerViewModel(key = "notes:$caseDescription") { CaseNotesViewModel(it, caseDescription) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        // Swiping down would silently discard unsaved edits.
        properties = androidx.compose.material3.ModalBottomSheetProperties(shouldDismissOnBackPress = !viewModel.hasChanges),
        sheetGesturesEnabled = !viewModel.hasChanges,
    ) {
        Column(Modifier.fillMaxSize().imePadding().padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                TextButton(onClick = onDismiss) { Text("Cancel") }
                Text(
                    "My Notes",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    modifier = Modifier.weight(1f),
                    textAlign = androidx.compose.ui.text.style.TextAlign.Center,
                )
                if (viewModel.isSaving) {
                    Box(Modifier.padding(horizontal = 16.dp)) { CircularProgressIndicator(Modifier.size(20.dp), strokeWidth = 2.dp) }
                } else {
                    TextButton(
                        enabled = viewModel.loadState == CaseNotesViewModel.LoadState.Loaded && viewModel.hasChanges,
                        onClick = { viewModel.save(onSaved = { onDismiss() }) },
                    ) { Text("Save") }
                }
            }

            when (viewModel.loadState) {
                CaseNotesViewModel.LoadState.Loading ->
                    Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
                CaseNotesViewModel.LoadState.NotSaved ->
                    EmptyState("Case not saved", "Notes can be added once this case is saved to your Cases.", Icons.AutoMirrored.Outlined.StickyNote2)
                CaseNotesViewModel.LoadState.Failed ->
                    ErrorStateView("Couldn't load your notes", "Check your connection and try again.", viewModel::load)
                CaseNotesViewModel.LoadState.Loaded -> {
                    Text(caseTitle, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    OutlinedTextField(
                        value = viewModel.draft,
                        onValueChange = { viewModel.draft = it },
                        placeholder = { Text("Pearls, attending preferences, things to look up…") },
                        modifier = Modifier.fillMaxWidth().weight(1f).padding(bottom = 4.dp),
                    )
                    PrivacyNote(Modifier.padding(bottom = 16.dp))
                }
            }
        }
    }

    viewModel.errorMessage?.let { message ->
        AlertDialog(
            onDismissRequest = { viewModel.errorMessage = null },
            title = { Text("Couldn't save your notes") },
            text = { Text(message) },
            confirmButton = { TextButton(onClick = { viewModel.errorMessage = null }) { Text("OK") } },
        )
    }

    if (viewModel.phiFindings.isNotEmpty()) {
        val lines = viewModel.phiFindings.joinToString("\n") { finding ->
            "• ${finding.kind}: " + finding.matches.joinToString(", ") { "“$it”" }
        }
        AlertDialog(
            onDismissRequest = { viewModel.phiFindings = emptyList() },
            title = { Text("Patient Information Detected") },
            text = {
                Text(
                    "This note can't be saved because it may contain patient-identifying information:\n\n$lines\n\nRemove it and try again.",
                )
            },
            confirmButton = { TextButton(onClick = { viewModel.phiFindings = emptyList() }) { Text("OK") } },
        )
    }
}
