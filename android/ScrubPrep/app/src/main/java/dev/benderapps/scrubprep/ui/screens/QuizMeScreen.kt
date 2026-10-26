package dev.benderapps.scrubprep.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.automirrored.filled.MenuBook
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.ui.text.input.KeyboardCapitalization
import dev.benderapps.scrubprep.model.PimpAssessment
import dev.benderapps.scrubprep.model.PimpDifficulty
import dev.benderapps.scrubprep.model.PimpSummary
import dev.benderapps.scrubprep.model.PimpTurn
import dev.benderapps.scrubprep.ui.components.AIContentNote
import dev.benderapps.scrubprep.ui.components.CardSurface
import dev.benderapps.scrubprep.ui.components.LoadingView
import dev.benderapps.scrubprep.ui.components.PrimaryButton
import dev.benderapps.scrubprep.ui.components.QuestionProgressHeader
import dev.benderapps.scrubprep.ui.components.ScreenScaffold
import dev.benderapps.scrubprep.ui.components.ScrollColumn
import dev.benderapps.scrubprep.ui.components.SecondaryButton
import dev.benderapps.scrubprep.ui.components.SecondaryText
import dev.benderapps.scrubprep.ui.components.SectionCard
import dev.benderapps.scrubprep.ui.theme.DangerRed
import dev.benderapps.scrubprep.ui.theme.QuizOrange
import dev.benderapps.scrubprep.ui.theme.SuccessGreen
import dev.benderapps.scrubprep.viewmodel.PimpMeViewModel
import dev.benderapps.scrubprep.viewmodel.PimpMeViewModel.Phase

/**
 * The interactive Quiz Me experience: pick a difficulty, then answer one question at a time
 * with feedback after each, ending in a readiness summary. Each difficulty can only be
 * completed once per case — completed ones are locked and shown with a checkmark; tapping
 * one reviews its saved transcript instead of restarting.
 */
@Composable
fun QuizMeScreen(viewModel: PimpMeViewModel, onBack: () -> Unit) {
    ScreenScaffold(title = "Quiz Me", onBack = onBack) {
        when (val phase = viewModel.phase) {
            Phase.PickingDifficulty ->
                if (viewModel.isLoadingCompletedDifficulties) {
                    LoadingView("Loading your progress…", emptyList())
                } else {
                    DifficultyPicker(viewModel)
                }
            Phase.Starting ->
                LoadingView("Starting your session…", listOf("Reviewing your prep", "Preparing the first question"))
            Phase.Answering, Phase.ReviewingFeedback -> QuizSession(viewModel)
            is Phase.Completed -> SummaryView(
                summary = phase.summary,
                prepTitle = viewModel.prep.title,
                allDifficultiesCompleted = viewModel.allDifficultiesCompleted,
                onChooseAnotherDifficulty = viewModel::backToDifficultyPicker,
                onDone = onBack,
            )
            is Phase.ReviewingTranscript -> TranscriptView(
                difficulty = phase.difficulty,
                transcript = phase.transcript,
                summary = phase.summary,
                prepTitle = viewModel.prep.title,
                onBack = viewModel::backToDifficultyPicker,
            )
        }
    }

    viewModel.errorMessage?.let { message ->
        AlertDialog(
            onDismissRequest = { viewModel.errorMessage = null },
            title = { Text("Couldn't continue") },
            text = { Text(message) },
            confirmButton = { TextButton(onClick = { viewModel.errorMessage = null }) { Text("OK") } },
        )
    }
}

/** The Quiz Me entry screen — pick a difficulty (or tap a completed one to review it) and start. */
@Composable
private fun DifficultyPicker(viewModel: PimpMeViewModel) {
    ScrollColumn {
        Text("Test me before I scrub.", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        SecondaryText("Interactive questions tailored to ${viewModel.prep.title}. Pick how tough you want it.")

        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
            PimpDifficulty.entries.forEach { level ->
                val isCompleted = level in viewModel.completedDifficulties
                DifficultyRow(
                    level = level,
                    isCompleted = isCompleted,
                    isSelected = !isCompleted && viewModel.difficulty == level,
                    onSelect = { viewModel.selectDifficulty(level) },
                )
            }
        }

        if (viewModel.allDifficultiesCompleted) {
            SecondaryText("You've completed every difficulty for this case. Tap any level above to review it.")
        } else {
            PrimaryButton("Start", viewModel::start)
        }

        // In the footer with the references, as on Rapid Fire — above the difficulty rows,
        // its tinted card read like another selectable option.
        AIContentNote()
        PrepReferencesCard(viewModel.prep.title, viewModel.prep.references)
    }
}

/** One difficulty row — locked with a checkmark once completed, otherwise selectable. */
@Composable
private fun DifficultyRow(level: PimpDifficulty, isCompleted: Boolean, isSelected: Boolean, onSelect: () -> Unit) {
    val background = when {
        isCompleted -> SuccessGreen.copy(alpha = 0.12f)
        isSelected -> MaterialTheme.colorScheme.primary.copy(alpha = 0.12f)
        else -> MaterialTheme.colorScheme.surfaceContainer
    }
    Row(
        Modifier
            .fillMaxWidth()
            .background(background, RoundedCornerShape(12.dp))
            .clickable(onClick = onSelect)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(level.displayName, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold)
            if (isCompleted) {
                Text("Completed — tap to review", style = MaterialTheme.typography.bodySmall, color = SuccessGreen)
            } else {
                SecondaryText(level.subtitle, Modifier)
            }
        }
        if (isCompleted) {
            Icon(Icons.Filled.Verified, contentDescription = "Completed", tint = SuccessGreen)
        } else if (isSelected) {
            Icon(Icons.Filled.CheckCircle, contentDescription = "Selected", tint = MaterialTheme.colorScheme.primary)
        }
    }
}

/** The active question/answer/feedback loop of a Quiz Me session. */
@Composable
private fun QuizSession(viewModel: PimpMeViewModel) {
    ScrollColumn(Modifier.imePadding()) {
        viewModel.progress?.let { QuestionProgressHeader(it.index, it.total, MaterialTheme.colorScheme.primary) }

        val turn = viewModel.lastTurn
        if (viewModel.phase == Phase.ReviewingFeedback && turn != null) {
            FeedbackCard(turn)
            PrimaryButton(
                text = if (viewModel.isFinalFeedback) "See Summary" else "Next Question",
                onClick = viewModel::continueToNextQuestion,
            )
        } else {
            CardSurface {
                Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        Icon(Icons.Filled.LocalFireDepartment, contentDescription = null, tint = QuizOrange, modifier = Modifier.padding(end = 2.dp))
                        Text("Question", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold, color = QuizOrange)
                    }
                    Text(viewModel.currentQuestion.orEmpty(), style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Medium)
                }
            }
            OutlinedTextField(
                value = viewModel.answerText,
                onValueChange = { viewModel.answerText = it },
                enabled = !viewModel.isSubmitting,
                placeholder = { Text("Type your answer") },
                minLines = 4,
                shape = RoundedCornerShape(12.dp),
                keyboardOptions = KeyboardOptions(capitalization = KeyboardCapitalization.Sentences, autoCorrectEnabled = false),
                modifier = Modifier.fillMaxWidth(),
            )
            PrimaryButton(
                text = "Submit",
                enabled = viewModel.answerText.isNotBlank(),
                isLoading = viewModel.isSubmitting,
                onClick = viewModel::submitAnswer,
            )
        }
    }
}

/** Feedback after submitting an answer — assessment, the question/answer, and the teaching point. */
@Composable
private fun FeedbackCard(turn: PimpTurn) {
    val (icon, tint) = when (turn.assessment) {
        PimpAssessment.Correct -> Icons.Filled.CheckCircle to SuccessGreen
        PimpAssessment.PartiallyCorrect -> Icons.Filled.Error to QuizOrange
        PimpAssessment.Incorrect -> Icons.Filled.Cancel to DangerRed
    }
    CardSurface {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(icon, contentDescription = null, tint = tint)
                Text(turn.assessment.label, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold, color = tint)
            }
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(turn.question, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                Text("Your answer: ${turn.answer}", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            LabeledText("Feedback", turn.feedback)
            LabeledText("Teaching Point", turn.teachingPoint)
        }
    }
}

@Composable
private fun LabeledText(label: String, text: String) {
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(label, style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold, color = MaterialTheme.colorScheme.onSurfaceVariant)
        Text(text, style = MaterialTheme.typography.bodyMedium)
    }
}

@Composable
private fun SummaryCards(summary: PimpSummary) {
    SectionCard("You're strong on", Icons.Filled.Verified, summary.strong)
    SectionCard("Review before you scrub", Icons.AutoMirrored.Filled.MenuBook, summary.review)
    SectionCard("Two-minute review", Icons.Filled.Schedule, summary.twoMinuteReview)
}

/** The end-of-session readiness summary, shown once every question in a difficulty has been answered. */
@Composable
private fun SummaryView(
    summary: PimpSummary,
    prepTitle: String,
    allDifficultiesCompleted: Boolean,
    onChooseAnotherDifficulty: () -> Unit,
    onDone: () -> Unit,
) {
    ScrollColumn {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text("Session Complete", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
            SecondaryText(prepTitle)
        }
        SummaryCards(summary)
        if (allDifficultiesCompleted) {
            PrimaryButton("Done", onDone)
        } else {
            PrimaryButton("Choose Another Difficulty", onChooseAnotherDifficulty)
            SecondaryButton("Done", onDone)
        }
    }
}

/** Read-only review of a previously-completed difficulty's saved transcript and summary. */
@Composable
private fun TranscriptView(
    difficulty: PimpDifficulty,
    transcript: List<PimpTurn>,
    summary: PimpSummary,
    prepTitle: String,
    onBack: () -> Unit,
) {
    ScrollColumn {
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Icon(Icons.Filled.Verified, contentDescription = null, tint = SuccessGreen)
                Text(
                    "${difficulty.displayName} — Completed",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.SemiBold,
                    color = SuccessGreen,
                )
            }
            SecondaryText(prepTitle)
        }
        transcript.forEach { FeedbackCard(it) }
        SummaryCards(summary)
        PrimaryButton("Back to Difficulties", onBack)
    }
}
