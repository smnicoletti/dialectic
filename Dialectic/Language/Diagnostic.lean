import Lean.Widget
import Dialectic.Language.Ast

/-!
Stable, source-facing diagnostic categories and the optional Dialectic panel
shown by Lean's standard Infoview. This module presents checker results; it
does not decide them and is not part of the trusted proof path.
-/

namespace Dialectic

open Lean Elab Command

inductive DiagnosticCategory where
  | parseSection
  | vocabulary
  | model
  | profile
  | deductionAccepted
  | deductionRejected
  | preservedAccepted
  | preservedRejected
  | alternativeInconsistency
  | consistencyNotEstablished
  | nonEntailment
  | nonEntailmentCertified
  | nonEntailmentNotEstablished
  | countermodelRejected
  | capability
  | delta
  | interpretive
  | document
  deriving Repr, Inhabited, BEq, DecidableEq

def DiagnosticCategory.code : DiagnosticCategory → String
  | .parseSection => "PARSE"
  | .vocabulary => "VOCAB"
  | .model => "MODEL"
  | .profile => "PROFILE"
  | .deductionAccepted => "CHECK/ACCEPTED"
  | .deductionRejected => "CHECK/REJECTED"
  | .preservedAccepted => "RECHECK/ACCEPTED"
  | .preservedRejected => "RECHECK/REJECTED"
  | .alternativeInconsistency => "ALTERNATIVE/INCONSISTENCY"
  | .consistencyNotEstablished => "ALTERNATIVE/CONSISTENCY-NOT-ESTABLISHED"
  | .nonEntailment => "NONENTAILMENT"
  | .nonEntailmentCertified => "NONENTAILMENT/CERTIFIED"
  | .nonEntailmentNotEstablished => "NONENTAILMENT/NOT-ESTABLISHED"
  | .countermodelRejected => "NONENTAILMENT/CERTIFICATE-REJECTED"
  | .capability => "CAPABILITY"
  | .delta => "DELTA"
  | .interpretive => "INTERPRETIVE"
  | .document => "DOCUMENT"

def diagnostic
    (category : DiagnosticCategory)
    (body : MessageData) : MessageData :=
  m!"[DIALECTIC/{category.code}] {body}"

@[widget_module]
def dialecticDiagnosticsWidget : Widget.Module where
  javascript := "
import * as React from 'react';

const e = React.createElement;

function badge(label, tone) {
  const colors = {
    accepted: '#2ea043',
    rejected: '#d29922',
    witnessed: '#f85149',
    certified: '#a371f7',
    neutral: '#8b949e'
  };
  return e('span', {
    style: {
      display: 'inline-block',
      color: colors[tone] || colors.neutral,
      fontWeight: 650,
      marginRight: '0.45rem'
    }
  }, label);
}

function row(label, value, tone) {
  return e('div', {
    key: label,
    style: {
      display: 'grid',
      gridTemplateColumns: '12rem minmax(0, 1fr)',
      gap: '0.5rem',
      margin: '0.22rem 0'
    }
  }, e('strong', null, label), badge(value, tone));
}

function listSection(title, rows) {
  if (!rows || rows.length === 0) return null;
  return e('section', { style: { marginTop: '0.7rem' } },
    e('h4', { style: { margin: '0 0 0.25rem' } }, title),
    e('ul', { style: { margin: 0, paddingLeft: '1.2rem' } },
      rows.map((item, i) => e('li', { key: title + i },
        e('code', null, item.label), ': ', item.text))));
}

function paragraph(text, style) {
  if (!text) return null;
  return e('p', { style: style || { margin: '0.2rem 0' } }, text);
}

function technicalDetails(panel) {
  return e('details', { style: { marginTop: '0.45rem', opacity: 0.86 } },
    e('summary', {
      style: { cursor: 'pointer', fontWeight: 600 }
    }, 'Technical details'),
    e('div', { style: { marginTop: '0.35rem' } },
      paragraph('Status: ' + panel.technicalStatus),
      paragraph(panel.technicalEvidence),
      paragraph(panel.technicalChecked)));
}

function evidencePanel(panel, tone) {
  const colors = {
    witnessed: '#f85149',
    certified: '#a371f7',
    neutral: '#8b949e'
  };
  return e('section', {
    style: {
      border: '1px solid #30363d',
      borderLeft: '4px solid ' + (colors[tone] || colors.neutral),
      borderRadius: '4px',
      marginTop: '0.75rem',
      padding: '0.55rem 0.7rem'
    }
  },
    e('h4', { style: { margin: '0 0 0.4rem' } },
      e('span', { style: { marginRight: '0.35rem' } }, panel.icon),
      panel.heading),
    paragraph(panel.sentence1),
    paragraph(panel.sentence2),
    paragraph(panel.reference, { margin: '0.3rem 0 0', fontWeight: 600 }),
    paragraph(panel.boundary, { margin: '0.3rem 0 0', fontStyle: 'italic' }),
    technicalDetails(panel)
  );
}

function recheckPanel(panel) {
  const tone = panel.unaffected
    ? 'neutral'
    : (panel.accepted ? 'accepted' : 'rejected');
  const boundary = panel.unaffected
    ? 'This says only that the changed claim is outside this deduction. It does not make the alternative assumptions consistent.'
    : (panel.accepted
      ? 'Lean accepted this preserved deduction under the changed assumptions.'
      : 'This rejects only the preserved deduction. Non-entailment requires separate counterexample evidence.');
  return e('section', {
    style: {
      border: '1px solid var(--vscode-panel-border)',
      borderRadius: '4px',
      marginTop: '0.55rem',
      padding: '0.55rem 0.7rem'
    }
  },
    e('h4', { style: { margin: '0 0 0.35rem' } },
      'Original deduction rechecked under the alternative'),
    badge(panel.heading, tone),
    paragraph(panel.detail, { margin: '0.32rem 0 0' }),
    paragraph(boundary, {
      margin: '0.32rem 0 0',
      fontStyle: 'italic',
      opacity: 0.9
    }));
}

function alternativeOverview(props) {
  const inconsistencyStatus = props.inconsistency.technicalStatus;
  const nonEntailmentStatus = props.nonEntailment.technicalStatus;
  const assumptions =
    inconsistencyStatus === 'InconsistencyStatus.witnessed'
      ? ['Contradictory assumptions', 'witnessed']
      : (inconsistencyStatus === 'InconsistencyStatus.notChecked'
        ? ['Not checked for contradiction', 'neutral']
        : ['No contradiction found (limited check)', 'neutral']);
  const conclusion =
    nonEntailmentStatus === 'NonEntailmentStatus.certified'
      ? ['Does not follow — counterexample found', 'certified']
      : ['Non-entailment not established', 'neutral'];
  return e('section', {
    style: {
      borderTop: '1px solid var(--vscode-panel-border)',
      marginTop: '0.7rem',
      paddingTop: '0.6rem'
    }
  },
    e('h4', { style: { margin: '0 0 0.35rem' } },
      'Alternative reconstruction as a whole'),
    row('Assumptions together', assumptions[0], assumptions[1]),
    row('Conclusion', conclusion[0], conclusion[1]),
    row('Negative evidence',
      nonEntailmentStatus === 'NonEntailmentStatus.certified'
        ? props.evidenceKind
        : 'unavailable (recheck only)',
      nonEntailmentStatus === 'NonEntailmentStatus.certified'
        ? 'certified'
        : 'neutral'),
    paragraph(
      'These two results concern the alternative assumptions considered together. Rechecking the original deduction is a separate question.',
      { margin: '0.35rem 0 0', opacity: 0.9 }
    ));
}

function noSemanticResultDetails(props) {
  return e('details', { style: { marginTop: '0.55rem', opacity: 0.9 } },
    e('summary', {
      style: { cursor: 'pointer', fontWeight: 600 }
    }, 'Why no stronger negative result is shown'),
    e('div', { style: { marginTop: '0.35rem' } },
      paragraph(props.inconsistency.sentence1),
      paragraph(props.inconsistency.sentence2),
      paragraph(props.nonEntailment.sentence1),
      paragraph(props.nonEntailment.sentence2)));
}

function capabilityPanel(panel) {
  return e('details', {
    style: {
      border: '1px solid var(--vscode-panel-border)',
      borderRadius: '4px',
      marginTop: '0.75rem',
      padding: '0.55rem 0.7rem'
    }
  },
    e('summary', {
      style: { cursor: 'pointer', fontWeight: 600 }
    }, panel.heading + ' — scope and limits'),
    e('div', { style: { marginTop: '0.35rem' } },
      paragraph(panel.inconsistency),
      paragraph(panel.nonEntailment),
      paragraph(panel.boundary, { margin: '0.3rem 0 0', fontStyle: 'italic' }),
      paragraph(panel.technicalInconsistency),
      paragraph(panel.technicalNonEntailment),
      paragraph(panel.roadmap)));
}

export default function DialecticDiagnostics(props) {
  const witnessed =
    props.inconsistency.technicalStatus === 'InconsistencyStatus.witnessed';
  const certified =
    props.nonEntailment.technicalStatus === 'NonEntailmentStatus.certified';
  const inconsistency = evidencePanel(props.inconsistency,
    witnessed ? 'witnessed' : 'neutral');
  const recheck = recheckPanel(props.recheck);
  return e('div', {
    style: {
      padding: '0.65rem 0.8rem',
      lineHeight: 1.35,
      maxWidth: '58rem'
    }
  },
    e('h3', { style: { margin: '0 0 0.2rem' } }, 'Dialectic diagnostics'),
    e('div', { style: { opacity: 0.78, marginBottom: '0.55rem' } },
      props.argument, ' · profile ', e('code', null, props.profile),
      props.model ? [' · model ', e('code', { key: 'model' }, props.model)] : null),
    row('Original reconstruction', props.originalStatus,
      props.originalStatus === 'deduction accepted' ? 'accepted' : 'rejected'),
    paragraph(
      'Green marks an accepted deduction. Purple marks checked negative evidence, not a tool error.',
      { margin: '0.2rem 0 0.5rem', opacity: 0.82 }
    ),
    alternativeOverview(props),
    witnessed ? inconsistency : null,
    certified ? evidencePanel(props.nonEntailment, 'certified') : null,
    (!witnessed && !certified) ? noSemanticResultDetails(props) : null,
    recheck,
    capabilityPanel(props.capabilities),
    listSection('Recorded deltas', props.deltas),
    listSection('Interpretive annotations', props.objections),
    e('div', {
      style: {
        borderLeft: '3px solid #58a6ff',
        marginTop: '0.8rem',
        padding: '0.35rem 0 0.35rem 0.65rem'
      }
    }, props.boundary)
  );
}
"

private def originalStatusJson : DeductionStatus → String
  | .accepted => "deduction accepted"
  | .rejected => "deduction not accepted"

structure EvidencePanelData where
  icon : String
  heading : String
  sentence1 : String
  sentence2 : String
  reference : String
  boundary : String
  technicalStatus : String
  technicalEvidence : String
  technicalChecked : String
  deriving Repr, Inhabited, BEq

structure RecheckSummaryData where
  heading : String
  detail : String
  accepted : Bool
  unaffected : Bool
  dependencies : Array Name
  changedClaims : Array Name
  steps : Array Name
  deriving Repr, Inhabited, BEq

private def naturalNameList (names : Array Name) : String :=
  match names.toList.map (·.toString) with
  | [] => "none"
  | [name] => name
  | [first, second] => s!"{first} and {second}"
  | names =>
      let last := names.getLast!
      let initial := names.dropLast
      s!"{String.intercalate ", " initial}, and {last}"

private def nounForCount (singular plural : String) (count : Nat) : String :=
  if count == 1 then singular else plural

def recheckSummaryData
    (deduction : Deduction)
    (alternative : Alternative)
    (status : DeductionStatus) : RecheckSummaryData :=
  let dependencies := deduction.baseDependencies
  let changedClaims := alternative.changes.map (·.claim)
  let affected :=
    changedClaims.filter fun changed => dependencies.contains changed
  let unaffected := affected.isEmpty
  let claimNoun := nounForCount "Claim" "Claims" dependencies.size
  let changedNoun := nounForCount "Claim" "Claims" changedClaims.size
  let stepNoun := nounForCount "Step" "Steps" deduction.steps.size
  let dependencyText :=
    s!"Deduction {deduction.name} uses {claimNoun} \
       {naturalNameList dependencies} in {stepNoun} \
       {naturalNameList deduction.stepNames}."
  let changeText :=
    if unaffected then
      s!"Changed {changedNoun} {naturalNameList changedClaims} \
         {if changedClaims.size == 1 then "is" else "are"} not among them."
    else
      s!"Changed {nounForCount "Claim" "Claims" affected.size} \
         {naturalNameList affected} \
         {if affected.size == 1 then "is" else "are"} among them."
  {
    heading :=
      if unaffected && status == .accepted then
        "This change does not affect this deduction."
      else if status == .accepted then
        "Preserved deduction accepted under this alternative."
      else
        "Preserved deduction rejected under this alternative."
    detail := s!"{dependencyText} {changeText}"
    accepted := status == .accepted
    unaffected
    dependencies
    changedClaims
    steps := deduction.stepNames
  }

structure CapabilityHelpData where
  heading : String
  inconsistency : String
  nonEntailment : String
  boundary : String
  technicalInconsistency : String
  technicalNonEntailment : String
  roadmap : String
  deriving Repr, Inhabited, BEq

def capabilityHelpData (profile : Name) : CapabilityHelpData :=
  if profile == `CoreLogic then {
    heading := "What CoreLogic can check"
    inconsistency :=
      "Contradiction: an existential witness conflicting with a universal-rule chain."
    nonEntailment :=
      "Non-entailment: a displayed finite set of individuals and predicate assignments."
    boundary :=
      "No result means that these limited checks found or received no witness."
    technicalInconsistency :=
      "The contradiction check starts from 'Some A noun is B' or 'Some A noun \
       is not B', closes positive facts under chains of 'Every A noun is B', \
       applies 'Every A noun is not B' at every reachable point, and looks for \
       one predicate both affirmed and denied. Only claims not concluded by a \
       step of the selected deduction are tested as premises."
    technicalNonEntailment :=
      "A countermodel must contain at least one named individual and assign every \
       declared unary predicate at every individual. Lean checks all alternative \
       premises together with the negation of the rechecked deduction's final \
       target over that finite domain. Dialectic does not search for the model."
    roadmap :=
      "Stronger negative results require explicit certificates for richer \
       models, or a sound-and-complete decision or model-finding procedure for \
       a precisely bounded fragment."
  } else if profile == `ModalK then {
    heading := "What ModalK can check"
    inconsistency := "Contradiction: no check is implemented."
    nonEntailment :=
      "Non-entailment: analysis of a philosopher-authored finite Kripke model."
    boundary :=
      "Dialectic detects whether the declared model is a counterexample; it does \
       not yet synthesize a new Kripke model."
    technicalInconsistency :=
      "ModalK currently elaborates box modus ponens with one declared \
       accessibility relation and no frame conditions. It has no contradiction \
       witness procedure."
    technicalNonEntailment :=
      "The Model declares an actual world, possible worlds, ground facts, and \
       arbitrary accessibility edges. Dialectic analyzes that neutral model, \
       generates the negative-evidence proposition, and Lean checks it."
    roadmap :=
      "Still unavailable: synthesis of new modal models, contradiction automation, \
       quantifiers over individuals, and stronger frame logics such as T, S4, \
       or S5 unless separately profiled."
  } else {
    heading := "What Counterfactual can check"
    inconsistency := "Contradiction: no check is implemented."
    nonEntailment :=
      "Non-entailment: analysis of a philosopher-authored actual/counterfactual model."
    boundary :=
      "The author describes the situations and selection as an interpretation; \
       Dialectic determines whether that model is a counterexample."
    technicalInconsistency :=
      "The profile re-elaborates the bounded selected-world consequence rule. \
       It has no contradiction witness procedure."
    technicalNonEntailment :=
      "The Model declares the object, actual and counterfactual situations, \
       ground facts, and selected-situation edges. Dialectic generates and Lean \
       checks the negative-evidence proposition."
    roadmap :=
      "Still unavailable: similarity rankings, antecedent-indexed selection, \
       closest-world search, nesting, quantifiers, and completeness for any \
       unrestricted conditional logic."
  }

def capabilityMessage (profile : Name) : String :=
  if profile == `CoreLogic then
    "CoreLogic can check chained unary contradiction witnesses and \
     author-supplied finite unary countermodels. Other cases remain \
     unestablished."
  else if profile == `ModalK then
      "ModalK can recheck box modus ponens and analyze a declared finite Kripke \
     model for counterexamples. It adds no frame conditions and does not \
     synthesize models."
  else
    "Counterfactual can recheck its bounded selected-situation consequence rule \
     and analyze declared actual/counterfactual models. It does not infer a \
     closest-situation ordering."

def inconsistencyPanelData
    (result : InconsistencyResult) : EvidencePanelData :=
  match result.status, result.evidence? with
  | .witnessed, some evidence => {
      icon := "⚠"
      heading := "Alternative assumptions are contradictory"
      sentence1 := "The alternative assumptions cannot all hold together."
      sentence2 :=
        "This result concerns the alternative reconstruction as a whole."
      reference := s!"The conflict uses Claims {String.intercalate ", " <|
        evidence.participatingClaims.toList.map (fun name => name.toString)}."
      boundary :=
        "The contradiction does not by itself show that the preserved deduction \
         failed or identify which reading should change."
      technicalStatus := "InconsistencyStatus.witnessed"
      technicalEvidence :=
        s!"Contradiction check over the alternative premise set associated with \
           Deduction {evidence.deduction}; target {evidence.target}. \
           {evidence.proofMethod}"
      technicalChecked :=
        "Lean elaborated the generated contradiction term against False and the \
         kernel accepted it."
    }
  | .witnessed, none => {
      icon := "⚠"
      heading := "Alternative assumptions are contradictory"
      sentence1 := "The alternative assumptions cannot all hold together."
      sentence2 := "The participating claims are not available in this report."
      reference := ""
      boundary :=
        "The contradiction does not by itself show that the preserved deduction \
         failed or identify which reading should change."
      technicalStatus := "InconsistencyStatus.witnessed"
      technicalEvidence := "Lean-checked contradiction witness."
      technicalChecked := "Lean checked a term of type False."
    }
  | .notWitnessed, _ => {
      icon := "○"
      heading := "No contradiction found"
      sentence1 :=
        "The checked assumptions did not produce a contradiction in the available test."
      sentence2 := "This does not show that the assumptions are consistent."
      reference := ""
      boundary := ""
      technicalStatus := "InconsistencyStatus.notWitnessed"
      technicalEvidence :=
        "No existential witness conflicts with any predicate reachable through \
         the implemented universal-rule closure over the alternative premises."
      technicalChecked :=
        "Only the implemented CoreLogic unary contradiction-chain pattern was tested."
    }
  | .notChecked, _ => {
      icon := "○"
      heading := "No contradiction check available"
      sentence1 := "This logic profile does not yet include a contradiction test."
      sentence2 := "No consistency judgment is made."
      reference := ""
      boundary := ""
      technicalStatus := "InconsistencyStatus.notChecked"
      technicalEvidence :=
        "No contradiction procedure is implemented for the selected profile."
      technicalChecked := "No inconsistency witness was checked."
    }

def nonEntailmentPanelData
    (result : NonEntailmentResult) : EvidencePanelData :=
  match result.status, result.evidence? with
  | .certified, some evidence => {
      icon := "⊭"
      heading := "Conclusion not supported by this reconstruction"
      sentence1 :=
        "A concrete model satisfies the alternative assumptions while the \
         conclusion is false."
      sentence2 :=
        "Lean checked the generated evidence, so this establishes non-entailment \
         for this reconstruction."
      reference :=
        s!"{evidence.modelSummary} Target: {evidence.target}."
      boundary :=
        "This assesses the declared reconstruction and model, not the source text."
      technicalStatus := "NonEntailmentStatus.certified"
      technicalEvidence :=
        s!"Generated certificate {evidence.certificate}; states \
           {String.intercalate ", " <|
             evidence.individuals.toList.map (fun name => name.toString)}. \
           Assignment: {evidence.modelSummary}. \
           {evidence.proofMethod}"
      technicalChecked :=
        "The model analyzer generated a proposition combining all alternative \
         premises with target failure; Lean checked that proposition."
    }
  | .certified, none => {
      icon := "⊭"
      heading := "Conclusion not supported by this reconstruction"
      sentence1 :=
        "A concrete model satisfies the alternative assumptions while the \
         conclusion is false."
      sentence2 :=
        "Lean checked the generated evidence, so this establishes non-entailment \
         for this reconstruction."
      reference := ""
      boundary :=
        "This assesses the declared reconstruction and model, not the source text."
      technicalStatus := "NonEntailmentStatus.certified"
      technicalEvidence := "Lean-checked countermodel evidence."
      technicalChecked := "Lean checked the assumptions true and the target false."
    }
  | .notEstablished, _ => {
      icon := "○"
      heading := "Non-entailment not established"
      sentence1 :=
        "No checked counterexample shows all alternative assumptions holding \
         while the conclusion is false."
      sentence2 :=
        "Rechecking one preserved deduction does not settle whether another \
         deduction could reach the conclusion."
      reference := ""
      boundary := "No entailment or non-entailment claim is made."
      technicalStatus := "NonEntailmentStatus.notEstablished"
      technicalEvidence :=
        "No accepted countermodel or complete procedure is present."
      technicalChecked :=
        "The preserved deduction was re-elaborated separately; its result does not \
         establish general non-derivability."
    }

def contextualInconsistencyPanelData
    (result : InconsistencyResult)
    (recheck : RecheckSummaryData) : EvidencePanelData :=
  let panel := inconsistencyPanelData result
  if result.status == .witnessed && recheck.unaffected then
    { panel with
      sentence2 :=
        "This contradiction comes from Claims in the alternative assumption set, \
         not from rechecking the preserved deduction."
      boundary :=
        "The alternative reconstruction is internally inconsistent. The \
         preserved deduction remains accepted because it does not use the \
         changed claim." }
  else
    panel

private def panelJson (panel : EvidencePanelData) : Json :=
  Json.mkObj [
    ("icon", Json.str panel.icon),
    ("heading", Json.str panel.heading),
    ("sentence1", Json.str panel.sentence1),
    ("sentence2", Json.str panel.sentence2),
    ("reference", Json.str panel.reference),
    ("boundary", Json.str panel.boundary),
    ("technicalStatus", Json.str panel.technicalStatus),
    ("technicalEvidence", Json.str panel.technicalEvidence),
    ("technicalChecked", Json.str panel.technicalChecked)
  ]

private def recheckJson (summary : RecheckSummaryData) : Json :=
  Json.mkObj [
    ("heading", Json.str summary.heading),
    ("detail", Json.str summary.detail),
    ("accepted", Json.bool summary.accepted),
    ("unaffected", Json.bool summary.unaffected)
  ]

private def capabilityJson (panel : CapabilityHelpData) : Json :=
  Json.mkObj [
    ("heading", Json.str panel.heading),
    ("inconsistency", Json.str panel.inconsistency),
    ("nonEntailment", Json.str panel.nonEntailment),
    ("boundary", Json.str panel.boundary),
    ("technicalInconsistency", Json.str panel.technicalInconsistency),
    ("technicalNonEntailment", Json.str panel.technicalNonEntailment),
    ("roadmap", Json.str panel.roadmap)
  ]

private def changesJson (changes : Array MeaningChange) : Json :=
  Json.arr <| changes.map fun change =>
    Json.mkObj [
      ("label", Json.str change.claim.toString),
      ("text", Json.str s!"{change.original.render} → {change.alternative.render}")
    ]

private def objectionsJson (objections : Array Objection) : Json :=
  Json.arr <| objections.map fun objection =>
    Json.mkObj [
      ("label", Json.str s!"{objection.name} about {objection.target}"),
      ("text", Json.str objection.statement)
    ]

def negativeEvidenceKind
    (profile : Name)
    (status : NonEntailmentStatus) : String :=
  if status != .certified then
    "no finite-model counterexample"
  else if profile == `ModalK then
    "model-analyzed finite Kripke counterexample"
  else if profile == `Counterfactual then
    "model-analyzed finite counterfactual counterexample"
  else
    "finite predicate counterexample"

def diagnosticsProps
    (notebook : Notebook)
    (deduction : Deduction)
    (originalStatus alternativeStatus : DeductionStatus)
    (inconsistency : InconsistencyResult)
    (nonEntailment : NonEntailmentResult) : Json :=
  let recheck := recheckSummaryData deduction notebook.alternative alternativeStatus
  let evidenceKind := negativeEvidenceKind notebook.profile nonEntailment.status
  Json.mkObj [
    ("argument", Json.str notebook.name.toString),
    ("profile", Json.str notebook.profile.toString),
    ("model", match notebook.model? with
      | some modelData => Json.str modelData.name.toString
      | none => Json.null),
    ("originalStatus", Json.str (originalStatusJson originalStatus)),
    ("evidenceKind", Json.str evidenceKind),
    ("recheck", recheckJson recheck),
    ("inconsistency",
      panelJson (contextualInconsistencyPanelData inconsistency recheck)),
    ("nonEntailment", panelJson (nonEntailmentPanelData nonEntailment)),
    ("capabilities", capabilityJson (capabilityHelpData notebook.profile)),
    ("deltas", changesJson notebook.alternative.changes),
    ("objections", objectionsJson notebook.alternative.objections),
    ("boundary", Json.str
      "This checks the stated reconstruction. It does not verify the source text \
       or the truth of its assumptions.")
  ]

def saveDiagnosticsPanel
    (notebook : Notebook)
    (deduction : Deduction)
    (originalStatus alternativeStatus : DeductionStatus)
    (inconsistency : InconsistencyResult)
    (nonEntailment : NonEntailmentResult) : CommandElabM Unit := do
  liftCoreM <| Widget.savePanelWidgetInfo dialecticDiagnosticsWidget.javascriptHash
    (pure <| diagnosticsProps notebook deduction originalStatus alternativeStatus
      inconsistency nonEntailment)
    notebook.ref

end Dialectic
