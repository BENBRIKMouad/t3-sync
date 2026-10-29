---
name: summarize-educational-content
description: "Pedagogical summarization engine for educational materials including lectures, video transcripts, textbooks, research papers, course slides, and online tutorials. Transforms complex educational content into high-yield study guides, Cornell notes, Feynman-style concept breakdowns, active recall flashcards, and self-test quizzes."
---

# Educational Content Summarizer

A specialized skill to transform educational materials into structured, pedagogically sound study assets that maximize comprehension, retention, and rapid review.

---

## When to Use This Skill

Activate this skill whenever processing:
- **Lecture Transcripts & Video Transcripts**: Recorded classes, MOOCs (Coursera, edX), YouTube educational lectures, seminar presentations.
- **Textbook Chapters & Excerpts**: Heavy conceptual literature, academic treatises, technical chapters.
- **Academic & Research Papers**: Scientific literature, case studies, conference publications.
- **Course Slides & Syllabus Units**: High-level lecture decks that require explanatory expansion.
- **Technical & Practical Tutorials**: Step-by-step educational documentation and concept walkthroughs.

**Do NOT use for:**
- Generic non-educational business memos or executive summaries (unless educational training is the subject).
- Creative fiction or literary review (unless literary analysis for educational coursework).
- Code diffs / PR reviews without pedagogical context.

---

## Summarization Modes

Depending on user intent or request context, produce output tailored to one of four primary educational modes (defaulting to **Comprehensive Study Guide** if unspecified):

| Mode | Best For | Output Format |
| :--- | :--- | :--- |
| **1. Comprehensive Study Guide** *(Default)* | In-depth study, test preparation, complete conceptual mastery | Overview + Deep Concept Breakdown + Analogies + Misconceptions + Self-Test |
| **2. High-Yield Revision Sheet** | Quick review, 15-minute pre-exam cram, cheat sheet | Key formulas, laws, definition bullets, and critical distinctions |
| **3. Cornell Notes** | Organized course note-taking, structured lecture synthesis | Cue Column (questions/keywords) + Note Column + Bottom Summary |
| **4. Active Recall & Flashcard Deck** | Spaced repetition, Anki export, self-assessment | Q&A pairs, cloze deletions, concept discrimination challenges |

---

## Pedagogical Processing Workflow

Follow these 5 steps when generating any educational summary:

```
[1. Ingest & Calibrate] ──> [2. Extract Core Architecture] ──> [3. Formulate Explanations] ──> [4. Highlight Pitfalls] ──> [5. Build Active Recall]
```

### 1. Ingest & Calibrate
- **Identify Audience Level**: Determine the target level (Beginner/Introductory, Intermediate/Undergraduate, Advanced/Specialist).
- **Identify Prerequisites**: Note what background knowledge the student needs before tackling this material.
- **State the Big Idea (Thesis)**: Formulate in 1–2 sentences what fundamental problem this material solves or what fundamental truth it explains.

### 2. Extract Core Architecture
- Identify the 3–7 primary thematic pillars or milestones of the content.
- Filter out conversational filler, administrative announcements, repetitive tangents, and rhetorical warm-ups from transcripts.
- Preserve technical precision: keep formal notation, mathematical formulas, and domain-specific terminology intact.

### 3. Formulate Explanations (The Feynman Method)
- For every abstract or difficult concept:
  1. **Formal Definition**: The academically rigorous definition.
  2. **Plain English Translation**: How to explain it to a novice.
  3. **Intuitive Analogy or Real-World Model**: Concrete metaphor grounded in everyday experience.
  4. **Example / Application**: A concrete working example or derivation.

### 4. Highlight Pitfalls & Common Misconceptions
- Explicitly identify where learners routinely get confused, make mistakes, or conflate two similar terms (e.g., *Mass vs. Weight*, *Concurrency vs. Parallelism*, *Type I vs. Type II error*).
- Provide clear disambiguation.

### 5. Build Active Recall & Self-Assessment
- Generate 3–5 targeted review questions spanning Bloom's Taxonomy:
  - *Remember / Understand*: Recall key definitions or mechanisms.
  - *Apply / Analyze*: Solve a scenario or identify differences.
  - *Evaluate / Synthesize*: Explain why or design an application.
- Provide collapsible or clearly separated answer keys with explanations.

---

## Standard Output Format (Comprehensive Study Guide)

Unless the user explicitly requests another format (e.g. Cornell Notes or Flashcards), format the output using the following markdown structure:

```markdown
# 📚 [Topic / Lecture Title] - Educational Study Guide

> **Core Thesis**: [1-2 sentences summarizing the overarching insight/purpose]  
> **Prerequisites**: [Key knowledge expected of the learner]  
> **Target Mastery**: [What the learner will be able to do/explain after reviewing]

---

## 🧭 Concept Architecture & Big Picture
- **Why this matters**: [Context and real-world relevance]
- **Core Pillars**:
  1. [Pillar 1]
  2. [Pillar 2]
  3. [Pillar 3]

---

## 🔍 Detailed Concept Breakdown

### 1. [Concept Name]
- **Formal Definition**: [Precise definition]
- **Intuitive Explanation**: [Plain-English breakdown]
- **💡 Intuitive Analogy**: [Relatable metaphor]
- **Mechanism / How It Works**:
  1. Step 1 ...
  2. Step 2 ...
- **Key Equation / Formula / Rule** (if applicable):
  $$\text{Equation}$$
  *Where:*
  - Variable $x$ = ...
- **Practical Example**: [Walkthrough of a scenario or case]

---

## ⚠️ Common Misconceptions & Pitfalls
| Common Confusion / Error | Why It's Wrong | The Correct Mental Model |
| :--- | :--- | :--- |
| [Misconception 1] | [Explanation] | [Correction] |
| [Misconception 2] | [Explanation] | [Correction] |

---

## 🧠 Active Recall & Knowledge Check
Test your understanding without looking at the notes above:

1. **[Question 1 - Conceptual]**: ...
2. **[Question 2 - Application / Scenario]**: ...
3. **[Question 3 - Comparative / Analytical]**: ...

<details>
<summary><b>Click to Reveal Answer Key & Explanations</b></summary>

1. **Answer 1**: [Detailed explanation]
2. **Answer 2**: [Detailed explanation]
3. **Answer 3**: [Detailed explanation]

</details>

---

## 🚀 Key Takeaways & Further Study
- **The 3 Golden Rules**:
  1. [Rule 1]
  2. [Rule 2]
  3. [Rule 3]
- **Recommended Next Topics**: [Natural continuation]
```

---

## Specialized Templates Reference

When alternative formats are needed, refer to the guides in [`references/templates.md`](file:///C:/Users/mouad_benbrik/.t3/scratch/2026-10-28-i-want-to-make-skill-61d25cdf/.agents/skills/summarize-educational-content/references/templates.md):
- **Cornell Notes Template**: Two-column layout with cue keywords, structured bullet notes, and 2-sentence summary.
- **High-Yield Revision / Cheat Sheet**: High-density reference for formulas, definitions, and cheat sheets.
- **Flashcard Deck Template**: Ready-to-copy format compatible with Anki, Quizlet, or Markdown study cards.

---

## Quality Checklist

Before finalizing any educational summary, verify:
- [ ] **Did I strip transcript noise?** (Removed filler, pleasantries, slide administration).
- [ ] **Are definitions distinct from analogies?** (Provided both rigorous terms and intuitive metaphors).
- [ ] **Are mathematical/technical formulations preserved?** (No hand-waving on critical formulas or mechanisms).
- [ ] **Is cognitive load controlled?** (Used tables, bold keywords, and concise lists rather than walls of text).
- [ ] **Are active recall questions provided?** (Included test questions to stimulate retention).
