import Dialectic.Language

/- Internal regression notebook for the CoreLogic deduction lifecycle. -/

Argument ResponsibleAction

Logic profile CoreLogic
  Description "intuitionistic first-order reasoning encoded as constructive Lean propositions"
End logic

Vocabulary
  Type Action called action
  Predicate responsible describes Action
  Predicate deliberate describes Action
  Predicate chosen describes Action
  Predicate answerable describes Action
End vocabulary

Source ResponsibleActionPassage
  Citation "Invented demonstration passage; not presented as a historical quotation"
  Location "sentences 1–5"
  Sentence 1 "Every responsible action is deliberate."
  Sentence 2 "Every deliberate action is chosen."
  Sentence 3 "Every chosen action is answerable."
  Sentence 4 "Every responsible action is chosen."
  Sentence 5 "Every responsible action is answerable."
End source

Reconstruction Original
  Claim P1 from ResponsibleActionPassage sentence 1
    Paraphrase "Every responsible action is deliberate."
    Formal meaning Every responsible action is deliberate
  End claim

  Claim P2 from ResponsibleActionPassage sentence 2
    Paraphrase "Every deliberate action is chosen."
    Formal meaning Every deliberate action is chosen
  End claim

  Claim P3 from ResponsibleActionPassage sentence 3
    Paraphrase "Every chosen action is answerable."
    Formal meaning Every chosen action is answerable
  End claim

  Claim ResponsibleIsChosen from ResponsibleActionPassage sentence 4
    Paraphrase "Every responsible action is chosen."
    Formal meaning Every responsible action is chosen
  End claim

  Claim Conclusion from ResponsibleActionPassage sentence 5
    Paraphrase "Every responsible action is answerable."
    Formal meaning Every responsible action is answerable
  End claim

  Deduction ResponsibilityChain
    Step ChoiceBridge
      From P1 and P2 conclude ResponsibleIsChosen
    Step AnswerabilityBridge
      From ResponsibleIsChosen and P3 conclude Conclusion
  End deduction
End reconstruction

Alternative ExistentialChoice based on Original
  Change P2
    Original meaning Every deliberate action is chosen
    Alternative meaning Some deliberate action is chosen
  End change

  Recheck the same deduction ResponsibilityChain

  Objection UniversalForce about P2
    Statement "The second sentence may license only an existential reading, not the universal bridge used by the original reconstruction."
  End objection
End alternative

End argument
