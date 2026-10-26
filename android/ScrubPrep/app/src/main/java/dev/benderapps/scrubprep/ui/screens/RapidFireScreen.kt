package dev.benderapps.scrubprep.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import dev.benderapps.scrubprep.model.QAPair
import dev.benderapps.scrubprep.model.PrepReference
import dev.benderapps.scrubprep.ui.components.AIContentNote
import dev.benderapps.scrubprep.ui.components.CardSurface
import dev.benderapps.scrubprep.ui.components.LoadingView
import dev.benderapps.scrubprep.ui.components.PrimaryButton
import dev.benderapps.scrubprep.ui.components.QuestionProgressHeader
import dev.benderapps.scrubprep.ui.components.ScreenScaffold
import dev.benderapps.scrubprep.ui.components.ScrollColumn
import dev.benderapps.scrubprep.ui.components.SecondaryButton
import dev.benderapps.scrubprep.ui.components.SecondaryText
import dev.benderapps.scrubprep.ui.theme.RapidYellow
import dev.benderapps.scrubprep.ui.theme.SuccessGreen
import dev.benderapps.scrubprep.viewmodel.RapidFireViewModel

/**
 * The Rapid Fire flow: exactly 5 high-yield question/answer pairs, one at a time — tap to
 * reveal the answer, then advance. No grading, no lengthy explanations, just a fast self-test
 * in the last two minutes before scrubbing in.
 */
@Composable
fun RapidFireScreen(viewModel: RapidFireViewModel, onBack: () -> Unit) {
    ScreenScaffold(title = "Rapid Fire", onBack = onBack) {
        val current = viewModel.currentQuestion
        when {
            viewModel.isLoading -> LoadingView(
                "Preparing your rapid fire…",
                listOf("Pulling the highest-yield questions", "Keeping it to five", "No lengthy explanations"),
            )
            current != null -> QuestionCard(
                qa = current,
                currentIndex = viewModel.currentIndex,
                totalCount = viewModel.questions.size,
                isAnswerRevealed = viewModel.isAnswerRevealed,
                isLastQuestion = viewModel.isLastQuestion,
                caseTitle = viewModel.prep.title,
                references = viewModel.prep.references,
                onReveal = viewModel::revealAnswer,
                onAdvance = viewModel::advance,
            )
            viewModel.isComplete -> CompletedView(
                questionCount = viewModel.questions.size,
                caseTitle = viewModel.prep.title,
                canGoAgain = viewModel.canGoAgain,
                onGoAgain = viewModel::restart,
                onDone = onBack,
            )
            else -> FailedView(viewModel.errorMessage, viewModel::load)
        }
    }
}

/** The per-question card — question, then (once revealed) the answer, then a button to advance. */
@Composable
private fun QuestionCard(
    qa: QAPair,
    currentIndex: Int,
    totalCount: Int,
    isAnswerRevealed: Boolean,
    isLastQuestion: Boolean,
    caseTitle: String,
    references: List<PrepReference>?,
    onReveal: () -> Unit,
    onAdvance: () -> Unit,
) {
    ScrollColumn {
        QuestionProgressHeader(currentIndex, totalCount, RapidYellow)

        CardSurface {
            Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Icon(Icons.Filled.Bolt, contentDescription = null, tint = RapidYellow, modifier = Modifier.size(18.dp))
                    Text(
                        "Question ${currentIndex + 1}",
                        style = MaterialTheme.typography.labelLarge,
                        fontWeight = FontWeight.SemiBold,
                        color = RapidYellow,
                    )
                }
                Text(qa.question, style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Medium)
                if (isAnswerRevealed) {
                    HorizontalDivider()
                    SecondaryText(qa.answer)
                }
            }
        }

        if (isAnswerRevealed) {
            PrimaryButton(if (isLastQuestion) "Finish" else "Next Question", onAdvance)
        } else {
            PrimaryButton("Reveal Answer", onReveal)
        }

        // Disclosure and references together as one "verify this" footer, so each question
        // leads the card.
        AIContentNote()
        PrepReferencesCard(caseTitle, references)
    }
}

/** Shown once every question in the round has been answered — "Go Again" or "Done". */
@Composable
private fun CompletedView(questionCount: Int, caseTitle: String, canGoAgain: Boolean, onGoAgain: () -> Unit, onDone: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.Filled.Verified, contentDescription = null, tint = SuccessGreen, modifier = Modifier.size(48.dp))
        Text("Ready to scrub.", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        SecondaryText("You reviewed $questionCount high-yield questions for $caseTitle.", Modifier)
        if (!canGoAgain) {
            Text(
                "That's the full ${RapidFireViewModel.MAX_TOTAL_QUESTIONS}-question review for this case.",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f),
                textAlign = TextAlign.Center,
            )
        }
        Column(Modifier.padding(horizontal = 16.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
            if (canGoAgain) {
                PrimaryButton("Go Again", onGoAgain)
                SecondaryButton("Done", onDone)
            } else {
                PrimaryButton("Done", onDone)
            }
        }
    }
}

/** Shown when Rapid Fire generation fails — offers a retry. */
@Composable
private fun FailedView(errorMessage: String?, onRetry: () -> Unit) {
    Column(
        Modifier.fillMaxSize().padding(24.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp, Alignment.CenterVertically),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        Icon(Icons.Filled.Warning, contentDescription = null, tint = androidx.compose.ui.graphics.Color(0xFFFF9500), modifier = Modifier.size(44.dp))
        Text("Couldn't generate this review", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.SemiBold)
        SecondaryText(errorMessage ?: "Please try again.", Modifier)
        Column(Modifier.padding(horizontal = 16.dp)) { PrimaryButton("Try Again", onRetry) }
    }
}
