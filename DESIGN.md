# Dialectic: implementation contract

Status: Lean-native executable vertical slice with constructive first-order,
relational ModalK, and bounded Counterfactual profiles, plus source-located
deduction-state guidance and versioned editor actions.

## Purpose and verification boundary

The language gives students a readable practice environment for reconstructing
and comparing philosophical arguments. Lean verifies only the explicitly
declared deductive core.
Every reported result must preserve this boundary:

> Lean acceptance establishes derivability under the selected logic profile,
> vocabulary, meanings, and premises. It does not establish that the premises
> are true or that the paraphrase is historically or interpretively faithful.

An alternative reconstruction changes inspectable declarations. It does not
attack the validity of an already accepted Lean derivation. Original and
alternative environments are independently checked. A preserved deduction may
be non-typable after a change; this is not general non-derivability.

## Executable notebook contract

`Examples/CorroboratedTestimony.lean` is the primary CoreLogic teaching
notebook. Its source is an invented classroom exercise:

```text
Argument CorroboratedTestimony
Logic profile CoreLogic
  Description "constructive unary-predicate practice"
End logic

Vocabulary
  Type Report called report
  Predicate independentlyCorroborated describes Report
  Predicate responsiblyAssessed describes Report
  Predicate credible describes Report
  Predicate primaFacieWarranting describes Report
End vocabulary

Source WorkshopScenario
  Citation "Invented classroom scenario for Dialectic"
  Location "Corroborated-testimony exercise, sentences 1-5"
  Sentence 1 "Every report supported by independent sources is responsibly assessed."
  ...
End source

Reconstruction Original
  Claim P1 from WorkshopScenario sentence 1
    Paraphrase "Every independently corroborated report is responsibly assessed."
    Formal meaning Every independentlyCorroborated report is responsiblyAssessed
  End claim
  ...
  Deduction TestimonyWarrant
    Goal Conclusion
    Step CredibilityFollows
      From P1 and P2 conclude CredibilityBridge
    Step ConclusionFollows
      From CredibilityBridge and P3 conclude Conclusion
  End deduction
End reconstruction

Alternative LimitedCorroboration based on Original
  Change P1
    Original meaning Every independentlyCorroborated report is responsiblyAssessed
    Alternative meaning Some independentlyCorroborated report is responsiblyAssessed
  End change
  Recheck the same deduction TestimonyWarrant
  Objection ScopeOfCorroboration about P1
    Statement "The exercise may support one report without supporting the universal premise."
  End objection
End alternative
End argument
```

Both `Vocabulary` and `Source` are mandatory first-class AST nodes.
`Vocabulary` owns domain declarations and readable aliases used by controlled
meanings. `Source` owns citation, edition/location prose, and numbered source
units. Claims are rejected if either link is unresolved.

## Grammar sketch

```ebnf
argument       ::= "Argument" name logic vocabulary model? source reconstruction alternative
                   "End argument"
logic          ::= "Logic profile" name "Description" string "End logic"
vocabulary     ::= "Vocabulary" typeDecl objectDecl* predicateDecl* relationDecl*
                   "End vocabulary"
typeDecl       ::= "Type" name "called" noun
objectDecl     ::= "Object" name "is" typeName
predicateDecl  ::= "Predicate" name "describes" typeName
relationDecl   ::= "Relation" name "links" typeName "to" typeName
model          ::= "Model" name state+
                   accessibility? selection? "End model"
state          ::= ("Actual world" | "Possible world" |
                    "Actual situation" | "Counterfactual situation") name
                   groundFact+ ("End world" | "End situation")
groundFact     ::= objectName "is" ("not")? predicate
accessibility  ::= "Accessibility" (name "reaches" name)*
                   "End accessibility"
selection      ::= "Closest situations" (name "selects" name)+
                   "End closest situations"
source         ::= "Source" name "Citation" string "Location" string
                   sourceSentence+ "End source"
sourceSentence ::= "Sentence" number string
reconstruction ::= "Reconstruction" name claim+ deduction+ "End reconstruction"
claim          ::= "Claim" name "from" sourceName "sentence" number
                   "Paraphrase" string "Formal meaning" meaning "End claim"
meaning        ::= "Every" predicate noun "is" predicate
                 | "Every" predicate noun "is not" predicate
                 | "No" predicate noun "is" predicate
                 | "Some" predicate noun "is" predicate
                 | "Some" predicate noun "is not" predicate
                 | "In every possible world" object "is" predicate
                 | "In some possible world" object "is" predicate
                 | "In every possible world if" object "is" predicate
                   "then" object "is" predicate
                 | "If it were the case that" object "is" predicate ","
                   "then" object "is" ("not")? predicate
deduction      ::= completedDeduction | draftDeduction
completedDeduction ::= "Deduction" name ("Goal" claimName)? step+
                       "End deduction"
draftDeduction ::= "Deduction" name ("Goal" claimName)? step*
                   ("Step" | "Continue deduction") "End deduction"
step           ::= "Step" name "From" name "and" name "conclude" name
alternative    ::= "Alternative" name "based on" name change+
                   "Recheck the same deduction" name
                   (countermodel | modelAnalysis)? objection*
                   "End alternative"
change         ::= "Change" claimName "Original meaning" meaning
                   "Alternative meaning" meaning "End change"
countermodel   ::= "Countermodel" name "for" claimName
                   individual+ "End countermodel"
individual     ::= "Individual" name assignment+
assignment     ::= "Predicate" predicate ("holds" | "does not hold")
modelAnalysis  ::= "Analyze model" modelName "for" claimName
objection      ::= "Objection" name "about" targetName
                   "Statement" string "End objection"
```

## Architecture

```text
ordinary .lean notebook
        |
        v
SurfaceSyntax.lean  -- Lean parser categories and command
        |
        v
Frontend.lean       -- lossless document AST with Syntax references
        |
        +--> Command.lean validates profile, vocabulary, source, names, deltas
        +--> Diagnostic.lean assigns stable categories and Infoview presentation
        +--> DeductionState.lean derives profile-specific editing guidance
        +--> DeductionAction.lean exposes versioned standard-editor Quick Fixes
        |
        v
CoreLogic.lean      -- constructive first-order meaning/deduction semantics
ModalK.lean         -- relational possible-world meaning/deduction semantics
Counterfactual.lean -- bounded selected-situation meaning/deduction semantics
        |
        v
profile dispatch    -- exactly one profile per notebook
        |
        v
Lean TermElabM      -- fresh original or alternative local environment
        |
        v
elabTermEnsuringType -> Meta.check -> Meta.checkWithKernel
        |
        v
source-located infoview messages + stable Lean status definitions
        + standard-Infoview result and deduction-state panels
        + source-ranged, versioned LSP code actions
```

The preserved object is `Deduction` plus its ordered `DeductionStep` AST. It is
translated to fresh Lean term syntax and re-elaborated under each environment.
No already-elaborated `Expr` is transplanted between changed bindings, and no
custom typechecker substitutes for Lean.

ModalK and Counterfactual use a first-class neutral `Model` node. The
philosopher declares objects, states, ground facts, and the profile-specific
frame or selection structure. The author does not declare that model to be a
counterexample. `Analyze model M for C` asks the profile analyzer whether the
model satisfies every alternative premise while falsifying `C`. The analyzer
then lowers that result to a closed proposition:
the conjunction of every alternative premise with the negation of the target.
Lean elaborates the generated evidence and `Meta.checkWithKernel` checks it.
The analyzer currently classifies a declared finite model; it does not
synthesize a different model. The checker does not promote preserved-term
rejection to non-entailment; only independently accepted model evidence does
so. CoreLogic retains its explicit finite certificate path.

The shared document AST is profile-neutral. A logic profile determines:

1. accepted controlled meaning phrases;
2. their abstract syntax and well-formedness;
3. their Lean semantics;
4. allowed deduction constructs.

Three profiles are executable. `CoreLogic` maps the supported unary formulas to
constructive `Prop`, universal quantification, implication, negation, and
existence. Its implemented step is transitive composition of unary universal
rules. `ModalK` maps a proposition to `World → Prop`, interprets necessity and
possibility through the accessibility structure in `Model`, adds no frame
condition, and implements box modus ponens. Its current ground fragment names
one domain object explicitly:

```text
In every possible world candidate is maximallyGreat
In some possible world candidate is maximallyGreat
In every possible world if candidate is maximallyGreat then candidate is existent
```

The ModalK checker creates explicit world and accessibility bindings, lowers
the preserved step to fresh Lean term syntax, and invokes the same elaborator
and kernel pipeline used by CoreLogic. Modal contradiction checking is
reported as `notChecked`.

`Counterfactual` interprets
`If it were the case that object is P, then object is Q` at an actual situation
as: every selected situation which satisfies the ground antecedent also
satisfies the ground consequent. The author describes the actual and
counterfactual situations and records the selection as an interpretation. The
implemented consequence rule composes two such conditionals only under that
one shared relation. This is not material implication and does not implement
unrestricted Lewis/Stalnaker similarity semantics, rankings, nesting, or
closest-world search.

Later deontic, epistemic, causal, temporal, or
ethical profiles must have separate vocabularies and semantics.
Cross-profile proof mixing is forbidden.

## Editing-time deduction state

An unfinished deduction is explicit in the AST. A bare `Step` asks Dialectic
to offer supported next moves before the author has named a goal. A Quick Fix
replaces that marker with an explicit `Goal` and complete controlled step.
When a goal is already known, `Goal C` records it and `Continue deduction`
marks the point for guidance after zero or more complete steps. Both markers
carry source ranges. Normal Lean re-elaboration rebuilds the state after every
edit. The state contains the profile, deduction, optional target, source
references, accepted draft steps, and available moves.

Draft steps are not trusted from their surface form. When a draft contains
steps, the selected profile translates that prefix and asks Lean to elaborate
and kernel-check it against the prefix's last conclusion. Only an accepted
prefix contributes derived claims to later suggestions. A rejected prefix is
shown as requiring correction and produces no next-step action.

The suggestion relation mirrors the implemented fragment:

| Profile | Suggested move |
| --- | --- |
| `CoreLogic` | compose `Every A noun is B` with `Every B noun is C` or `Every B noun is not C` |
| `ModalK` | combine a boxed implication with the matching boxed antecedent |
| `Counterfactual` | compose two conditionals interpreted over the same declared selection relation |

No other move is proposed. In particular, an empty suggestion set is guidance
about this bounded rule set, not proof of non-entailment.

`DeductionAction.lean` stores each action payload in Lean's InfoTree at the
bare `Step` or `Continue deduction` range. A registered standard language-server
`CodeActionProvider` returns a `WorkspaceEdit` containing the current
`VersionedTextDocumentIdentifier`. The edit replaces only that marker with
the displayed controlled syntax. At a bare `Step`, the replacement adds an
explicit goal and a complete step. At `Continue deduction`, an intermediate
move retains the marker, while a move reaching `Goal` removes it. The resulting
completed block enters the ordinary checking path on re-elaboration. If the
document version has changed, the Lean client does not apply the stale edit.

The Infoview panel itself is read-only. Users invoke the action through VS
Code's standard Quick Fix menu at the marker. This avoids an editor-specific
JavaScript bridge while still providing a genuine one-action insertion path
with the stock Lean extension.

## Result model

The command materializes and tests separate values:

- `DeductionStatus.accepted`: Lean elaborated and kernel-checked the controlled
  steps against the declared target;
- `DeductionStatus.rejected`: those preserved steps are non-typable in that
  environment;
- `InconsistencyStatus.witnessed`: Lean accepted an explicit `False` proof from
  an existential witness and a zero-or-more-step universal-rule chain;
- `InconsistencyStatus.notWitnessed`: the implemented unary closure found no
  such witness; this is not a consistency theorem.
- `InconsistencyStatus.notChecked`: the selected profile has no implemented
  contradiction procedure; no consistency claim is made.
- `NonEntailmentStatus.certified`: reserved for Lean-checked model evidence or
  a complete approved procedure. For ModalK and Counterfactual, the analyzer
  derives the evidence proposition from the neutral `Model` section; Lean then
  checks that every alternative premise holds and the target fails. CoreLogic
  currently retains an explicit finite certificate;
- `NonEntailmentStatus.notEstablished`: no such certificate was produced.
  Rejection of a preserved term is not enough to promote this status.

`Tests/Fixtures/ConflictingInterpretation.lean` covers the direct
`.witnessed` branch. Its alternative changes `P2`, whereas
`AdmissibilityBridge` uses `P1` and `P3` in `DiscussionFollows`. The AST
dependency analysis therefore classifies the recheck as unaffected and reports
`This change does not affect this deduction.` The inconsistency panel is shown
first and states that the assumptions conflict independently of the accepted
deduction. `Tests/Fixtures/ChainedConflict.lean` exercises a two-rule closure and
records three participating claims in the kernel-checked `False` proof.
`Tests/Fixtures/SkepticalWarrant.lean` exercises a one-individual `.certified`
result; `Tests/Fixtures/PluralTestimony.lean` requires two individuals. In both
CoreLogic regression notebooks, the changed claim is a dependency of the
preserved deduction. Term rejection and countermodel acceptance therefore
remain distinct but relevant results. Dialectic claims neither countermodel
search nor a complete general non-entailment procedure.

### Negative-evidence capability matrix

| Profile/result | Positive evidence | Exact implemented boundary | Meaning of no result |
| --- | --- | --- | --- |
| CoreLogic inconsistency | Kernel-checked `False` term with participating claims | One existential premise; positive closure through arbitrary-length `everyIs` chains; `everyIsNot` applied at reachable predicates; only the four unary meaning constructors and premises not concluded by the selected deduction | No witness from this closure, not a consistency proof |
| CoreLogic non-entailment | Kernel-checked finite countermodel satisfying all alternative premises and falsifying the target | Nonempty author-supplied finite domain; every declared unary predicate assigned at every individual; no relations, multiple sorts, or search | No accepted certificate, not entailment |
| ModalK inconsistency | None | No contradiction procedure | No consistency judgment |
| ModalK non-entailment | Analyzer finds a counterexample in the declared finite Kripke model; Lean checks the generated evidence | One named object, an actual world, possible worlds, total ground valuations, and arbitrary accessibility; no frame laws or model synthesis | Declared model not a counterexample, not entailment |
| Counterfactual inconsistency | None | No contradiction procedure | No consistency judgment |
| Counterfactual non-entailment | Analyzer finds a selected situation where the target fails; Lean checks the generated evidence | One named object, actual/counterfactual situations, total ground valuations, and authored selection; no ranking, nesting, or model synthesis | Declared model not a counterexample, not entailment |

The CoreLogic closure is an implementation algorithm, not a Lean-formalized
soundness-and-completeness theorem. A future positive consistency result needs
either a checked model of the premises or a formally bounded decision
procedure with a proved completeness result. The staged non-entailment roadmap
is: bounded synthesis beyond the declared model; richer multi-sorted domains
and relation assignments; antecedent-indexed
counterfactual selection or rankings; then bounded profile-specific model
search. Each accepted countermodel must continue to be lowered to a
proposition and checked by Lean.

## Validation and diagnostics

Validation is source-located and precedes proof checking. It covers:

- exactly one executable profile (`CoreLogic`, `ModalK`, or `Counterfactual`);
- one declared type/readable noun alias in the current fragment;
- duplicate or undeclared objects, predicates, and relations;
- predicate domains and relation domain/range compatibility;
- controlled meanings using the declared noun and predicates;
- source identifiers and numbered sentence links;
- claim, deduction, step, delta, recheck, and objection targets;
- paired `Original meaning` matching the base reconstruction exactly;
- profile-specific model-analysis targets, unique named states, total
  non-duplicated ground assignments, valid edges, and exactly one actual world
  or situation.

Negative Lean tests exercise cross-profile keywords, missing source
locations, undeclared predicates, and incompatible noun aliases. Positive
tests exercise multi-step CoreLogic composition, a directly contradictory
and a chained contradictory CoreLogic alternative, one- and two-individual
finite countermodels, the corroborated-testimony exercise, ModalK box modus
ponens with finite Kripke model analysis, and bounded counterfactual
consequence with actual/selected-situation model analysis.

Dialectic messages have stable, human-readable categories rather than exposing
generated Lean errors as the product vocabulary:

| Category | Meaning |
| --- | --- |
| `PARSE`, `VOCAB`, `MODEL`, `PROFILE` | section/link, declaration, model, or selected-logic error |
| `DEDUCTION/STATE` | source-located unfinished deduction and editing guidance |
| `CHECK/ACCEPTED`, `CHECK/REJECTED` | original controlled deduction result |
| `RECHECK/ACCEPTED`, `RECHECK/REJECTED` | preserved deduction result in the alternative environment |
| `ALTERNATIVE/INCONSISTENCY` | Lean checked an explicit direct or chained contradiction |
| `ALTERNATIVE/CONSISTENCY-NOT-ESTABLISHED` | no general consistency claim is available |
| `NONENTAILMENT/CERTIFIED` | model analysis found premises true and target false, and Lean checked the generated evidence |
| `NONENTAILMENT/NOT-ESTABLISHED` | no accepted certificate or complete procedure was produced |
| `NONENTAILMENT/CERTIFICATE-REJECTED` | the displayed assignment failed its certificate obligation |
| `CAPABILITY` | source-located summary of checks available for the selected profile |
| `DELTA`, `INTERPRETIVE` | authored change and non-elaborated objection |

These categories cover validation and checking after Lean has parsed the
`Argument` command. Token-level failures that prevent construction of that
command are reported directly by Lean's parser with their native source
locations; Dialectic does not intercept or reclassify them.

`Diagnostic.lean` also saves a panel through Lean's built-in widget API. The
default view follows the semantic dependency:

1. the original reconstruction's deduction status;
2. the alternative reconstruction as a whole, with separate rows for
   assumptions considered together and the conclusion under those assumptions;
3. any positive contradiction witness or countermodel evidence; and
4. re-elaboration of the preserved deduction under the alternative.

This order keeps three results distinct. A contradiction witness concerns the
alternative premise set and need not arise from the preserved deduction. A
rejected preserved term establishes only non-typability of that term. A
Lean-checked countermodel establishes non-entailment because it satisfies all
alternative premises while falsifying the target. When neither positive result
exists, the widget displays the limited negative checks under a collapsed
explanation. Exact status constructors, deduction/target metadata, proof or
model evidence, and the elaborator/kernel check remain under `Technical
details`. The profile capability card is collapsed by default. Deltas and
objections follow the checking results.

The widget does not use one pass/fail color for all logical outcomes. Green
marks an accepted deduction. Purple with `⊭` marks Lean-checked negative
evidence. Red marks a witnessed contradiction, and amber marks rejection or
caution. The label and icon carry the meaning when color is unavailable.

The panel summarizes already-computed results in the standard VS Code
Infoview; it is not a proof oracle and neither reimplements typing nor changes
a kernel result.
Ordinary `logInfoAt`, `logWarningAt`, and `throwErrorAt` messages remain the
source-located compatibility baseline. `Tests/Diagnostics.lean` checks the
stable codes, accepted/rejected lifecycle messages, and exact relative source
ranges without matching Lean's rendered elaboration errors.
`Tests/EvidenceOutcomes.lean` checks the concise default copy separately from
the retained technical status and evidence fields.
`Tests/DeductionState.lean` checks CoreLogic, ModalK, and Counterfactual state
data; accepted and rejected draft-prefix behavior; source-range preservation;
exact controlled-step payloads; and versioned workspace edits.
`Tests/InteractiveCodeAction.lean` drives Lean's language-server test runner at
the continuation marker and checks the stock Quick Fix path.
`Tests/InteractiveBareStepCodeAction.lean` reproduces `Step` followed by
`End deduction` and asks the actual server for the panel widget and code
actions at that incomplete marker. `Tests/LanguageServerRunner.lean` provides
the executable entry point for both requests.

The implementation adopted three concepts after a read-only review of the
Paper24 UFO Lean diagnostics: keep explanation outside the trusted certificate
path, classify statuses on the Lean side before rendering, and pair a summary
panel with ordinary source-located messages. It did not copy Paper24's finite
table analyzer, diagnostic formula mirror, certificate-field workflow, or
JavaScript layout. Those mechanisms solve a different finite-model problem and
would blur Dialectic's narrower derivation/reconstruction boundary.

## Non-goals and extension points

This version does not verify premise truth, source accuracy, interpretive
fidelity, or general consistency. Its finite CoreLogic certificate can
establish particular non-entailment results but is not a search or decision
procedure. It does not yet implement binary-relation meanings, identity, nested quantifiers,
conjunction/disjunction cases, definitions, replies, exceptions, unresolved
questions, automatic model search, modal contradiction checking, stronger
frame systems, similarity rankings, antecedent-indexed selection, or nested
counterfactuals. Those belong in profile-specific AST and elaboration
extensions while retaining the shared
notebook sections.

No custom VS Code extension is required. Panels use Lean's built-in widget
mechanism, actions use the standard LSP code-action provider, and ordinary
source-located Lean messages remain the compatibility baseline.

## Pedagogical progression and evaluation

The exercises assume basic familiarity with premises, conclusions, and
alternative reconstructions, but no Lean experience. They progress through
vocabulary, source links, controlled meanings, explicit deduction steps, live
guidance, assumption revision, inconsistency, and countermodels. Alternative
reconstructions provide practice in exposing and comparing commitments.

The learning objectives are to identify the vocabulary of an argument, make
formal-meaning choices explicit, write named deductions, explain how a revision
changes a proof, and state the verification boundary correctly. These are
design objectives. The project has not measured student learning gains.

The records in `CORPUS.md` separate invented teaching scenarios from bounded
published-source exercises. Executable notebooks cover corroborated testimony,
an invented algorithmic-accountability case, a K-level modal subargument, and
a selected-situation counterfactual.
Aquinas and Russell remain advanced profile-design targets.

Future classroom evaluation must measure:

1. whether students can read a notebook without Lean syntax;
2. whether they can write and correct controlled meanings and deductions;
3. whether they can identify supplied premises and reconstruction deltas; and
4. whether they distinguish derivability, proof rejection, contradiction, and
   certified non-entailment.

Published-source exercises must preserve bibliographic provenance and passage
boundaries. Every exercise must identify supplied premises and modeling
choices. Profile-gated cases remain unavailable until their own semantics
exist; Dialectic never routes them through another profile.
