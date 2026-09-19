<h1 align="center">Dialectic</h1>

<p align="center"><strong>A Lean-native language for formal argument reconstruction</strong></p>

<p align="center">
  <a href="lean-toolchain"><img alt="Lean 4.32.1" src="https://img.shields.io/badge/Lean-4.32.1-0f4c81"></a>
  <a href="lakefile.lean"><img alt="Dialectic 0.1.0" src="https://img.shields.io/badge/Dialectic-0.1.0-555555"></a>
  <a href="https://marketplace.visualstudio.com/items?itemName=leanprover.lean4"><img alt="Standard Lean VS Code extension" src="https://img.shields.io/badge/editor-standard%20Lean%20VS%20Code-informational"></a>
</p>

Dialectic is a Lean language extension for reconstructing arguments. A notebook
keeps vocabulary, source sentences, controlled meanings, deduction steps,
revisions, and objections in one readable Lean file. Use the standard Lean
extension for VS Code. You do not write Lean terms or tactics.

> [!IMPORTANT]
> **Verification boundary.** Dialectic checks whether a deduction follows from
> the declared reconstruction and logic profile. It does not check whether the
> premises are true or whether a reconstruction is the best reading of a text.

## Prerequisites

Dialectic assumes basic familiarity with premises, conclusions, suppressed
assumptions, and alternative reconstructions. No Lean experience is required.

You need:

- Lean `4.32.1` through the project toolchain;
- VS Code or VSCodium with the standard **Lean 4** extension; and
- this repository opened at its root, where `lakefile.lean` is located.

## Quick start

Install [elan](https://github.com/leanprover/elan) if Lean is not already
available. Then clone and build Dialectic:

```sh
git clone https://github.com/smnicoletti/dialectic.git
cd dialectic
lake build
```

Open the repository root in VS Code or VSCodium. Install the standard **Lean 4**
extension if it is not installed. Then open
[`CorroboratedTestimonyDraft.lean`](Dialectic/Examples/CorroboratedTestimonyDraft.lean).

Place the cursor on `Continue deduction`. The Infoview shows the current
deduction state and one supported next move. Open the Quick Fix menu to insert
the proposed step. Lean checks the deduction after the edit.

The completed notebook is
[`CorroboratedTestimony.lean`](Dialectic/Examples/CorroboratedTestimony.lean).
Its source is an invented classroom scenario.

## Exercise progression

### 1. Declare vocabulary and source material

Every notebook declares its domain terms before it uses them:

```text
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
End source
```

The vocabulary section is mandatory. Dialectic reports undeclared terms and
incompatible uses at their source locations.

### 2. Choose a controlled meaning

The paraphrase remains readable prose. The `Formal meaning` line states the
precise interpretation used by the checker:

```text
Claim P1 from WorkshopScenario sentence 1
  Paraphrase "Every independently corroborated report is responsibly assessed."
  Formal meaning Every independentlyCorroborated report is responsiblyAssessed
End claim
```

Students can compare the prose with the quantifier and predicates chosen for
the controlled meaning. A later alternative can change that meaning explicitly.

### 3. Write a deduction with live guidance

A bare `Step` is a valid draft marker:

```text
Deduction TestimonyWarrant
  Step
End deduction
```

At this marker, the Infoview shows **Choose the next deduction step**. It lists
the declared claims and only the moves implemented by the selected profile.
The Quick Fix inserts an explicit goal and a complete controlled step. It never
inserts a Lean proof term.

After one accepted step, use `Continue deduction`:

```text
Deduction TestimonyWarrant
  Goal Conclusion
  Step CredibilityFollows
    From P1 and P2 conclude CredibilityBridge
  Continue deduction
End deduction
```

For this state, CoreLogic proposes:

```text
Step ConclusionFollows
  From CredibilityBridge and P3 conclude Conclusion
```

The proposed step becomes a checked result only after insertion and normal Lean
re-elaboration. If no implemented move applies, the panel offers no action.

### 4. Revise an assumption

An alternative reconstruction records its exact change and rechecks the same
deduction in a new environment:

```text
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
```

The change removes the universal premise required by the first step. Lean
rejects the preserved deduction under the alternative. This result concerns
that deduction term. It does not prove that no other deduction exists.

### 5. Interpret negative evidence

Dialectic keeps five outcomes separate:

| Result | What the result means |
| --- | --- |
| Preserved deduction rejected | The written deduction does not type-check under the alternative declarations. |
| Contradiction found | The implemented CoreLogic analysis built and checked a contradiction from named claims. |
| No contradiction found | The bounded analysis found no witness. This is not a consistency proof. |
| Conclusion not supported | A checked finite model satisfies the alternative assumptions while the conclusion is false. |
| Non-entailment not established | No accepted countermodel supports that conclusion. This is not an entailment proof. |

Synthetic cases for diagnostic branches live in `Dialectic/Tests/Fixtures/`.
They are tests, not public teaching examples.

## Reasoning profiles

Each reconstruction selects exactly one logic profile. The profile controls the
meaning phrases, formal semantics, deduction rules, and negative evidence that
Dialectic can check.

### CoreLogic

CoreLogic supports the current constructive unary fragment:

```text
Logic profile CoreLogic
  Description "constructive unary-predicate practice"
End logic

Formal meaning Every credible report is primaFacieWarranting
```

It checks explicit universal chains and a bounded set of existential and
negative unary forms. It can check named contradiction witnesses and
author-supplied finite unary countermodels.

### ModalK

ModalK uses explicit worlds and accessibility without extra frame conditions:

```text
Logic profile ModalK
  Description "normal modal K with an explicit finite model"
End logic

Formal meaning In every possible world candidate is maximallyGreat
Formal meaning In every possible world if candidate is maximallyGreat then candidate is existent
```

The current deduction rule is box modus ponens. Model analysis can find a
counterexample in the declared finite Kripke model. Dialectic does not assume
reflexivity, symmetry, transitivity, or Euclideanness, and it does not synthesize
models.

### Counterfactual

The Counterfactual profile distinguishes the actual situation from selected
counterfactual situations:

```text
Logic profile Counterfactual
  Description "bounded selected-situation reasoning"
End logic

Formal meaning If it were the case that thisMatch is struck, then thisMatch is lit
```

The profile checks one consequence rule over the same declared selection
relation. It does not infer which situations are closest, compare similarity,
or implement unrestricted Lewis or Stalnaker semantics.

## Implementation and validation

Dialectic is a Lean language extension. Its parser builds a controlled notebook
AST. The selected profile validates meanings and deduction forms. Lean then
elaborates the generated propositions and proof terms and sends source-located
messages to the standard Infoview.

Run the complete library and test suite:

```sh
lake build
```

The default target imports every public example and every Lean-native test.
Expected warnings show rejected alternatives; they do not indicate a failed
build.

The language-server regressions check the live widget and the versioned editor
action at `Step` and `Continue deduction`. The workspace edit targets only the
current marker range and includes the current document version.

Run both real language-server inputs with Lean's test runner:

```sh
lake env lean --run Dialectic/Tests/LanguageServerRunner.lean -p Dialectic/Tests/InteractiveCodeAction.lean
lake env lean --run Dialectic/Tests/LanguageServerRunner.lean -p Dialectic/Tests/InteractiveBareStepCodeAction.lean
```

## Project layout

```text
Dialectic/
  Examples/        # public argument notebooks
  Language/        # syntax, AST, profiles, checking, diagnostics, editor actions
  Tests/
    Fixtures/      # synthetic diagnostic inputs
    *.lean         # parser, semantics, diagnostic, and server regressions
Dialectic.lean     # default build target
DESIGN.md          # implementation and semantic design
CONTRIBUTING.md    # contribution requirements
```

## Current limits

- CoreLogic has one domain type and unary predicates.
- Vocabulary can record relations, but current CoreLogic deductions do not use them.
- ModalK supports box modus ponens and declared finite-model analysis.
- Counterfactual reasoning uses one declared selection relation.
- Dialectic does not search for arbitrary proofs or synthesize countermodels.
- Identity, nested quantifiers, general cases, definitions, replies, and further
  dialectical records remain planned extensions.

## Documentation

| Document | Purpose |
| --- | --- |
| [Design specification](DESIGN.md) | Grammar, semantics, architecture, diagnostics, and limits |
| [Contributing](CONTRIBUTING.md) | Development requirements and contacts |
