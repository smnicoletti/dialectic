import Dialectic.Language

Argument GettierCounterexample

Logic profile CoreLogic
  Description "constructive unary reasoning over a bounded reconstruction of the justified-true-belief analysis"
End logic

Vocabulary
  Type Belief called belief
  Predicate gettierCase describes Belief
  Predicate justifiedTrue describes Belief
  Predicate knowledge describes Belief
End vocabulary

Source GettierCaseI
  Citation "Edmund L. Gettier, Is Justified True Belief Knowledge?, Analysis 23(6), 1963, pp. 121-122; the sentences below are original abstractions, not quotations"
  Location "the preliminary justified-true-belief analysis and Case I, excluding Case II"
  Sentence 1 "Every belief represented as a Gettier case is justified and true."
  Sentence 2 "Every justified and true belief counts as knowledge."
  Sentence 3 "Every belief represented as a Gettier case counts as knowledge."
End source

Reconstruction Original
  Claim P1 from GettierCaseI sentence 1
    Paraphrase "Every belief in the modeled Gettier case is justified and true."
    Formal meaning Every gettierCase belief is justifiedTrue
  End claim

  Claim P2 from GettierCaseI sentence 2
    Paraphrase "Every justified and true belief is knowledge."
    Formal meaning Every justifiedTrue belief is knowledge
  End claim

  Claim Conclusion from GettierCaseI sentence 3
    Paraphrase "Every belief in the modeled Gettier case is knowledge."
    Formal meaning Every gettierCase belief is knowledge
  End claim

  Deduction JustifiedTrueBeliefAnalysis
    Step KnowledgeFollows
      From P1 and P2 conclude Conclusion
  End deduction
End reconstruction

Alternative GettierReading based on Original
  Change P2
    Original meaning Every justifiedTrue belief is knowledge
    Alternative meaning Some justifiedTrue belief is not knowledge
  End change

  Recheck the same deduction JustifiedTrueBeliefAnalysis

  Countermodel CaseIBelief for Conclusion
    Individual caseIBelief
      Predicate gettierCase holds
      Predicate justifiedTrue holds
      Predicate knowledge does not hold
  End countermodel

  Objection CoarseAbstraction about P1
    Statement "The predicate justifiedTrue compresses belief, justification, and truth into one declared category. It records the counterexample shape but does not formalize Gettier's disjunction or theory of knowledge."
  End objection
End alternative

End argument
