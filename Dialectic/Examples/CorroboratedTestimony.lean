import Dialectic.Language

Argument CorroboratedTestimony

Logic profile CoreLogic
  Description "constructive unary-predicate practice with an explicit two-step reconstruction"
End logic

Vocabulary
  Type Report called report
  Predicate independentlyCorroborated describes Report
  Predicate responsiblyAssessed describes Report
  Predicate credible describes Report
  Predicate primaFacieWarranting describes Report
End vocabulary

Source WorkshopScenario
  Citation "Invented classroom scenario for Dialectic"
  Location "Corroborated-testimony exercise, sentences 1-5"
  Sentence 1 "Every report supported by independent sources is responsibly assessed."
  Sentence 2 "Every responsibly assessed report is credible for the purpose of this exercise."
  Sentence 3 "Every credible report provides prima facie warrant for belief."
  Sentence 4 "Every independently corroborated report is credible."
  Sentence 5 "Every independently corroborated report provides prima facie warrant for belief."
End source

Reconstruction Original
  Claim P1 from WorkshopScenario sentence 1
    Paraphrase "Every independently corroborated report is responsibly assessed."
    Formal meaning Every independentlyCorroborated report is responsiblyAssessed
  End claim

  Claim P2 from WorkshopScenario sentence 2
    Paraphrase "Every responsibly assessed report is credible within the exercise."
    Formal meaning Every responsiblyAssessed report is credible
  End claim

  Claim P3 from WorkshopScenario sentence 3
    Paraphrase "Every credible report provides prima facie warrant for belief."
    Formal meaning Every credible report is primaFacieWarranting
  End claim

  Claim CredibilityBridge from WorkshopScenario sentence 4
    Paraphrase "Every independently corroborated report is credible."
    Formal meaning Every independentlyCorroborated report is credible
  End claim

  Claim Conclusion from WorkshopScenario sentence 5
    Paraphrase "Every independently corroborated report provides prima facie warrant for belief."
    Formal meaning Every independentlyCorroborated report is primaFacieWarranting
  End claim

  Deduction TestimonyWarrant
    Goal Conclusion
    Step CredibilityFollows
      From P1 and P2 conclude CredibilityBridge
    Step ConclusionFollows
      From CredibilityBridge and P3 conclude Conclusion
  End deduction
End reconstruction

Alternative LimitedCorroboration based on Original
  Change P1
    Original meaning Every independentlyCorroborated report is responsiblyAssessed
    Alternative meaning Some independentlyCorroborated report is responsiblyAssessed
  End change

  Recheck the same deduction TestimonyWarrant

  Objection ScopeOfCorroboration about P1
    Statement "The exercise may support responsible assessment for one assigned report without supporting the universal premise used by the original deduction."
  End objection
End alternative

End argument
