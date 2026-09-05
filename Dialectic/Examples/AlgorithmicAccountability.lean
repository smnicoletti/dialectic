import Dialectic.Language

Argument AlgorithmicAccountability

Logic profile CoreLogic
  Description "constructive unary reasoning about review rights for automated decisions"
End logic

Vocabulary
  Type Decision called decision
  Predicate automated describes Decision
  Predicate highImpact describes Decision
  Predicate reviewable describes Decision
End vocabulary

Source ClassroomPolicyScenario
  Citation "Invented contemporary classroom scenario for Dialectic; not a quotation or statement of current law"
  Location "algorithmic accountability exercise, sentences 1–3"
  Sentence 1 "Every automated decision in the exercise is high impact."
  Sentence 2 "Every high-impact decision in the exercise is open to review."
  Sentence 3 "Every automated decision in the exercise is open to review."
End source

Reconstruction Original
  Claim P1 from ClassroomPolicyScenario sentence 1
    Paraphrase "Every automated decision is high impact."
    Formal meaning Every automated decision is highImpact
  End claim

  Claim P2 from ClassroomPolicyScenario sentence 2
    Paraphrase "Every high-impact decision is reviewable."
    Formal meaning Every highImpact decision is reviewable
  End claim

  Claim Conclusion from ClassroomPolicyScenario sentence 3
    Paraphrase "Every automated decision is reviewable."
    Formal meaning Every automated decision is reviewable
  End claim

  Deduction ReviewabilityBridge
    Step ReviewFollows
      From P1 and P2 conclude Conclusion
  End deduction
End reconstruction

Alternative LimitedReviewPolicy based on Original
  Change P2
    Original meaning Every highImpact decision is reviewable
    Alternative meaning Some highImpact decision is reviewable
  End change

  Recheck the same deduction ReviewabilityBridge

  Countermodel TwoDecisions for Conclusion
    Individual reviewedCase
      Predicate automated does not hold
      Predicate highImpact holds
      Predicate reviewable holds
    Individual disputedCase
      Predicate automated holds
      Predicate highImpact holds
      Predicate reviewable does not hold
  End countermodel

  Objection UnequalReviewAccess about P2
    Statement "A policy may make one high-impact decision reviewable without granting review for every high-impact decision. The two-decision model makes that scope difference explicit."
  End objection
End alternative

End argument
