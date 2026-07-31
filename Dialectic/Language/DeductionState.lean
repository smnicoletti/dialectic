import Lean.Widget
import Dialectic.Language.Ast

/-!
The editing-time view of an explicitly unfinished Dialectic deduction. The
state and suggestions are derived from the controlled AST. They do not become
proof steps until the author writes a `Step` and Lean accepts the completed
deduction.
-/

namespace Dialectic

open Lean Elab Command

structure DeductionStateClaimData where
  name : Name
  paraphrase : String
  sourceReference : String
  deriving Repr, Inhabited, BEq

structure DeductionStateStepData where
  name : Name
  conclusion : Name
  paraphrase : String
  sourceReference : String
  deriving Repr, Inhabited, BEq

structure DeductionSuggestionData where
  text : String
  rule : String
  stepName : Name
  left : Name
  right : Name
  conclusion : Name
  replacement : String
  deriving Repr, Inhabited, BEq

structure DeductionStateData where
  profile : Name
  deduction : Name
  hasGoal : Bool
  markerLabel : String
  target : Name
  targetParaphrase : String
  targetSourceReference : String
  premises : Array DeductionStateClaimData
  establishedSteps : Array DeductionStateStepData
  stepsAccepted : Bool
  suggestions : Array DeductionSuggestionData
  unavailable : String
  deriving Repr, Inhabited, BEq

private def lookupClaim
    (reconstruction : Reconstruction)
    (name : Name) : Option Claim :=
  reconstruction.claims.find? fun claimData => claimData.name == name

private def claimReference (claimData : Claim) : DeductionStateClaimData := {
  name := claimData.name
  paraphrase := claimData.paraphrase
  sourceReference :=
    s!"{claimData.source}, sentence {claimData.sentence}"
}

private def premiseClaims
    (reconstruction : Reconstruction)
    (deduction : Deduction) : Array Claim :=
  let derived := deduction.steps.map (·.conclusion)
  reconstruction.claims.filter fun claimData =>
    !derived.contains claimData.name &&
      deduction.intendedConclusion? != some claimData.name

private def availableClaims
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (includeDerived : Bool) : Array Claim := Id.run do
  let mut result := premiseClaims reconstruction deduction
  if includeDerived then
    for step in deduction.steps do
      if let some claimData := lookupClaim reconstruction step.conclusion then
        unless result.any (fun available => available.name == claimData.name) do
          result := result.push claimData
  return result

private def supportedResult?
    (profile : Name)
    (left right : Meaning) : Option (Meaning × String) :=
  match profile, left, right with
  | `CoreLogic, .everyIs source noun middle,
      .everyIs next noun' target =>
      if middle == next && noun == noun' then
        some (.everyIs source noun target, "universal chain")
      else none
  | `CoreLogic, .everyIs source noun middle,
      .everyIsNot next noun' target =>
      if middle == next && noun == noun' then
        some (.everyIsNot source noun target, "universal chain")
      else none
  | `ModalK, .modalEveryImp individual antecedent consequent,
      .modalEvery individual' premise =>
      if individual == individual' && antecedent == premise then
        some (.modalEvery individual consequent, "box modus ponens")
      else none
  | `Counterfactual, .counterfactual individual antecedent middle,
      .counterfactual individual' next consequent =>
      if individual == individual' && middle == next then
        some (.counterfactual individual antecedent consequent,
          "selected-situation consequence")
      else none
  | _, _, _ => none

private def suggestionText
    (profile left right conclusion : Name) : String :=
  if profile == `CoreLogic then
    s!"Use {left} and then {right} to establish {conclusion}."
  else if profile == `ModalK then
    s!"Use {left} with {right} to establish {conclusion} by box modus ponens."
  else
    s!"Use {left} and then {right} to establish {conclusion} across the same \
       selected situations."

private def pushSuggestionUnique
    (suggestions : Array DeductionSuggestionData)
    (suggestion : DeductionSuggestionData) :
    Array DeductionSuggestionData :=
  if suggestions.any (fun existing => existing.text == suggestion.text) then
    suggestions
  else
    suggestions.push suggestion

private def freshStepName
    (deduction : Deduction)
    (conclusion : Name) : Name := Id.run do
  let base := conclusion.appendAfter "Follows"
  if !deduction.stepNames.contains base then
    return base
  for index in [2:100] do
    let candidate := base.appendAfter index.repr
    if !deduction.stepNames.contains candidate then
      return candidate
  return base.appendAfter "Next"

private def stepReplacement
    (stepName left right conclusion : Name)
    (finishesGoal needsGoalScaffold : Bool) : String :=
  let step :=
    s!"Step {stepName}\n      From {left} and {right} conclude {conclusion}"
  if needsGoalScaffold then
    s!"Goal {conclusion}\n    {step}"
  else if finishesGoal then step
  else s!"{step}\n    Continue deduction"

private def nextSuggestions
    (notebook : Notebook)
    (deduction : Deduction)
    (available : Array Claim) : Array DeductionSuggestionData := Id.run do
  let mut result := #[]
  for left in available do
    for right in available do
      if let some (produced, rule) :=
          supportedResult? notebook.profile left.meaning right.meaning then
        for conclusion in notebook.original.claims do
          let alreadyAvailable :=
            available.any fun claimData => claimData.name == conclusion.name
          let mayChooseAsGoal :=
            deduction.intendedConclusion?.isNone &&
              conclusion.name != left.name &&
              conclusion.name != right.name
          if (!alreadyAvailable || mayChooseAsGoal) &&
              produced == conclusion.meaning then
            let stepName := freshStepName deduction conclusion.name
            let finishesGoal :=
              deduction.intendedConclusion? == Option.some conclusion.name
            let needsGoalScaffold :=
              deduction.isChoosingStep &&
                deduction.intendedConclusion?.isNone
            result := pushSuggestionUnique result {
              text := suggestionText notebook.profile left.name right.name
                conclusion.name
              rule
              stepName
              left := left.name
              right := right.name
              conclusion := conclusion.name
              replacement :=
                stepReplacement stepName left.name right.name conclusion.name
                  finishesGoal needsGoalScaffold
            }
  return result

private def unavailableMessage
    (profile target : Name)
    (hasGoal : Bool)
    (suggestions : Array DeductionSuggestionData) : String :=
  if !suggestions.isEmpty then ""
  else if !hasGoal && profile == `CoreLogic then
    "No currently supported universal-chain move applies to the declared claims."
  else if !hasGoal && profile == `ModalK then
    "No currently supported box-modus-ponens move applies to the declared claims."
  else if !hasGoal then
    "No currently supported selected-situation consequence move applies to the \
     declared claims. Dialectic does not infer a closest-situation ordering."
  else if profile == `CoreLogic then
    s!"No currently supported universal-chain move produces {target}. This is \
       guidance about available moves, not a non-entailment result."
  else if profile == `ModalK then
    s!"No currently supported box-modus-ponens move produces {target}. ModalK \
       suggestions assume only K; no stronger frame principle is suggested."
  else
    s!"No currently supported selected-situation consequence move produces \
       {target}. Dialectic does not infer a closest-situation ordering."

def deductionStateData
    (notebook : Notebook)
    (deduction : Deduction)
    (stepsAccepted : Bool := true) : DeductionStateData :=
  let target := deduction.intendedConclusion?.getD
    (deduction.steps.back?.map (·.conclusion) |>.getD Name.anonymous)
  let targetClaim? := lookupClaim notebook.original target
  let available := availableClaims notebook.original deduction stepsAccepted
  let suggestions :=
    if stepsAccepted then nextSuggestions notebook deduction available else #[]
  {
    profile := notebook.profile
    deduction := deduction.name
    hasGoal := deduction.intendedConclusion?.isSome
    markerLabel :=
      if deduction.isChoosingStep then "Step" else "Continue deduction"
    target
    targetParaphrase := targetClaim?.map (·.paraphrase) |>.getD ""
    targetSourceReference := targetClaim?.map
      (fun claimData => s!"{claimData.source}, sentence {claimData.sentence}")
      |>.getD ""
    premises := (premiseClaims notebook.original deduction).map claimReference
    establishedSteps := deduction.steps.map fun step =>
      let claimData? := lookupClaim notebook.original step.conclusion
      {
        name := step.name
        conclusion := step.conclusion
        paraphrase := claimData?.map (·.paraphrase) |>.getD ""
        sourceReference := claimData?.map
          (fun claimData =>
            s!"{claimData.source}, sentence {claimData.sentence}")
          |>.getD ""
      }
    stepsAccepted
    suggestions
    unavailable :=
      if stepsAccepted then
        unavailableMessage notebook.profile target
          deduction.intendedConclusion?.isSome suggestions
      else
        "Correct the rejected written Step before requesting another move."
  }

private def claimJson (claimData : DeductionStateClaimData) : Json :=
  Json.mkObj [
    ("name", Json.str claimData.name.toString),
    ("paraphrase", Json.str claimData.paraphrase),
    ("sourceReference", Json.str claimData.sourceReference)
  ]

private def stepJson (step : DeductionStateStepData) : Json :=
  Json.mkObj [
    ("name", Json.str step.name.toString),
    ("conclusion", Json.str step.conclusion.toString),
    ("paraphrase", Json.str step.paraphrase),
    ("sourceReference", Json.str step.sourceReference)
  ]

private def suggestionJson (suggestion : DeductionSuggestionData) : Json :=
  Json.mkObj [
    ("text", Json.str suggestion.text),
    ("rule", Json.str suggestion.rule),
    ("stepName", Json.str suggestion.stepName.toString),
    ("replacement", Json.str suggestion.replacement)
  ]

def deductionStateProps (state : DeductionStateData) : Json :=
  Json.mkObj [
    ("profile", Json.str state.profile.toString),
    ("deduction", Json.str state.deduction.toString),
    ("hasGoal", Json.bool state.hasGoal),
    ("markerLabel", Json.str state.markerLabel),
    ("target", Json.str state.target.toString),
    ("targetParaphrase", Json.str state.targetParaphrase),
    ("targetSourceReference", Json.str state.targetSourceReference),
    ("premises", Json.arr <| state.premises.map claimJson),
    ("establishedSteps", Json.arr <| state.establishedSteps.map stepJson),
    ("stepsAccepted", Json.bool state.stepsAccepted),
    ("suggestions", Json.arr <| state.suggestions.map suggestionJson),
    ("unavailable", Json.str state.unavailable)
  ]

@[widget_module]
def dialecticDeductionStateWidget : Widget.Module where
  javascript := "
import * as React from 'react';

const e = React.createElement;

function section(title, content) {
  return e('section', { style: { marginTop: '0.7rem' } },
    e('h4', { style: { margin: '0 0 0.3rem' } }, title),
    content);
}

function claimList(premises) {
  return e('ul', { style: { margin: 0, paddingLeft: '1.2rem' } },
    premises.map((premise) =>
      e('li', { key: premise.name, style: { margin: '0.22rem 0' } },
        e('code', null, premise.name), ' — ', premise.paraphrase,
        e('div', { style: { opacity: 0.72, fontSize: '0.92em' } },
          premise.sourceReference))));
}

function stepList(steps) {
  if (!steps.length) {
    return e('p', { style: { margin: 0, opacity: 0.8 } },
      'No written step has been accepted yet.');
  }
  return e('ul', { style: { margin: 0, paddingLeft: '1.2rem' } },
    steps.map((step) =>
      e('li', { key: step.name, style: { margin: '0.22rem 0' } },
        e('code', null, step.name), ' establishes ',
        e('code', null, step.conclusion),
        e('div', null, step.paraphrase),
        e('div', { style: { opacity: 0.72, fontSize: '0.92em' } },
          step.sourceReference))));
}

function suggestionList(suggestions, unavailable) {
  if (!suggestions.length) {
    return e('p', { style: { margin: 0 } }, unavailable);
  }
  return e('ul', { style: { margin: 0, paddingLeft: '1.2rem' } },
    suggestions.map((suggestion, index) =>
      e('li', { key: suggestion.text + index, style: { margin: '0.22rem 0' } },
        suggestion.text,
        e('span', { style: { opacity: 0.7 } },
          ' (' + suggestion.rule + ')'),
        e('pre', {
          style: {
            margin: '0.35rem 0 0.55rem',
            padding: '0.4rem 0.55rem',
            overflowX: 'auto',
            background: 'var(--vscode-textCodeBlock-background)'
          }
        }, suggestion.replacement))));
}

export default function DialecticDeductionState(props) {
  return e('div', {
    style: {
      padding: '0.65rem 0.8rem',
      lineHeight: 1.35,
      maxWidth: '58rem'
    }
  },
    e('h3', { style: { margin: '0 0 0.2rem' } },
      props.hasGoal ? 'Deduction state' : 'Choose the next deduction step'),
    e('div', { style: { opacity: 0.78, marginBottom: '0.55rem' } },
      'Profile ', e('code', null, props.profile), ' · Deduction ',
      e('code', null, props.deduction)),
    props.hasGoal ? e('div', {
      style: {
        borderLeft: '4px solid #58a6ff',
        padding: '0.4rem 0.65rem'
      }
    },
      e('strong', null, 'Intended conclusion: '),
      e('code', null, props.target),
      e('div', { style: { marginTop: '0.2rem' } }, props.targetParaphrase),
      e('div', { style: { opacity: 0.72, fontSize: '0.92em' } },
        props.targetSourceReference)) :
      e('div', {
        style: {
          borderLeft: '4px solid #58a6ff',
          padding: '0.4rem 0.65rem'
        }
      },
        e('strong', null, 'Select a supported next move below.'),
        e('div', { style: { marginTop: '0.2rem' } },
          'The selected move will add an explicit Goal and a complete Step.')),
    section(props.hasGoal ? 'Premises in scope' : 'Declared claims in scope',
      claimList(props.premises)),
    section(
      props.stepsAccepted
        ? 'Established by Lean-checked draft steps'
        : 'Written steps requiring correction',
      stepList(props.establishedSteps)),
    section('Available next moves',
      suggestionList(props.suggestions, props.unavailable)),
    props.suggestions.length
      ? e('div', {
          style: {
            borderLeft: '3px solid #d29922',
            marginTop: '0.65rem',
            padding: '0.35rem 0 0.35rem 0.65rem'
          }
        },
          props.hasGoal
            ? e(React.Fragment, null,
                'Keep the cursor on ',
                e('code', null, props.markerLabel),
                ', open the Quick Fix menu, and choose ',
                e('strong', null, 'Dialectic: add Step …'),
                '. Intermediate moves retain the marker; a move that reaches ',
                'the Goal closes the draft and triggers the full Lean check.')
            : e(React.Fragment, null,
                'Keep the cursor on ',
                e('code', null, 'Step'),
                ', open the Quick Fix menu, and choose ',
                e('strong', null, 'Dialectic: add Step …'),
                '. The edit adds the displayed Goal and Step; Lean then checks ',
                'the completed deduction.'))
      : null
  );
}
"

def saveDeductionStatePanel
    (deduction : Deduction)
    (state : DeductionStateData) : CommandElabM Unit := do
  let ref := deduction.stateRef?.getD deduction.ref
  liftCoreM <| Widget.savePanelWidgetInfo
    dialecticDeductionStateWidget.javascriptHash
    (pure <| deductionStateProps state)
    ref

end Dialectic
