import Dialectic.Tests.Fixtures.ConflictingInterpretation
import Dialectic.Tests.Fixtures.SkepticalWarrant

open Dialectic
open Lean Elab Command

#guard ConflictingInterpretation_Original_deductionStatus == .accepted
#guard ConflictingInterpretation_IndependentConflict_deductionStatus == .accepted
#guard
  ConflictingInterpretation_IndependentConflict_inconsistencyStatus == .witnessed
#guard
  ConflictingInterpretation_IndependentConflict_nonEntailmentStatus ==
    .notEstablished

#guard SkepticalWarrant_Original_deductionStatus == .accepted
#guard SkepticalWarrant_SkepticalReading_deductionStatus == .rejected
#guard SkepticalWarrant_SkepticalReading_inconsistencyStatus == .notWitnessed
#guard SkepticalWarrant_SkepticalReading_nonEntailmentStatus == .certified

#guard DiagnosticCategory.nonEntailmentCertified.code ==
  "NONENTAILMENT/CERTIFIED"
#guard DiagnosticCategory.nonEntailmentNotEstablished.code ==
  "NONENTAILMENT/NOT-ESTABLISHED"
#guard DiagnosticCategory.countermodelRejected.code ==
  "NONENTAILMENT/CERTIFICATE-REJECTED"

private def witnessedPanel := inconsistencyPanelData {
  status := .witnessed
  evidence? := Option.some {
    universalClaim := `P1
    existentialClaim := `P2
    participatingClaims := #[`P1, `P2]
    «deduction» := `AdmissibilityBridge
    target := `Conclusion
    proofMethod := "kernel-checked test witness"
  }
}

#guard witnessedPanel.icon == "⚠"
#guard witnessedPanel.heading == "Alternative assumptions are contradictory"
#guard witnessedPanel.sentence1 ==
  "The alternative assumptions cannot all hold together."
#guard witnessedPanel.reference == "The conflict uses Claims P1, P2."
#guard witnessedPanel.technicalStatus == "InconsistencyStatus.witnessed"
#guard witnessedPanel.technicalEvidence.startsWith
  "Contradiction check over the alternative premise set"
#guard witnessedPanel.technicalChecked ==
  "Lean elaborated the generated contradiction term against False and the kernel accepted it."

private def notWitnessedPanel := inconsistencyPanelData {
  status := .notWitnessed
  evidence? := Option.none
}

#guard notWitnessedPanel.heading == "No contradiction found"
#guard notWitnessedPanel.sentence1 ==
  "The available check found no contradiction."
#guard notWitnessedPanel.sentence2 ==
  "This does not show that the assumptions are consistent."
#guard notWitnessedPanel.technicalStatus ==
  "InconsistencyStatus.notWitnessed"
#guard notWitnessedPanel.technicalEvidence ==
  "No existential claim conflicts with a predicate reached through the available universal rules."

private def certifiedPanel := nonEntailmentPanelData {
  status := .certified
  evidence? := Option.some {
    certificate := `SkepticalBelief
    «deduction» := `WarrantBridge
    target := `Conclusion
    individuals := #[`sampleBelief]
    premiseClaims := #[`P1, `P2]
    modelSummary :=
      "sampleBelief: testimonyBased holds, primaFacieJustified holds, warranted does not hold"
    proofMethod := "kernel-checked test certificate"
  }
}

#guard certifiedPanel.icon == "⊭"
#guard certifiedPanel.heading == "Conclusion does not follow"
#guard certifiedPanel.sentence1 ==
  "A counterexample was found: all alternative assumptions hold, but the conclusion is false."
#guard certifiedPanel.sentence2 == "Lean checked the counterexample."
#guard certifiedPanel.reference ==
  "sampleBelief: testimonyBased holds, primaFacieJustified holds, warranted does not hold Target: Conclusion."
#guard certifiedPanel.boundary == ""
#guard certifiedPanel.technicalStatus == "NonEntailmentStatus.certified"

private def notEstablishedPanel := nonEntailmentPanelData {
  status := .notEstablished
  evidence? := Option.none
}

#guard notEstablishedPanel.heading == "Non-entailment not established"
#guard notEstablishedPanel.sentence1 ==
  "No checked counterexample has all alternative assumptions true and the conclusion false."
#guard notEstablishedPanel.boundary == ""
#guard notEstablishedPanel.technicalStatus ==
  "NonEntailmentStatus.notEstablished"

private def coreCapabilities := capabilityHelpData `CoreLogic

#guard coreCapabilities.heading == "What CoreLogic can check"
#guard coreCapabilities.inconsistency ==
  "Contradiction: a witness conflicts with a chain of universal rules."
#guard coreCapabilities.nonEntailment ==
  "Non-entailment: a supplied finite counterexample."
#guard coreCapabilities.technicalNonEntailment.contains
  "gives every declared unary predicate a value for each one"

private def modalCapabilities := capabilityHelpData `ModalK

#guard modalCapabilities.heading == "What ModalK can check"
#guard modalCapabilities.inconsistency ==
  "Contradiction: no check is implemented."
#guard modalCapabilities.nonEntailment ==
  "Non-entailment: a supplied finite Kripke counterexample."

private def counterfactualCapabilities := capabilityHelpData `Counterfactual

#guard counterfactualCapabilities.heading == "What Counterfactual can check"
#guard counterfactualCapabilities.nonEntailment ==
  "Non-entailment: a supplied counterfactual counterexample."
#guard negativeEvidenceKind `ModalK .certified ==
  "model-analyzed finite Kripke counterexample"
#guard negativeEvidenceKind `Counterfactual .certified ==
  "model-analyzed finite counterfactual counterexample"
#guard negativeEvidenceKind `ModalK .notEstablished ==
  "no finite-model counterexample"

private def dependencyDeduction : Dialectic.«Deduction» := {
  name := `AdmissibilityBridge
  steps := #[{
    name := `DiscussionFollows
    left := `P1
    right := `P3
    conclusion := `Conclusion
    ref := Syntax.missing
  }]
  ref := Syntax.missing
}

private def independentConflict : Dialectic.«Alternative» := {
  name := `IndependentConflict
  base := `Original
  changes := #[{
    «claim» := `P2
    original := .someIs `coherent `theory `admissible
    «alternative» := .someIsNot `coherent `theory `admissible
    ref := Syntax.missing
    alternativeRef := Syntax.missing
  }]
  recheck := `AdmissibilityBridge
  countermodel? := none
  objections := #[]
  ref := Syntax.missing
  recheckRef := Syntax.missing
}

private def independentRecheck :=
  recheckSummaryData dependencyDeduction independentConflict .accepted

#guard dependencyDeduction.baseDependencies == #[`P1, `P3]
#guard dependencyDeduction.stepNames == #[`DiscussionFollows]
#guard independentRecheck.unaffected
#guard independentRecheck.heading ==
  "This change does not affect this deduction."
#guard independentRecheck.detail ==
  "Deduction AdmissibilityBridge uses Claims P1 and P3 in Step \
   DiscussionFollows. Changed Claim P2 is not among them."

private def independentConflictPanel :=
  contextualInconsistencyPanelData {
    status := .witnessed
    evidence? := Option.some {
      universalClaim := `P1
      existentialClaim := `P2
      participatingClaims := #[`P1, `P2]
      «deduction» := `AdmissibilityBridge
      target := `Conclusion
      proofMethod := "kernel-checked test witness"
    }
  } independentRecheck

#guard independentConflictPanel.sentence2 ==
  "The contradiction comes from the alternative assumptions, not the recheck."
#guard independentConflictPanel.boundary ==
  "The deduction remains accepted because it does not use the changed claim."

private def affectedReading : Dialectic.«Alternative» :=
  { independentConflict with
    name := `AffectedReading
    changes := #[{
      «claim» := `P1
      original := .everyIs `coherent `theory `admissible
      «alternative» := .everyIsNot `coherent `theory `admissible
      ref := Syntax.missing
      alternativeRef := Syntax.missing
    }] }

private def affectedRecheck :=
  recheckSummaryData dependencyDeduction affectedReading .rejected

#guard !affectedRecheck.unaffected
#guard affectedRecheck.heading ==
  "Deduction AdmissibilityBridge rejected under this alternative."
#guard affectedRecheck.detail.contains "Changed Claim P1 is among them."

#guard dialecticDiagnosticsWidget.javascript.contains
  "Alternative reconstruction"
#guard dialecticDiagnosticsWidget.javascript.contains
  "Contradictory assumptions"
#guard dialecticDiagnosticsWidget.javascript.contains "Non-entailment"
#guard dialecticDiagnosticsWidget.javascript.contains
  "Conclusion does not follow (counterexample found)"
#guard dialecticDiagnosticsWidget.javascript.contains
  "Original deduction under the alternative"
#guard dialecticDiagnosticsWidget.javascript.contains
  "These results concern the alternative assumptions."
#guard dialecticDiagnosticsWidget.javascript.contains "Negative evidence"
#guard dialecticDiagnosticsWidget.javascript.contains
  "No counterexample checked"
#guard dialecticDiagnosticsWidget.javascript.contains
  "props.evidenceKind"
#guard dialecticDiagnosticsWidget.javascript.contains
  "Only this deduction is rejected. Non-entailment needs a counterexample."
#guard dialecticDiagnosticsWidget.javascript.contains "#a371f7"

/--
info: [DIALECTIC/ALTERNATIVE/INCONSISTENCY] Alternative assumptions are contradictory in IndependentConflict: Claims P1, P2 cannot all hold together. This contradiction is in the alternative assumption set; it does not come from rechecking accepted Deduction 'AdmissibilityBridge'.
-/
#guard_msgs (info, substring := true) in
run_cmd
  logInfoAt (← getRef) <|
    diagnostic .alternativeInconsistency
      "Alternative assumptions are contradictory in IndependentConflict: \
       Claims P1, P2 cannot all hold together. This contradiction is in the \
       alternative assumption set; it does not come from rechecking accepted \
       Deduction 'AdmissibilityBridge'."

/--
info: [DIALECTIC/RECHECK/ACCEPTED] IndependentConflict: This change does not affect this deduction. Deduction AdmissibilityBridge uses Claims P1 and P3 in Step DiscussionFollows. Changed Claim P2 is not among them.
-/
#guard_msgs (info, substring := true) in
run_cmd
  logInfoAt (← getRef) <|
    diagnostic .preservedAccepted
      "IndependentConflict: This change does not affect this deduction. \
       Deduction AdmissibilityBridge uses Claims P1 and P3 in Step \
       DiscussionFollows. Changed Claim P2 is not among them."

/--
info: [DIALECTIC/NONENTAILMENT/CERTIFIED] Conclusion does not follow from SkepticalReading. Lean checked a concrete example where all alternative assumptions hold and Conclusion is false. The counterexample establishes non-entailment; rejection of one preserved deduction alone would not.
-/
#guard_msgs (info, substring := true) in
run_cmd
  logInfoAt (← getRef) <|
    diagnostic .nonEntailmentCertified
      "Conclusion does not follow from SkepticalReading. Lean checked a \
       concrete example where all alternative assumptions hold and Conclusion \
       is false. The counterexample establishes non-entailment; rejection of \
       one preserved deduction alone would not."
