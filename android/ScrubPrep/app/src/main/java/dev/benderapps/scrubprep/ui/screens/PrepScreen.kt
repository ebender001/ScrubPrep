package dev.benderapps.scrubprep.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.StickyNote2
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.outlined.AccessibilityNew
import androidx.compose.material.icons.automirrored.outlined.Chat
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material.icons.automirrored.outlined.HelpOutline
import androidx.compose.material.icons.automirrored.outlined.MenuBook
import androidx.compose.material.icons.outlined.Schedule
import androidx.compose.material.icons.outlined.Star
import androidx.compose.material.icons.outlined.Visibility
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import dev.benderapps.scrubprep.model.ORPrep
import dev.benderapps.scrubprep.model.PrepReference
import dev.benderapps.scrubprep.model.QAPair
import dev.benderapps.scrubprep.learn.LearnSource
import dev.benderapps.scrubprep.ui.components.AIContentNote
import dev.benderapps.scrubprep.ui.components.CardSurface
import dev.benderapps.scrubprep.ui.components.CardTitle
import dev.benderapps.scrubprep.ui.components.LearnSourceRow
import dev.benderapps.scrubprep.ui.components.PrimaryButton
import dev.benderapps.scrubprep.ui.components.ScreenScaffold
import dev.benderapps.scrubprep.ui.components.ScrollColumn
import dev.benderapps.scrubprep.ui.components.SecondaryButton
import dev.benderapps.scrubprep.ui.components.SecondaryText
import dev.benderapps.scrubprep.ui.components.SectionCard
import java.net.URLEncoder

/** The scrollable OR Prep display — concise enough to review in ~10-15 minutes. */
@Composable
fun PrepScreen(
    caseDescription: String,
    prep: ORPrep,
    onBack: () -> Unit,
    onQuizMe: () -> Unit,
    onRapidFire: () -> Unit,
) {
    var isShowingNotes by remember { mutableStateOf(false) }

    ScreenScaffold(
        title = "",
        onBack = onBack,
        actions = {
            IconButton(onClick = { isShowingNotes = true }) {
                Icon(Icons.AutoMirrored.Outlined.StickyNote2, contentDescription = "My Notes")
            }
        },
    ) {
        ScrollColumn {
            // Shown here, where it can wrap, instead of in the app bar — long procedure
            // names (e.g. "Thrombectomy for Acute Limb Ischemia") truncate there.
            Text(prep.title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.Bold)
            SecondaryText(prep.caseSummary)

            AIContentNote()
            PrepReferencesCard(operationTitle = prep.title, references = prep.references)

            SectionCard("Why are we operating?", Icons.AutoMirrored.Outlined.HelpOutline, prep.whyOperating)
            SectionCard("Anatomy I need to know", Icons.Outlined.AccessibilityNew, prep.anatomy)
            SectionCard("Operation in 60 seconds", Icons.Outlined.Schedule, prep.operationOverview)
            SectionCard("What should I watch for?", Icons.Outlined.Visibility, prep.thingsToWatch)
            SectionCard("What could go wrong?", Icons.Outlined.ErrorOutline, prep.complications)
            SectionCard("Know these 5 things", Icons.Outlined.Star, prep.mustKnow)

            if (prep.likelyQuestions.isNotEmpty()) PrepLikelyQuestionsCard(questions = prep.likelyQuestions)

            Column(Modifier.padding(top = 8.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
                PrimaryButton("Quiz Me", onQuizMe, icon = Icons.Filled.LocalFireDepartment)
                SecondaryButton("Rapid Fire", onRapidFire, icon = Icons.Filled.Bolt)
                SecondaryButton("My Notes", { isShowingNotes = true }, icon = Icons.AutoMirrored.Outlined.StickyNote2)
            }
        }
    }

    if (isShowingNotes) {
        CaseNotesSheet(caseDescription = caseDescription, caseTitle = prep.title, onDismiss = { isShowingNotes = false })
    }
}

/**
 * The "Likely questions" card at the bottom of an OR Prep — omitted entirely when the prep
 * has none. Also reused by Learn reference screens under their own [title].
 */
@Composable
fun PrepLikelyQuestionsCard(questions: List<QAPair>, modifier: Modifier = Modifier, title: String = "Likely questions") {
    CardSurface(modifier) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            CardTitle(title, Icons.AutoMirrored.Outlined.Chat)
            questions.forEach { qa ->
                Column(Modifier.padding(vertical = 2.dp), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                    Text(qa.question, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Medium)
                    SecondaryText(qa.answer)
                }
            }
        }
    }
}

/**
 * "References for this operation" — the prep's verified StatPearls references (real articles
 * the backend found through NCBI), or, when there are none (older saved cases, or no
 * StatPearls article fits), searches of the NCBI Bookshelf and PubMed review articles.
 */
@Composable
fun PrepReferencesCard(operationTitle: String, references: List<PrepReference>?, modifier: Modifier = Modifier) {
    CardSurface(modifier) {
        Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            CardTitle("References for this operation", Icons.AutoMirrored.Outlined.MenuBook)
            if (!references.isNullOrEmpty()) {
                references.forEach { LearnSourceRow(LearnSource(it.title, it.source, it.url)) }
            } else {
                // `null` means this prep was never looked up (saved before references
                // existed); empty means a lookup ran and found no StatPearls match.
                Text(
                    if (references == null) "Search these sources for this operation:"
                    else "No StatPearls article matched this case. Search these sources instead:",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                )
                LearnSourceRow(
                    LearnSource(
                        "Search medical textbooks",
                        "NCBI Bookshelf, including StatPearls",
                        "https://www.ncbi.nlm.nih.gov/books/?term=${encode(operationTitle)}",
                    ),
                )
                LearnSourceRow(
                    LearnSource(
                        "Search review articles",
                        "PubMed, National Library of Medicine",
                        "https://pubmed.ncbi.nlm.nih.gov/?term=${encode(operationTitle)}&filter=pubt.review",
                    ),
                )
            }
        }
    }
}

// Searches are built from the operation's title, so they're always on topic and can't be a
// fabricated citation.
private fun encode(text: String): String = URLEncoder.encode(text, "UTF-8")
