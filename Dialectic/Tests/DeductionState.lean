import Dialectic.Language
import Dialectic.Examples.GalileoShipDraft

open Dialectic
open Lean Elab Command

#guard DiagnosticCategory.deductionState.code == "DEDUCTION/STATE"

private def missing : Syntax := Syntax.missing

private def mkTestClaim
    (name : Name)
    (semanticForm : Meaning)
    (paraphrase : String)
    (sentenceNo : Nat) : Dialectic.«Claim» := {
  name
  «source» := `TestSource
  «sentence» := sentenceNo
  paraphrase
  «meaning» := semanticForm
  ref := missing
  meaningRef := missing
}

private def notebook
    (profileName : Name)
    (claims : Array Dialectic.«Claim»)
    (proofData : Dialectic.«Deduction») : Notebook := {
  name := `EditingTest
  «profile» := profileName
  profileDescription := "state test"
  profileRef := missing
  «vocabulary» := {
    typeWord := { leanName := `Thing, noun := `thing, ref := missing }
    predicates := #[]
    relations := #[]
    ref := missing
  }
  «source» := {
    name := `TestSource
    citation := "Original test material"
    location := "sentences 1–5"
    sentences := #[]
    ref := missing
  }
  «original» := {
    name := `Original
    claims
    deductions := #[proofData]
    ref := missing
  }
  «alternative» := {
    name := `Alternative
    base := `Original
    changes := #[]
    recheck := proofData.name
    countermodel? := Option.none
    objections := #[]
    ref := missing
    recheckRef := missing
  }
  ref := missing
}

private def coreDeduction : Dialectic.«Deduction» := {
  name := `ShipComparison
  steps := #[{
    name := `OutcomeBridge
    left := `P1
    right := `P2
    conclusion := `DescribedOutcome
    ref := missing
  }]
  intendedConclusion? := Option.some `Conclusion
  stateRef? := Option.some missing
  ref := missing
}

private def coreNotebook : Notebook :=
  notebook `CoreLogic #[
    mkTestClaim `P1 (.everyIs `described `trial `stipulated)
      "Every described trial is stipulated." 1,
    mkTestClaim `P2 (.everyIs `stipulated `trial `sameOutcome)
      "Every stipulated trial has the same outcome." 2,
    mkTestClaim `P3 (.everyIs `sameOutcome `trial `nonDiscriminating)
      "Every same-outcome trial is non-discriminating." 3,
    mkTestClaim `DescribedOutcome (.everyIs `described `trial `sameOutcome)
      "Every described trial has the same outcome." 4,
    mkTestClaim `Conclusion (.everyIs `described `trial `nonDiscriminating)
      "Every described trial is non-discriminating." 5
  ] coreDeduction

private def coreState := deductionStateData coreNotebook coreDeduction

#guard coreState.profile == `CoreLogic
#guard coreState.target == `Conclusion
#guard coreState.targetSourceReference == "TestSource, sentence 5"
#guard coreState.premises.map (·.name) == #[`P1, `P2, `P3]
#guard coreState.establishedSteps == #[{
  name := `OutcomeBridge
  conclusion := `DescribedOutcome
  paraphrase := "Every described trial has the same outcome."
  sourceReference := "TestSource, sentence 4"
}]
#guard coreState.suggestions.any fun suggestion =>
  suggestion.text ==
    "Use DescribedOutcome and then P3 to establish Conclusion." &&
  suggestion.rule == "universal chain"
#guard coreState.suggestions.any fun suggestion =>
  suggestion.stepName == `ConclusionFollows &&
  suggestion.replacement ==
    "Step ConclusionFollows\n      From DescribedOutcome and P3 conclude \
     Conclusion"

private def bareStepDeduction (name : Name) : Dialectic.«Deduction» := {
  name
  steps := #[]
  stateRef? := Option.some missing
  draftMarker := .chooseStep
  ref := missing
}

private def coreBareStep := bareStepDeduction `CoreDraft

private def coreBareStepState :=
  deductionStateData
    (notebook `CoreLogic #[
      mkTestClaim `P1 (.everyIs `reflective `inquiry `careful)
        "Every reflective inquiry is careful." 1,
      mkTestClaim `P2 (.everyIs `careful `inquiry `revisable)
        "Every careful inquiry is revisable." 2,
      mkTestClaim `Conclusion (.everyIs `reflective `inquiry `revisable)
        "Every reflective inquiry is revisable." 3
    ] coreBareStep)
    coreBareStep

#guard coreBareStepState.suggestions.size == 1
#guard coreBareStepState.suggestions[0]!.rule == "universal chain"
#guard coreBareStepState.suggestions[0]!.replacement.startsWith
  "Goal Conclusion\n    Step"

private def rejectedDraftState :=
  deductionStateData coreNotebook coreDeduction false

#guard !rejectedDraftState.stepsAccepted
#guard rejectedDraftState.suggestions.isEmpty
#guard rejectedDraftState.unavailable ==
  "Correct the rejected written Step before requesting another move."

private def modalDeduction : Dialectic.«Deduction» := {
  name := `NecessaryConsequence
  steps := #[]
  intendedConclusion? := Option.some `Conclusion
  stateRef? := Option.some missing
  ref := missing
}

private def modalState :=
  deductionStateData
    (notebook `ModalK #[
      mkTestClaim `M1 (.modalEveryImp `candidate `great `existent)
        "Necessarily, greatness implies existence." 1,
      mkTestClaim `M2 (.modalEvery `candidate `great)
        "The candidate is necessarily great." 2,
      mkTestClaim `Conclusion (.modalEvery `candidate `existent)
        "The candidate necessarily exists." 3
    ] modalDeduction)
    modalDeduction

#guard modalState.suggestions.size == 1
#guard modalState.suggestions[0]!.rule == "box modus ponens"
#guard modalState.suggestions[0]!.text.contains "Use M1 with M2"
#guard !modalState.suggestions[0]!.text.contains "universal chain"

private def modalBareStep := bareStepDeduction `ModalDraft

private def modalBareStepState :=
  deductionStateData
    (notebook `ModalK #[
      mkTestClaim `M1 (.modalEveryImp `candidate `great `existent)
        "Necessarily, greatness implies existence." 1,
      mkTestClaim `M2 (.modalEvery `candidate `great)
        "The candidate is necessarily great." 2,
      mkTestClaim `Conclusion (.modalEvery `candidate `existent)
        "The candidate necessarily exists." 3
    ] modalBareStep)
    modalBareStep

#guard modalBareStepState.suggestions.size == 1
#guard modalBareStepState.suggestions[0]!.rule == "box modus ponens"
#guard modalBareStepState.suggestions[0]!.replacement.startsWith
  "Goal Conclusion\n    Step"

private def counterfactualDeduction : Dialectic.«Deduction» := {
  name := `CounterfactualConsequence
  steps := #[]
  intendedConclusion? := Option.some `Conclusion
  stateRef? := Option.some missing
  ref := missing
}

private def counterfactualState :=
  deductionStateData
    (notebook `Counterfactual #[
      mkTestClaim `C1 (.counterfactual `match `struck `lit)
        "If struck, the match would light." 1,
      mkTestClaim `C2 (.counterfactual `match `lit `visible)
        "If lit, the flame would be visible." 2,
      mkTestClaim `Conclusion (.counterfactual `match `struck `visible)
        "If struck, the flame would be visible." 3
    ] counterfactualDeduction)
    counterfactualDeduction

#guard counterfactualState.suggestions.size == 1
#guard counterfactualState.suggestions[0]!.rule ==
  "selected-situation consequence"
#guard counterfactualState.suggestions[0]!.text.contains
  "across the same selected situations"

private def counterfactualBareStepDeduction : Dialectic.«Deduction» := {
  name := `CounterfactualConsequence
  steps := #[]
  stateRef? := Option.some missing
  draftMarker := .chooseStep
  ref := missing
}

private def counterfactualBareStepState :=
  deductionStateData
    (notebook `Counterfactual #[
      mkTestClaim `C1 (.counterfactual `match `struck `lit)
        "If struck, the match would light." 1,
      mkTestClaim `C2 (.counterfactual `match `lit `visible)
        "If lit, the match would be visible." 2,
      mkTestClaim `Conclusion (.counterfactual `match `struck `visible)
        "If struck, the match would be visible." 3
    ] counterfactualBareStepDeduction)
    counterfactualBareStepDeduction

#guard !counterfactualBareStepState.hasGoal
#guard counterfactualBareStepState.markerLabel == "Step"
#guard counterfactualBareStepState.suggestions.size == 1
#guard counterfactualBareStepState.suggestions[0]!.replacement ==
  "Goal Conclusion\n    Step ConclusionFollows\n      From C1 and C2 conclude \
   Conclusion"

private def unsupportedGoal : Dialectic.«Deduction» := {
  name := `UnsupportedGoal
  steps := #[]
  intendedConclusion? := Option.some `Conclusion
  stateRef? := Option.some missing
  ref := missing
}

private def unsupportedState :=
  deductionStateData
    (notebook `CoreLogic #[
      mkTestClaim `P1 (.someIs `reflective `person `careful)
        "Some reflective person is careful." 1,
      mkTestClaim `Conclusion (.everyIs `reflective `person `careful)
        "Every reflective person is careful." 2
    ] unsupportedGoal)
    unsupportedGoal

#guard unsupportedState.suggestions.isEmpty
#guard unsupportedState.unavailable.contains
  "not a non-entailment result"

private def unsupportedBareStep : Dialectic.«Deduction» := {
  name := `UnsupportedBareStep
  steps := #[]
  stateRef? := Option.some missing
  draftMarker := .chooseStep
  ref := missing
}

private def unsupportedBareStepState :=
  deductionStateData
    (notebook `Counterfactual #[
      mkTestClaim `C1 (.counterfactual `match `struck `lit)
        "If struck, the match would light." 1,
      mkTestClaim `C2 (.counterfactual `match `wet `cold)
        "If wet, the match would be cold." 2
    ] unsupportedBareStep)
    unsupportedBareStep

#guard unsupportedBareStepState.suggestions.isEmpty
#guard unsupportedBareStepState.unavailable.contains
  "No currently supported selected-situation consequence move applies"
#guard !unsupportedBareStepState.unavailable.contains "[anonymous]"

#guard !dialecticDeductionStateWidget.javascript.contains
  "These are editing suggestions, not checked results."
#guard dialecticDeductionStateWidget.javascript.contains
  "Choose the next deduction step"
#guard dialecticDeductionStateWidget.javascript.contains
  "Select a supported next move below."
#guard !dialecticDeductionStateWidget.javascript.contains
  "This panel does not establish non-entailment."
#guard !dialecticDeductionStateWidget.javascript.contains "onClick"

private def guardedEditJson : String :=
  (toJson <| versionedStepWorkspaceEdit {
    uri := "file:///tmp/DialecticDraft.lean"
    version? := Option.some 7
  } {
    start := { line := 20, character := 4 }
    «end» := { line := 20, character := 22 }
  } "Step ConclusionFollows").compress

#guard guardedEditJson.contains "\"version\":7"
#guard guardedEditJson.contains "Step ConclusionFollows"

run_cmd do
  let registered := Lean.Server.codeActionProviderExt.getState (← getEnv)
  unless registered.contains ``Dialectic.deductionStepCodeAction do
    throwError "Dialectic deduction-step code action provider was not registered"

run_cmd do
  let sourceText := r#"
Argument ParsedDraft
Logic profile CoreLogic
  Description "source-range test"
End logic
Vocabulary
  Type Thing called thing
  Predicate first describes Thing
  Predicate second describes Thing
End vocabulary
Source TestSource
  Citation "Original test material"
  Location "sentences 1–2"
  Sentence 1 "Every first thing is second."
  Sentence 2 "Every first thing is second."
End source
Reconstruction Original
  Claim P1 from TestSource sentence 1
    Paraphrase "Every first thing is second."
    Formal meaning Every first thing is second
  End claim
  Claim Conclusion from TestSource sentence 2
    Paraphrase "Every first thing is second."
    Formal meaning Every first thing is second
  End claim
  Deduction Draft
    Goal Conclusion
    Continue deduction
  End deduction
End reconstruction
Alternative Clarification based on Original
  Change P1
    Original meaning Every first thing is second
    Alternative meaning Some first thing is second
  End change
  Recheck the same deduction Draft
End alternative
End argument
"#
  let parsed ←
    match Parser.runParserCategory (← getEnv) `command sourceText "<state-range-test>" with
    | .ok parsedSyntax => pure parsedSyntax
    | .error message => throwError message
  let parsedNotebook ← parseNotebook parsed
  let parsedDeduction ← parsedNotebook.original.deductions[0]?.getDM <|
    throwError "missing parsed draft deduction"
  let stateRef ← parsedDeduction.stateRef?.getDM <|
    throwError "draft marker did not retain its source range"
  if stateRef.getPos?.isNone || stateRef.getTailPos?.isNone then
    throwError "draft marker has no source range"

run_cmd do
  let sourceText := r#"
Argument ParsedBareStep
Logic profile Counterfactual
  Description "bare Step parser regression"
End logic
Vocabulary
  Type Match called matchObject
  Object thisMatch is Match
  Predicate struck describes Match
  Predicate lit describes Match
  Predicate visible describes Match
End vocabulary
Model MatchModel
  Actual situation actual
    thisMatch is not struck
    thisMatch is not lit
    thisMatch is not visible
  End situation
  Counterfactual situation selected
    thisMatch is struck
    thisMatch is lit
    thisMatch is visible
  End situation
  Closest situations
    actual selects selected
  End closest situations
End model
Source MatchSource
  Citation "Original parser test"
  Location "sentences 1-3"
  Sentence 1 "If struck, lit."
  Sentence 2 "If lit, visible."
  Sentence 3 "If struck, visible."
End source
Reconstruction Original
  Claim C1 from MatchSource sentence 1
    Paraphrase "If struck, lit."
    Formal meaning If it were the case that thisMatch is struck, then thisMatch is lit
  End claim
  Claim C2 from MatchSource sentence 2
    Paraphrase "If lit, visible."
    Formal meaning If it were the case that thisMatch is lit, then thisMatch is visible
  End claim
  Claim Conclusion from MatchSource sentence 3
    Paraphrase "If struck, visible."
    Formal meaning If it were the case that thisMatch is struck, then thisMatch is visible
  End claim
  Deduction Draft
    Step
  End deduction
End reconstruction
Alternative DampReading based on Original
  Change C1
    Original meaning If it were the case that thisMatch is struck, then thisMatch is lit
    Alternative meaning If it were the case that thisMatch is struck, then thisMatch is not lit
  End change
  Recheck the same deduction Draft
End alternative
End argument
"#
  let parsed ←
    match Parser.runParserCategory (← getEnv) `command sourceText
        "<bare-step-parser-test>" with
    | .ok parsedSyntax => pure parsedSyntax
    | .error message => throwError message
  let parsedNotebook ← parseNotebook parsed
  let parsedDeduction ← parsedNotebook.original.deductions[0]?.getDM <|
    throwError "missing parsed bare-Step deduction"
  unless parsedDeduction.isChoosingStep do
    throwError "bare Step was not retained as a draft marker"
  if parsedDeduction.intendedConclusion?.isSome then
    throwError "bare Step without Goal acquired an implicit target"
  let stateRef ← parsedDeduction.stateRef?.getDM <|
    throwError "bare Step did not retain its source range"
  if stateRef.getPos?.isNone || stateRef.getTailPos?.isNone then
    throwError "bare Step marker has no source range"
