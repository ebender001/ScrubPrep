package dev.benderapps.scrubprep.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.StickyNote2
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.automirrored.outlined.Assignment
import androidx.compose.material.icons.outlined.FilterListOff
import androidx.compose.material.icons.outlined.SearchOff
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import dev.benderapps.scrubprep.model.ScrubCase
import dev.benderapps.scrubprep.ui.components.EmptyState
import dev.benderapps.scrubprep.ui.components.ScreenScaffold
import dev.benderapps.scrubprep.viewmodel.CaseSortOrder
import dev.benderapps.scrubprep.viewmodel.CasesListViewModel

/** Full case history list — the Home screen only shows the 5 most recent. */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CasesScreen(viewModel: CasesListViewModel, onOpenCase: (ScrubCase) -> Unit) {
    LaunchedEffect(viewModel) { viewModel.load() }

    ScreenScaffold(
        title = "Cases",
        actions = {
            if (viewModel.cases.isNotEmpty()) SortFilterMenu(viewModel)
        },
    ) {
        when {
            viewModel.isLoading && viewModel.cases.isEmpty() ->
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) { CircularProgressIndicator() }
            viewModel.cases.isEmpty() ->
                EmptyState("No cases yet", "Cases you prepare will show up here.", Icons.AutoMirrored.Outlined.Assignment)
            else -> Column(Modifier.fillMaxSize()) {
                OutlinedTextField(
                    value = viewModel.searchText,
                    onValueChange = { viewModel.searchText = it },
                    placeholder = { Text("Search cases") },
                    leadingIcon = { Icon(Icons.Filled.Search, contentDescription = null) },
                    trailingIcon = {
                        if (viewModel.searchText.isNotEmpty()) {
                            IconButton(onClick = { viewModel.searchText = "" }) {
                                Icon(Icons.Filled.Clear, contentDescription = "Clear search")
                            }
                        }
                    },
                    singleLine = true,
                    shape = CircleShape,
                    modifier = Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 4.dp),
                )

                val visibleCases = viewModel.visibleCases()
                PullToRefreshBox(
                    isRefreshing = viewModel.isLoading,
                    onRefresh = viewModel::load,
                    modifier = Modifier.fillMaxSize(),
                ) {
                    if (visibleCases.isEmpty()) {
                        if (viewModel.trimmedSearchText.isNotEmpty()) {
                            EmptyState("No results for “${viewModel.trimmedSearchText}”", "Check the spelling or try a new search.", Icons.Outlined.SearchOff)
                        } else {
                            EmptyState(
                                "No matching cases",
                                "No cases match the selected filters.",
                                Icons.Outlined.FilterListOff,
                                action = { TextButton(onClick = viewModel::clearFilters) { Text("Clear filters") } },
                            )
                        }
                    } else {
                        LazyColumn(contentPadding = PaddingValues(bottom = 16.dp)) {
                            items(visibleCases, key = { it.id }) { scrubCase ->
                                SwipeToDeleteRow(onDelete = { viewModel.delete(scrubCase) }) {
                                    CaseRow(scrubCase) { onOpenCase(scrubCase) }
                                }
                                HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
                            }
                        }
                    }
                }
            }
        }
    }

    viewModel.errorMessage?.let { message ->
        AlertDialog(
            onDismissRequest = { viewModel.errorMessage = null },
            title = { Text("Couldn't load your cases") },
            text = { Text(message) },
            confirmButton = { TextButton(onClick = { viewModel.errorMessage = null }) { Text("OK") } },
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SwipeToDeleteRow(onDelete: () -> Unit, content: @Composable () -> Unit) {
    val state = rememberSwipeToDismissBoxState()
    // The row leaves the list only once the server confirms the delete, so snap it back.
    LaunchedEffect(state.currentValue) {
        if (state.currentValue == SwipeToDismissBoxValue.EndToStart) {
            onDelete()
            state.reset()
        }
    }
    SwipeToDismissBox(
        state = state,
        enableDismissFromStartToEnd = false,
        backgroundContent = {
            Box(
                Modifier.fillMaxSize().background(MaterialTheme.colorScheme.error).padding(horizontal = 20.dp),
                contentAlignment = Alignment.CenterEnd,
            ) { Icon(Icons.Filled.Delete, contentDescription = "Delete", tint = MaterialTheme.colorScheme.onError) }
        },
    ) {
        Box(Modifier.background(MaterialTheme.colorScheme.background)) { content() }
    }
}

/** One Cases list row: prep title, then the created date (plus a note glyph) and specialty chip. */
@Composable
private fun CaseRow(scrubCase: ScrubCase, onClick: () -> Unit) {
    Column(
        Modifier.fillMaxWidth().clickableRow(onClick).padding(horizontal = 16.dp, vertical = 12.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(scrubCase.prep.title, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(formatDate(scrubCase), style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                if (scrubCase.hasNotes) {
                    Text("·", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    Icon(
                        Icons.AutoMirrored.Outlined.StickyNote2,
                        contentDescription = "Has notes",
                        modifier = Modifier.size(14.dp),
                        tint = MaterialTheme.colorScheme.onSurfaceVariant,
                    )
                }
            }
            scrubCase.specialty?.let { specialty ->
                Text(
                    specialty.name,
                    style = MaterialTheme.typography.labelSmall,
                    fontWeight = FontWeight.Medium,
                    maxLines = 1,
                    modifier = Modifier
                        .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.12f), CircleShape)
                        .padding(horizontal = 8.dp, vertical = 3.dp),
                )
            }
        }
    }
}

private fun Modifier.clickableRow(onClick: () -> Unit): Modifier = this.then(Modifier.clickable(onClick = onClick))

@Composable
private fun SortFilterMenu(viewModel: CasesListViewModel) {
    var expanded by remember { mutableStateOf(false) }
    Box {
        IconButton(onClick = { expanded = true }) {
            Icon(
                Icons.Filled.FilterList,
                contentDescription = "Sort and filter",
                tint = if (viewModel.isFiltering) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface,
            )
        }
        DropdownMenu(expanded = expanded, onDismissRequest = { expanded = false }) {
            MenuHeader("Sort by")
            CaseSortOrder.entries.forEach { order ->
                CheckItem(order.title, viewModel.sortOrder == order) { viewModel.updateSortOrder(order) }
            }
            if (viewModel.availableSpecialties.isNotEmpty()) {
                HorizontalDivider()
                MenuHeader("Specialty")
                CheckItem("All", viewModel.specialtyFilter == null) { viewModel.specialtyFilter = null }
                viewModel.availableSpecialties.forEach { specialty ->
                    CheckItem(specialty.name, viewModel.specialtyFilter == specialty.id) { viewModel.specialtyFilter = specialty.id }
                }
            }
            if (viewModel.anyCaseHasNotes) {
                HorizontalDivider()
                MenuHeader("Notes")
                CheckItem("Has notes", viewModel.hasNotesFilter) { viewModel.hasNotesFilter = !viewModel.hasNotesFilter }
            }
        }
    }
}

@Composable
private fun MenuHeader(text: String) {
    Text(
        text,
        style = MaterialTheme.typography.labelMedium,
        color = MaterialTheme.colorScheme.onSurfaceVariant,
        modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
    )
}

@Composable
private fun CheckItem(text: String, checked: Boolean, onClick: () -> Unit) {
    DropdownMenuItem(
        text = { Text(text) },
        trailingIcon = { if (checked) Icon(Icons.Filled.Check, contentDescription = "Selected") },
        onClick = onClick,
    )
}
