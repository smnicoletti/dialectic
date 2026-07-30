# Dialectic calibration corpus

Status: source-grounded implementation test suite, not settled translations

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
- **Intended profile:** `CoreLogic` v1 for the explicit quantified/relational
  skeleton, treating `efficientCause` and `dependsOn` as declared predicates
  and exposing every bridge principle as a supplied assumption. A later causal
  profile may be evaluated separately, never mixed into the same
  reconstruction.
- **Anticipated CNL features:** typed predicates, identity/non-self-causation,
  universal claims, contradiction, a named no-regress rule, supplied premises,
  definition/identification choices, and source links at clause level.
- **Likely alternatives:** temporal versus hierarchical readings of the causal
  order; alternative formulations of the no-infinite-regress premise; whether
  the final identification is a definition, supplied bridge, or conclusion.
  Each becomes a separately named reconstruction with a visible delta.

## GAL-SHIP

- **Work and edition:** Galileo Galilei, *Dialogo sopra i due massimi sistemi
  del mondo* (Florence: Giovanni Battista Landini, 1632), Second Day, the
  below-decks ship thought experiment. A familiar English cross-locator is
  Stillman Drake's *Dialogue Concerning the Two Chief World Systems*
  (University of California Press, 1953), pp. 186-187; no Drake text is
  retained.
- **Stable records:** [Smithsonian Libraries 1632 copy](https://library.si.edu/digital-library/book/dialogodigalileo00gali)
  (marked public domain/CC0 by the repository);
  [Open Library record OL51470791M](https://openlibrary.org/books/OL51470791M);
  [Stanford Encyclopedia of Philosophy, Galileo](https://plato.stanford.edu/entries/galileo/)
  for the historical/methodological context of shared uniform motion.
- **Access/retention:** The linked 1632 scan is identified by Smithsonian
  Libraries as free of copyright restrictions. This project nevertheless
  stores only metadata and an original outline. The 1953 translation is a
  location aid, not retained corpus text.
- **Passage boundary:** Second Day, Salviati's invitation to consider ordinary
  phenomena below decks on a large ship, through the comparison between rest
  and smooth uniform motion. Exclude the surrounding discussion of falling
  bodies and later objections.
- **Original plain-language outline:** Consider the listed trials inside the
  ship under the stipulated isolation and motion conditions. Trials satisfying
  those conditions have the same internal outcomes while the ship is at rest
  and while it moves uniformly without fluctuation. The reconstruction makes
  explicit a methodological bridge: matching internal outcomes do not
  discriminate those two conditions. Therefore the described trials do not
  distinguish rest from uniform shared motion within the stipulated setting.
- **Intended profile:** implemented `CoreLogic` for a unary abstraction of the
  methodological chain. `describedBelowDeck`, `satisfiesStipulations`,
  `sameInternalOutcome`, and `nonDiscriminating` are declared predicates over
  trials. The model does not encode trajectories, time, acceleration, causal
  laws, or a general theory of observational equivalence.
- **Anticipated CNL features:** cases, comparison of models, universal versus
  restricted quantification over observations, exceptions, idealizing
  assumptions, countermodels, and unresolved empirical questions.
- **Likely alternatives:** observational equivalence versus the stronger claim
  that motion is undetectable; which phenomena and observers are quantified
  over; whether closure, uniformity, and absence of external interaction are
  supplied premises or part of the modeled case.
- **Executable status:** implemented in
  `Dialectic/Examples/GalileoShip.lean` as a deliberately bounded
  unary-predicate reconstruction with five source-linked claims and a
  two-step deduction. The original composes the stipulation, shared-outcome,
  and non-discrimination bridges. `RestrictedStipulation` changes only the
  universal scope of the first premise to an existential reading; Lean then
  rejects only the preserved deduction term. This example does not formalize
  Galileo's full kinematics or establish a settled translation.

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

## GET-CASE-I

- **Work and edition:** Edmund L. Gettier, "Is Justified True Belief
  Knowledge?", *Analysis* 23(6) (1963), 121-123, DOI
  `10.1093/analys/23.6.121`.
- **Stable record:** [Oxford Academic publisher page](https://academic.oup.com/analysis/article-abstract/23/6/121/109949).
- **Access/retention:** The publisher page identifies the article as
  copyrighted and access-restricted. No article text, PDF, or quotation is
  retained. This record contains only bibliographic metadata, locations, and
  an original outline.
- **Passage boundary:** The two preliminary principles about fallible
  justification and justification preserved through known entailment on
  p. 121, together with Case I on pp. 121-122. Case II and subsequent
  literature are excluded from this unit.
- **Original plain-language outline:** A subject has strong justification for
  a claim that is in fact false. The subject validly infers a disjunction. An
  unrelated disjunct happens to be true, so the inferred belief is justified
  and true, while the case is presented as one in which the subject does not
  know the disjunction. This supplies a candidate counterexample to the
  sufficiency of justified true belief.
- **Intended profile:** `CoreLogic` v1 for the case skeleton, treating
  `justified`, `believes`, `true`, and `knows` as declared predicates and the
  two preliminary principles as explicit rules/assumptions. A future epistemic
  profile must be a separate reconstruction with its own semantics.
- **Anticipated CNL features:** named rules, disjunction introduction,
  counterexample witness, distinction between object-level truth and
  justification, supplied premises, interpretation notes, and a competing
  conclusion.
- **Likely alternatives:** whether closure of justification is a rule or
  premise; whether the false lemma is essential; whether the final
  not-knowledge judgment is formalized as a premise, conclusion, or
  dialectical annotation; later epistemic profiles for luck or defeasibility.
- **Executable status:** `Dialectic/Examples/GettierCounterexample.lean`
  implements a coarse unary abstraction of the justified-true-belief
  sufficiency claim. A finite individual makes the alternative premises true
  and the proposed knowledge conclusion false. The notebook records that it
  does not formalize Gettier's disjunction, justification closure, or a theory
  of knowledge.

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
  subargument and analyzes a declared finite K model. It is an inspired
  reconstruction, not a transcription of Plantinga's proof.

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

These records become evaluation cases only after an edition-specific source
span and a human-authored reconstruction are reviewed. None is a canonical
philosophical translation. Galileo, Gettier, Plantinga, and Lewis now have
bounded executable examples. Aquinas and Russell remain design targets:

| Case | Positive implementation test | Required alternative or boundary test |
| --- | --- | --- |
| `AQ-SECOND-WAY` | Clause-level trace links and explicit supplied bridge premises | Compare two no-regress/identification readings; report all premise and definition deltas |
| `GAL-SHIP` | **Implemented subset:** five source-linked claims and a two-step unary methodological chain | **Implemented:** narrowing the scope of the stipulation premise rejects the preserved term; kinematics and general observational equivalence remain unformalized |
| `RUS-DENOTING` | Multiple controlled meanings attached to one surface sentence | Reject description/scope keywords outside the declared descriptions profile; compare narrow/wide scope reconstructions |
| `GET-CASE-I` | **Implemented abstraction:** a justified-true-belief bridge and a checked finite counterexample | Keep epistemic predicates uninterpreted in `CoreLogic`; require a separate reconstruction for any epistemic profile |
| `PLA-MODAL-ONTOLOGICAL` | **Implemented K-level subargument:** box modus ponens with visible premises | Record that Plantinga's full S5 reasoning lies outside the profile |
| `LEW-MATCH` | **Implemented bounded rule:** consequence over one declared selection | Record that Dialectic performs no similarity ordering or closest-situation search |

Synthetic cases for diagnostic branches remain under
`Dialectic/Tests/Fixtures/`. They are regression inputs, not public
philosophical examples or evidence about a historical author.

For every evaluation case, acceptance requires:

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
