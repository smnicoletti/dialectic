<h1 align="center">Dialectic</h1>

<p align="center"><strong>A Lean-native controlled language for reconstructing philosophical arguments</strong></p>

<p align="center">
  <a href="lean-toolchain"><img alt="Lean 4.32.1" src="https://img.shields.io/badge/Lean-4.32.1-0f4c81"></a>
  <a href="lakefile.lean"><img alt="Dialectic 0.1.0" src="https://img.shields.io/badge/Dialectic-0.1.0-555555"></a>
  <a href="LICENSE"><img alt="AGPL-3.0-or-later" src="https://img.shields.io/badge/license-AGPL--3.0--or--later-blue"></a>
  <a href="https://marketplace.visualstudio.com/items?itemName=leanprover.lean4"><img alt="Standard Lean VS Code extension" src="https://img.shields.io/badge/editor-standard%20Lean%20VS%20Code-informational"></a>
</p>

<p align="center">
  <a href="#quick-start">Quick start</a> ·
  <a href="#reasoning-profiles">Reasoning profiles</a> ·
  <a href="#philosophical-examples">Philosophical examples</a> ·
  <a href="#alternatives-objections-and-negative-evidence">Diagnostics</a> ·
  <a href="CONTRIBUTING.md">Contributing</a>
</p>

Dialectic notebooks keep source provenance, paraphrases, controlled formal
meanings, deductions, alternatives, and objections in one readable Lean file.
The standard Lean extension parses the notebook and reports source-located
results in the VS Code Infoview.

> [!IMPORTANT]
> **Verification boundary.** Dialectic verifies derivability under the selected
> reconstruction and logic profile. It does not verify premise truth,
> translation accuracy, or historical and interpretive fidelity.

| Author writes | Dialectic checks | Reader sees |
| --- | --- | --- |
| Source-linked claims, controlled meanings, and named deduction steps | Lean elaboration and kernel checking under one declared profile | Accepted deductions, explicit deltas, recheck results, and bounded negative evidence |

```text
Source passage → Paraphrase → Controlled meaning → Lean check → Infoview result
                       ↘ Interpretation choices and objections remain visible
```

## Quick start

1. Install [Elan](https://github.com/leanprover/elan) and the standard Lean 4
   VS Code extension.
2. Open this directory as the VS Code folder. `lean-toolchain` pins Lean
   4.32.1.
3. Open one of the notebooks in `Dialectic/Examples/`.

No Python program, external parser, generated Lean file, or custom editor
extension is required.

To check the complete project from a terminal:

```sh
lake build
```

## Notebook structure

Every notebook has one logic profile and the following parsed sections:

```text
import Dialectic.Language

Argument GalileoShip

Logic profile CoreLogic
  Description "constructive unary reasoning"
End logic

Vocabulary
  Type Trial called trial
  Predicate describedBelowDeck describes Trial
  Predicate satisfiesStipulations describes Trial
End vocabulary

Source GalileoShipPassage
  Citation "Galileo Galilei, Dialogue, Second Day; original paraphrases"
  Location "the enclosed below-decks ship comparison"
  Sentence 1 "The described trials satisfy the stipulated conditions."
  Sentence 2 "Trials satisfying those conditions have matching internal outcomes."
End source

Reconstruction Original
  ...
End reconstruction

Alternative RestrictedStipulation based on Original
  ...
End alternative

End argument
```

`Vocabulary` declares the domain type, its readable noun, named objects, and
predicates. `Source` records provenance and numbered sentences. A `Claim`
connects one source sentence to a paraphrase and a controlled formal meaning.
Lean reports undeclared vocabulary, wrong domains, missing source locations,
and profile-specific syntax at the relevant source range.

## Reasoning profiles

Each reconstruction selects exactly one profile. Dialectic never transfers a
deduction silently between profiles.

| Profile | Implemented argument form | Negative evidence |
| --- | --- | --- |
| `CoreLogic` | Constructive unary universal chains and existential claims | Chained contradiction witnesses and finite unary countermodels supplied in the notebook |
| `ModalK` | Box modus ponens over an explicit finite Kripke model | Analysis of the declared model; no frame conditions or model synthesis |
| `Counterfactual` | A bounded consequence rule over selected counterfactual situations | Analysis of declared actual and counterfactual situations; no similarity search |

### CoreLogic

The Galileo example composes two visible universal steps:

```text
Claim P1 from GalileoShipPassage sentence 1
  Paraphrase "Every described below-decks trial satisfies the stipulations."
  Formal meaning Every describedBelowDeck trial is satisfiesStipulations
End claim

Claim P2 from GalileoShipPassage sentence 2
  Paraphrase "Every stipulated trial has the same internal outcome."
  Formal meaning Every satisfiesStipulations trial is sameInternalOutcome
End claim

Claim DescribedOutcome from GalileoShipPassage sentence 4
  Paraphrase "Every described trial has the same internal outcome."
  Formal meaning Every describedBelowDeck trial is sameInternalOutcome
End claim

Deduction ShipComparison
  Step OutcomeBridge
    From P1 and P2 conclude DescribedOutcome
  Step DiscriminationBridge
    From DescribedOutcome and P3 conclude Conclusion
End deduction
```

The supported meanings are:

```text
Every A noun is B
Every A noun is not B
No A noun is B
Some A noun is B
Some A noun is not B
```

An alternative gives an explicit semantic delta and rechecks the preserved
deduction:

```text
Alternative RestrictedStipulation based on Original
  Change P1
    Original meaning Every describedBelowDeck trial is satisfiesStipulations
    Alternative meaning Some describedBelowDeck trial is satisfiesStipulations
  End change

  Recheck the same deduction ShipComparison
End alternative
```

Rejection means that these deduction steps no longer type-check under the
alternative declarations. It does not show that the conclusion has no other
proof.

Complete CoreLogic examples:

- [`GalileoShip.lean`](Dialectic/Examples/GalileoShip.lean), a bounded
  reconstruction of Galileo's below-decks ship argument;
- [`GettierCounterexample.lean`](Dialectic/Examples/GettierCounterexample.lean),
  a coarse reconstruction of the justified-true-belief analysis and a finite
  counterexample.

### ModalK

Modal vocabulary describes domain objects. Worlds and accessibility belong to
the model:

```text
Vocabulary
  Type Being called being
  Object candidate is Being
  Predicate maximallyGreat describes Being
  Predicate existent describes Being
End vocabulary

Model OntologicalReading
  Actual world actual
    candidate is not maximallyGreat
    candidate is not existent
  End world
  Possible world greatWorld
    candidate is maximallyGreat
    candidate is existent
  End world
  Accessibility
    actual reaches greatWorld
  End accessibility
End model
```

Modal claims use profile-gated phrases:

```text
Formal meaning In every possible world if candidate is maximallyGreat then candidate is existent
Formal meaning In every possible world candidate is maximallyGreat
Formal meaning In some possible world candidate is maximallyGreat
```

`Analyze model OntologicalReading for Conclusion` asks Dialectic whether the
declared model satisfies the alternative assumptions while falsifying the
conclusion. The author declares a model, not a countermodel. Dialectic
classifies that model and asks Lean to check the generated evidence.

`ModalK` assumes no reflexivity, symmetry, transitivity, or Euclidean frame
condition. The current analyzer does not construct or search for models.

See
[`ModalOntologicalArgument.lean`](Dialectic/Examples/ModalOntologicalArgument.lean),
a deliberately bounded K-level reconstruction inspired by Plantinga's modal
argument. The notebook excludes the S5-specific structure of Plantinga's
argument.

### Counterfactual

Counterfactual notebooks distinguish the actual situation from selected
counterfactual situations:

```text
Vocabulary
  Type Match called matchObject
  Object thisMatch is Match
  Predicate struck describes Match
  Predicate lit describes Match
End vocabulary

Model DampMatchModel
  Actual situation actual
    thisMatch is not struck
    thisMatch is not lit
  End situation
  Counterfactual situation dampCase
    thisMatch is struck
    thisMatch is not lit
  End situation
  Closest situations
    actual selects dampCase
  End closest situations
End model

Formal meaning If it were the case that thisMatch is struck, then thisMatch is lit
```

The profile evaluates a conditional at the declared selected situations. It
does not treat the conditional as material implication, infer which situations
are closest, or implement unrestricted Lewis/Stalnaker semantics.

See
[`CounterfactualMatch.lean`](Dialectic/Examples/CounterfactualMatch.lean), an
original match scenario informed by David Lewis's *Counterfactuals*.

## Alternatives, objections, and negative evidence

An `Alternative` changes one or more meanings, rechecks the same controlled
deduction, and may attach an `Objection`. Original and alternative
reconstructions receive separate Lean checks.

The Infoview separates four questions:

| Display | Meaning |
| --- | --- |
| Green, deduction accepted | Lean accepted the declared steps under this reconstruction and profile |
| Amber, preserved deduction rejected | The same steps are not typable after the displayed change |
| Red, contradictory assumptions | The implemented check produced a Lean term of `False` from the alternative assumptions |
| Purple, `⊭` | A checked model satisfies the alternative assumptions while falsifying the conclusion |

The absence of negative evidence has a weaker meaning:

- **No contradiction found** means that the available check produced no
  contradiction witness. It is not a consistency proof.
- **Non-entailment not established** means that no accepted counterexample is
  available. It is not an entailment proof.

CoreLogic countermodels list finite individuals and a total truth assignment
for every declared unary predicate. Modal and counterfactual notebooks instead
describe a neutral model and request analysis. Technical evidence remains
available in the collapsed Infoview section.

## Philosophical examples

The public examples contain original paraphrases and explicit provenance:

| Notebook | Profile | Philosophical basis | Demonstrated comparison |
| --- | --- | --- | --- |
| [`GalileoShip.lean`](Dialectic/Examples/GalileoShip.lean) | `CoreLogic` | Galileo, *Dialogue Concerning the Two Chief World Systems*, Second Day | A scope change rejects the preserved two-step deduction |
| [`GettierCounterexample.lean`](Dialectic/Examples/GettierCounterexample.lean) | `CoreLogic` | Gettier, "Is Justified True Belief Knowledge?", Case I | A finite countermodel certifies non-entailment |
| [`ModalOntologicalArgument.lean`](Dialectic/Examples/ModalOntologicalArgument.lean) | `ModalK` | A bounded subargument inspired by Plantinga, *The Nature of Necessity*, chapter 10 | Possibility replaces necessity; declared-model analysis finds a counterexample |
| [`CounterfactualMatch.lean`](Dialectic/Examples/CounterfactualMatch.lean) | `Counterfactual` | An original match scenario informed by Lewis, *Counterfactuals* | A damp-match reading rejects the preserved deduction and model analysis certifies non-entailment |

None is presented as a settled translation. `CORPUS.md` records source
locations, access status, intended formal features, and unresolved
interpretive choices. Synthetic regression notebooks live under
`Dialectic/Tests/Fixtures/`, not in the public examples.

## Build and test

From this directory:

```sh
lake build
```

The default library imports every public example and every Lean-native
regression test. Expected warnings in the example notebooks report rejected
alternative deductions; they do not indicate a failed build.

The project layout is:

```text
Dialectic/
  Examples/        # source-grounded or source-inspired notebooks
  Language/        # syntax, AST, validation, elaboration, profiles, diagnostics
  Tests/
    Fixtures/      # synthetic regression notebooks
    *.lean         # guards and negative tests
Dialectic.lean     # default build target
DESIGN.md          # implementation and semantic design
CORPUS.md          # source and evaluation records
```

## Documentation

| Document | Purpose |
| --- | --- |
| [README](README.md) | Author workflow, profiles, examples, and result interpretation |
| [Design specification](DESIGN.md) | Grammar, semantics, architecture, diagnostics, and implementation limits |
| [Calibration corpus](CORPUS.md) | Source provenance, passage boundaries, and evaluation cases |
| [Contributing](CONTRIBUTING.md) | Development requirements, example policy, licensing, and contacts |

## Current limits

- CoreLogic supports one domain type and unary-predicate argument forms.
- Relations may be recorded in vocabulary, but the current deduction rules do
  not reason over them.
- ModalK supports box modus ponens and finite declared-model analysis only.
- Counterfactual reasoning uses one explicit selection relation and a bounded
  consequence rule.
- No profile provides unrestricted first-order quantifier alternation,
  equality, description logic, temporal logic, deontic logic, epistemic logic,
  modal model synthesis, or counterfactual similarity search.
- Lean checks formal consequences of declared choices. Readers must still
  assess the premises, paraphrases, source boundaries, and interpretation.

## Contributing and license

Contributions are welcome. Read [CONTRIBUTING.md](CONTRIBUTING.md) before
opening a pull request and run `lake build` before submission.

Dialectic is available under the
[GNU Affero General Public License v3.0 or later](LICENSE). Separate commercial
licensing may be available from the copyright holders.

Project contacts:

- Stefano Maria Nicoletti — <stefano@duck.com>
- Edoardo Putti — <edoardo.putti@gmail.com>
