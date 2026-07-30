import Dialectic.Language

open Dialectic

Argument InconsistentAlternative

Logic profile CoreLogic
  Description "constructive unary-predicate test"
End logic

Vocabulary
  Type Action called action
  Predicate responsible describes Action
  Predicate answerable describes Action
  Predicate accountable describes Action
End vocabulary

Source TestPassage
  Citation "Invented regression fixture"
  Location "sentences 1–4"
  Sentence 1 "Every responsible action is answerable."
  Sentence 2 "Some responsible action is answerable."
  Sentence 3 "Every answerable action is accountable."
  Sentence 4 "Every responsible action is accountable."
End source

Reconstruction Original
  Claim P1 from TestPassage sentence 1
    Paraphrase "Every responsible action is answerable."
    Formal meaning Every responsible action is answerable
  End claim
  Claim P2 from TestPassage sentence 2
    Paraphrase "Some responsible action is answerable."
    Formal meaning Some responsible action is answerable
  End claim
  Claim P3 from TestPassage sentence 3
    Paraphrase "Every answerable action is accountable."
    Formal meaning Every answerable action is accountable
  End claim
  Claim C from TestPassage sentence 4
    Paraphrase "Every responsible action is accountable."
    Formal meaning Every responsible action is accountable
  End claim

  Deduction Accountability
    Step AccountabilityBridge
      From P1 and P3 conclude C
  End deduction
End reconstruction

Alternative NegativeWitness based on Original
  Change P2
    Original meaning Some responsible action is answerable
    Alternative meaning Some responsible action is not answerable
  End change
  Recheck the same deduction Accountability
End alternative

End argument

#guard InconsistentAlternative_Original_deductionStatus == .accepted
#guard InconsistentAlternative_NegativeWitness_deductionStatus == .accepted
#guard InconsistentAlternative_NegativeWitness_inconsistencyStatus == .witnessed
#guard InconsistentAlternative_NegativeWitness_nonEntailmentStatus == .notEstablished
