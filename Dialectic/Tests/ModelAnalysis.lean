import Dialectic.Examples.ModalOntologicalArgument
import Dialectic.Examples.CounterfactualMatch

open Dialectic

#guard DiagnosticCategory.model.code == "MODEL"
#guard ModalOntologicalArgument_Original_deductionStatus == .accepted
#guard ModalOntologicalArgument_PossibleGreatness_deductionStatus == .rejected
#guard
  ModalOntologicalArgument_PossibleGreatness_nonEntailmentStatus == .certified
#guard CounterfactualMatch_Original_deductionStatus == .accepted
#guard CounterfactualMatch_DampMatch_deductionStatus == .rejected
#guard CounterfactualMatch_DampMatch_nonEntailmentStatus == .certified

#guard (Meaning.modalEvery `shipTrial `stable).render ==
  "In every possible world shipTrial is stable"
#guard (Meaning.counterfactual `thisMatch `struck `lit).render ==
  "If it were the case that thisMatch is struck, then thisMatch is lit"

/--
error: [DIALECTIC/VOCAB] unknown ModalK Object 'otherSystem'; declare it in Vocabulary
-/
#guard_msgs (error, substring := true) in
Argument UndeclaredModelObject
Logic profile ModalK
  Description "object validation fixture"
End logic
Vocabulary
  Type System called system
  Object declaredSystem is System
  Predicate stable describes System
  Predicate observable describes System
End vocabulary
Model ObjectErrorModel
  Actual world actual
    otherSystem is stable
    declaredSystem is observable
  End world
End model
Source Fixture
  Citation "Invented model validation fixture"
  Location "sentences 1–3"
  Sentence 1 "Stable systems are observable in every world."
  Sentence 2 "The system is stable in every world."
  Sentence 3 "The system is observable in every world."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "Stable systems are observable in every world."
    Formal meaning In every possible world if declaredSystem is stable then declaredSystem is observable
  End claim
  Claim P2 from Fixture sentence 2
    Paraphrase "The system is stable in every world."
    Formal meaning In every possible world declaredSystem is stable
  End claim
  Claim Conclusion from Fixture sentence 3
    Paraphrase "The system is observable in every world."
    Formal meaning In every possible world declaredSystem is observable
  End claim
  Deduction Test
    Step Result
      From P1 and P2 conclude Conclusion
  End deduction
End reconstruction
Alternative Changed based on Original
  Change P2
    Original meaning In every possible world declaredSystem is stable
    Alternative meaning In some possible world declaredSystem is stable
  End change
  Recheck the same deduction Test
End alternative
End argument

Argument ModelWithoutCounterexample
Logic profile ModalK
  Description "model analysis can finish without negative evidence"
End logic
Vocabulary
  Type System called system
  Object sampleSystem is System
  Predicate stable describes System
  Predicate observable describes System
End vocabulary
Model SupportingModel
  Actual world actual
    sampleSystem is stable
    sampleSystem is observable
  End world
  Accessibility
    actual reaches actual
  End accessibility
End model
Source Fixture
  Citation "Invented model analysis fixture"
  Location "sentences 1–3"
  Sentence 1 "Stable systems are observable in every world."
  Sentence 2 "The system is stable in every world."
  Sentence 3 "The system is observable in every world."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "Stable systems are observable in every world."
    Formal meaning In every possible world if sampleSystem is stable then sampleSystem is observable
  End claim
  Claim P2 from Fixture sentence 2
    Paraphrase "The system is stable in every world."
    Formal meaning In every possible world sampleSystem is stable
  End claim
  Claim Conclusion from Fixture sentence 3
    Paraphrase "The system is observable in every world."
    Formal meaning In every possible world sampleSystem is observable
  End claim
  Deduction Test
    Step Result
      From P1 and P2 conclude Conclusion
  End deduction
End reconstruction
Alternative PossibleOnly based on Original
  Change P2
    Original meaning In every possible world sampleSystem is stable
    Alternative meaning In some possible world sampleSystem is stable
  End change
  Recheck the same deduction Test
  Analyze model SupportingModel for Conclusion
End alternative
End argument

#guard ModelWithoutCounterexample_Original_deductionStatus == .accepted
#guard ModelWithoutCounterexample_PossibleOnly_deductionStatus == .rejected
#guard
  ModelWithoutCounterexample_PossibleOnly_nonEntailmentStatus ==
    .notEstablished
