import Dialectic.Language

open Dialectic
open Lean Elab Command

#guard DiagnosticCategory.parseSection.code == "PARSE"
#guard DiagnosticCategory.vocabulary.code == "VOCAB"
#guard DiagnosticCategory.profile.code == "PROFILE"
#guard DiagnosticCategory.deductionAccepted.code == "CHECK/ACCEPTED"
#guard DiagnosticCategory.preservedRejected.code == "RECHECK/REJECTED"
#guard DiagnosticCategory.alternativeInconsistency.code ==
  "ALTERNATIVE/INCONSISTENCY"
#guard DiagnosticCategory.nonEntailment.code == "NONENTAILMENT"
#guard DiagnosticCategory.capability.code == "CAPABILITY"
#guard DiagnosticCategory.delta.code == "DELTA"
#guard DiagnosticCategory.interpretive.code == "INTERPRETIVE"

/--
@ +19:19...47
error: [DIALECTIC/VOCAB] unknown CoreLogic predicate 'missing'; declare it in Vocabulary
-/
#guard_msgs (error, positions := true) in
Argument LocatedVocabularyError
Logic profile CoreLogic
  Description "source-location regression fixture"
End logic
Vocabulary
  Type Thing called thing
  Predicate first describes Thing
  Predicate second describes Thing
End vocabulary
Source Fixture
  Citation "Invented diagnostics fixture"
  Location "sentences 1–2"
  Sentence 1 "Every first thing is missing."
  Sentence 2 "Every first thing is second."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "Every first thing is missing."
    Formal meaning Every first thing is missing
  End claim
  Claim C from Fixture sentence 2
    Paraphrase "Every first thing is second."
    Formal meaning Every first thing is second
  End claim
  Deduction VocabularyCheck
    Step Bridge
      From P1 and P1 conclude C
  End deduction
End reconstruction
Alternative ChangedReading based on Original
  Change P1
    Original meaning Every first thing is missing
    Alternative meaning Some first thing is missing
  End change
  Recheck the same deduction VocabularyCheck
End alternative
End argument

/--
@ +31:2...+34:15
info: [DIALECTIC/CHECK/ACCEPTED] Original: Deduction 'LifecycleCheck' follows under this reconstruction and the CoreLogic profile. This does not assess the assumptions or source text.
---
@ +41:29...43
warning: [DIALECTIC/RECHECK/REJECTED] ExistentialPremise: Deduction LifecycleCheck rejected under this alternative. Deduction LifecycleCheck uses Claims P1 and P2 in Step Bridge. Changed Claim P2 is among them. This rejects only the preserved deduction. Non-entailment requires separate counterexample evidence.
-/
#guard_msgs (info, warning, positions := true, substring := true) in
Argument DiagnosticLifecycle
Logic profile CoreLogic
  Description "successful and alternative-recheck diagnostics fixture"
End logic
Vocabulary
  Type Thing called thing
  Predicate first describes Thing
  Predicate second describes Thing
  Predicate third describes Thing
End vocabulary
Source Fixture
  Citation "Invented diagnostics fixture"
  Location "sentences 1–3"
  Sentence 1 "Every first thing is second."
  Sentence 2 "Every second thing is third."
  Sentence 3 "Every first thing is third."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "Every first thing is second."
    Formal meaning Every first thing is second
  End claim
  Claim P2 from Fixture sentence 2
    Paraphrase "Every second thing is third."
    Formal meaning Every second thing is third
  End claim
  Claim C from Fixture sentence 3
    Paraphrase "Every first thing is third."
    Formal meaning Every first thing is third
  End claim
  Deduction LifecycleCheck
    Step Bridge
      From P1 and P2 conclude C
  End deduction
End reconstruction
Alternative ExistentialPremise based on Original
  Change P2
    Original meaning Every second thing is third
    Alternative meaning Some second thing is third
  End change
  Recheck the same deduction LifecycleCheck
  Objection Scope about P2
    Statement "The universal premise may be too strong."
  End objection
End alternative
End argument

#guard DiagnosticLifecycle_Original_deductionStatus == .accepted
#guard DiagnosticLifecycle_ExistentialPremise_deductionStatus == .rejected
#guard DiagnosticLifecycle_ExistentialPremise_inconsistencyStatus == .notWitnessed
#guard DiagnosticLifecycle_ExistentialPremise_nonEntailmentStatus == .notEstablished

/--
info: [DIALECTIC/CAPABILITY] CoreLogic can check chained unary contradiction witnesses and author-supplied finite unary countermodels. Other cases remain unestablished.
-/
#guard_msgs (info, substring := true) in
run_cmd
  logInfoAt (← getRef) <|
    diagnostic .capability (capabilityMessage `CoreLogic)

/--
info: [DIALECTIC/CAPABILITY] ModalK can recheck box modus ponens and analyze a declared finite Kripke model for counterexamples. It adds no frame conditions and does not synthesize models.
-/
#guard_msgs (info, substring := true) in
run_cmd
  logInfoAt (← getRef) <|
    diagnostic .capability (capabilityMessage `ModalK)
