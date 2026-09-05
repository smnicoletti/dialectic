import Dialectic.Language

/-!
Lean language-server regression input. Running this file with
`Lean.Server.Test.Runner` requests the stock editor code action at the draft
marker and exposes the versioned text edit in the response.
-/

Argument CorroboratedTestimonyServerDraft

Logic profile CoreLogic
  Description "server regression for the corroborated-testimony teaching exercise"
End logic

Vocabulary
  Type Report called report
  Predicate independentlyCorroborated describes Report
  Predicate responsiblyAssessed describes Report
  Predicate credible describes Report
End vocabulary

Source WorkshopScenario
  Citation "Invented classroom scenario for Dialectic"
  Location "Corroborated-testimony server exercise, sentences 1-3"
  Sentence 1 "Every independently corroborated report is responsibly assessed."
  Sentence 2 "Every responsibly assessed report is credible."
  Sentence 3 "Every independently corroborated report is credible."
End source

Reconstruction Original
  Claim P1 from WorkshopScenario sentence 1
    Paraphrase "Every independently corroborated report is responsibly assessed."
    Formal meaning Every independentlyCorroborated report is responsiblyAssessed
  End claim

  Claim P2 from WorkshopScenario sentence 2
    Paraphrase "Every responsibly assessed report is credible."
    Formal meaning Every responsiblyAssessed report is credible
  End claim

  Claim Conclusion from WorkshopScenario sentence 3
    Paraphrase "Every independently corroborated report is credible."
    Formal meaning Every independentlyCorroborated report is credible
  End claim

  Deduction TestimonyCredibility
    Goal Conclusion
    Continue deduction
    --^ codeAction
  End deduction
End reconstruction

Alternative LimitedCorroboration based on Original
  Change P1
    Original meaning Every independentlyCorroborated report is responsiblyAssessed
    Alternative meaning Some independentlyCorroborated report is responsiblyAssessed
  End change
  Recheck the same deduction TestimonyCredibility
End alternative

End argument
