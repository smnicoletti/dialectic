# Dialectic teaching corpus

Status: progressive teaching exercises and bounded source records

Access and provenance were checked on 2026-07-30. No primary-source file is
retained in this repository. The records below contain bibliographic metadata,
stable links, passage boundaries, and original paraphrases/outlines written for
this project. They intentionally contain no quotation from the primary works.
Later corpus work must preserve edition-specific source spans and must not
silently replace them with these outlines.

## AQ-SECOND-WAY

- **Work and edition:** Thomas Aquinas, *Summa Theologiae*, Prima Pars,
  question 2, article 3, body of the article, Second Way. The Latin locator is
  Enrique Alarcón's Corpus Thomisticum transcription of the Leonine edition
  (Rome, 1888), record `[28318]`. An English cross-locator is the Fathers of
  the English Dominican Province translation, second revised edition (1920),
  Article 3, paragraphs headed "The second way."
- **Stable records:** [Corpus Thomisticum, ST I q. 2](https://www.corpusthomisticum.org/sth1002.html);
  [New Advent English cross-locator](https://www.newadvent.org/summa/1002.htm).
- **Access/retention:** Aquinas's work and the 1888/1920 editions are
  historical public-domain sources, but the linked digital presentations have
  their own terms. Store metadata and an original outline only; do not ingest
  either web page wholesale.
- **Passage boundary:** Begin with the transition to the Second Way in
  `[28318]`; end with the identification of a first efficient cause. Exclude
  the First and Third Ways and the replies to objections.
- **Original plain-language outline:** There is an ordered dependence among
  efficient causes. Nothing is an efficient cause of itself. The relevant
  causal ordering cannot lack a first member, because removing a first cause
  removes intermediate causes and their effects. Therefore a first efficient
  cause must be posited; the passage then identifies this with God.
- **Intended profile:** a future relational or causal profile with explicit
  meanings for `efficientCause` and `dependsOn`. The current `CoreLogic`
  fragment cannot encode the case's relational structure, so this record
  remains blocked rather than being compiled through a unary approximation.
- **Anticipated CNL features:** typed predicates, identity/non-self-causation,
  universal claims, contradiction, a named no-regress rule, supplied premises,
  definition/identification choices, and source links at clause level.
- **Likely alternatives:** temporal versus hierarchical readings of the causal
  order; alternative formulations of the no-infinite-regress premise; whether
  the final identification is a definition, supplied bridge, or conclusion.
  Each becomes a separately named reconstruction with a visible delta.

## EDU-CORROBORATED-TESTIMONY

- **Kind:** invented classroom scenario.
- **Exercise boundary:** five sentences about independently corroborated
  reports, responsible assessment, credibility, and prima facie warrant.
- **Plain-language outline:** Every independently corroborated report is
  responsibly assessed. Every responsibly assessed report is credible. Every
  credible report provides prima facie warrant. Therefore every independently
  corroborated report provides prima facie warrant.
- **Profile:** implemented `CoreLogic`. The exercise uses four unary predicates
  over reports and a two-step universal chain.
- **Learning focus:** vocabulary declaration, source-to-meaning alignment,
  intermediate claims, explicit deduction steps, and quantifier scope.
- **Alternative:** `LimitedCorroboration` changes the first universal premise
  to an existential claim. Lean then rejects the preserved deduction because
  its first step requires the universal premise. This rejection does not prove
  general non-entailment.
- **Executable status:** completed and draft forms are in
  `Dialectic/Examples/CorroboratedTestimony.lean` and
  `Dialectic/Examples/CorroboratedTestimonyDraft.lean`.

## RUS-DENOTING

- **Work and edition:** Bertrand Russell, "On Denoting," *Mind* 14(56)
  (1905), 479-493, especially pp. 485-486 on the present-King-of-France
  puzzle and the scope of negation.
- **Stable records:** [DOI 10.1093/mind/XIV.4.479](https://doi.org/10.1093/mind/XIV.4.479);
  [Wikisource transcription](https://en.wikisource.org/wiki/On_Denoting).
- **Access/retention:** The 1905 article is public domain in the United States.
  This test suite stores metadata and an original outline rather than a local
  copy or quotation.
- **Passage boundary:** Begin with the excluded-middle puzzle concerning the
  present King of France; include Russell's contrast between primary and
  secondary occurrence needed to distinguish readings; stop before the later
  discussion moves to other puzzles.
- **Original plain-language outline:** A sentence containing a definite
  description should not force the description to denote an object. Expanding
  the description into quantified conditions separates existence and
  uniqueness from predication. Moving negation across that quantified
  structure yields distinct readings rather than a single ambiguous formula.
- **Intended profile:** a future `ClassicalFOLDescriptions` profile with
  explicit existence, uniqueness, identity, scope, and a recorded classical
  meta-logic. Until that profile exists, the case should be `blocked`, not
  silently compiled under `CoreLogic`.
- **Anticipated CNL features:** definitions, quantifier scope, identity,
  existence/uniqueness, negation, alternative controlled meanings for one
  surface sentence, and profile-specific inference rules.
- **Likely alternatives:** narrow versus wide scope of negation;
  quantificational versus presuppositional treatment; whether existence and
  uniqueness are asserted, presupposed, or modeled as definedness conditions.

## EDU-ALGORITHMIC-ACCOUNTABILITY

- **Kind:** contemporary classroom scenario.
- **Exercise boundary:** three sentences connect automated decisions,
  high-impact decisions, and access to review.
- **Plain-language outline:** Every automated decision in the exercise is high
  impact. Every high-impact decision is reviewable. Therefore every automated
  decision is reviewable.
- **Profile:** implemented `CoreLogic`. The exercise uses three unary
  predicates over decisions and one universal-composition step.
- **Learning focus:** distinguish rejection of one preserved deduction from
  certified non-entailment. The finite countermodel uses two decisions because
  the existential alternative and the falsified universal conclusion need not
  concern the same decision.
- **Alternative:** `LimitedReviewPolicy` changes the universal review premise
  to an existential one. Lean rejects the preserved composition. A supplied
  two-decision model satisfies both alternative premises while falsifying the
  conclusion, so Lean also accepts finite non-entailment evidence.
- **Executable status:**
  `Dialectic/Examples/AlgorithmicAccountability.lean` contains the completed
  notebook. `Dialectic/Tests/AlgorithmicAccountability.lean` checks the four
  reported statuses.

## PLA-MODAL-ONTOLOGICAL

- **Work and edition:** Alvin Plantinga, *The Nature of Necessity* (Oxford:
  Clarendon Press, 1974), chapter 10.
- **Stable record:** [Oxford Academic,
  DOI 10.1093/0198244142.001.0001](https://doi.org/10.1093/0198244142.001.0001).
- **Access/retention:** The repository stores bibliographic metadata and
  original abstractions only. It does not retain the book text.
- **Passage boundary:** Chapter 10's modal ontological argument. The executable
  notebook isolates one box-modus-ponens-shaped subargument and excludes the
  S5-specific steps.
- **Original plain-language outline:** If maximal greatness necessarily
  entails existence, and the candidate is necessarily maximally great, then
  the candidate necessarily exists. Replacing the second premise with mere
  possibility blocks that deduction.
- **Intended profile:** implemented `ModalK`, with explicit worlds and
  accessibility. The example does not attribute K as the logic of Plantinga's
  full argument.
- **Anticipated CNL features:** necessity, possibility, profile-specific
  inference, an explicit alternative meaning, finite-model analysis, and an
  objection about modal strength.
- **Likely alternatives:** possibility versus necessity of maximal greatness;
  K versus stronger frame conditions; and different formal accounts of
  maximal greatness.
- **Executable status:**
  `Dialectic/Examples/ModalOntologicalArgument.lean` checks the bounded
  subargument and analyzes a declared finite K model.

## LEW-MATCH

- **Work and edition:** David Lewis, *Counterfactuals* (Blackwell, 1973),
  opening discussion, pp. 1-2.
- **Stable record:** [PhilPapers bibliographic
  record](https://philpapers.org/rec/LEWC-2).
- **Access/retention:** No book text is retained. The notebook uses an original
  match scenario for bibliographic orientation.
- **Passage boundary:** The opening discussion of counterfactual conditionals.
  The executable example does not reproduce Lewis's later system.
- **Original plain-language outline:** If a match were struck, it would light;
  if it lit, its flame would be visible; therefore, under one shared explicit
  selection of counterfactual situations, striking it would make the flame
  visible.
- **Intended profile:** the implemented bounded `Counterfactual` profile. It
  evaluates claims over author-declared selected situations and does not infer
  comparative similarity.
- **Anticipated CNL features:** an actual situation, selected counterfactual
  situations, object-relative facts, a visible consequence step, an
  alternative, and model analysis.
- **Likely alternatives:** whether the selected damp situation is relevant;
  whether the same selection supports both conditionals; and whether
  similarity should depend on the antecedent.
- **Executable status:** `Dialectic/Examples/CounterfactualMatch.lean`.

## Evaluation role

The invented scenarios are ready for interface practice. Published-source
records become classroom exercises after review of the edition-specific span
and human-authored reconstruction. Plantinga and Lewis have bounded executable
examples. Aquinas and Russell remain advanced design targets:

| Case | Positive implementation test | Required alternative or boundary test |
| --- | --- | --- |
| `AQ-SECOND-WAY` | Clause-level trace links and explicit supplied bridge premises | Compare two no-regress/identification readings; report all premise and definition deltas |
| `EDU-CORROBORATED-TESTIMONY` | **Implemented:** five linked claims and a two-step unary chain | **Implemented:** narrowing the first universal premise rejects the preserved term; no general non-entailment claim follows |
| `RUS-DENOTING` | Multiple controlled meanings attached to one surface sentence | Reject description/scope keywords outside the declared descriptions profile; compare narrow/wide scope reconstructions |
| `EDU-ALGORITHMIC-ACCOUNTABILITY` | **Implemented:** a universal reviewability bridge and a checked two-decision countermodel | Separate rejection of the preserved term from finite-model non-entailment evidence |
| `PLA-MODAL-ONTOLOGICAL` | **Implemented K-level subargument:** box modus ponens with visible premises | Record that Plantinga's full S5 reasoning lies outside the profile |
| `LEW-MATCH` | **Implemented bounded rule:** consequence over one declared selection | Record that Dialectic performs no similarity ordering or closest-situation search |

Synthetic cases for diagnostic branches remain under
`Dialectic/Tests/Fixtures/`. They are regression inputs, not public
philosophical examples or evidence about a historical author.

For every published-source exercise, acceptance requires:

1. exact source metadata and passage boundaries survive round-trip formatting;
2. every formal declaration traces through a controlled meaning to a source
   span or is visibly marked as supplied;
3. each reconstruction selects exactly one profile and rejects unavailable
   keywords/rules;
4. original and alternative reconstructions are checked in independent Lean
   local environments, even when authored in one notebook;
5. comparison reports enumerate paraphrase, meaning, interpretation,
   definition, supplied-assumption, and profile deltas;
6. `verified`, `incomplete`, and certified non-entailment are not conflated;
7. reviewers can mark a reconstruction contested without changing its Lean
   result.
