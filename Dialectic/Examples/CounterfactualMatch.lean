import Dialectic.Language

Argument CounterfactualMatch

Logic profile Counterfactual
  Description "bounded selected-situation semantics with an explicit actual situation"
End logic

Vocabulary
  Type Match called matchObject
  Object thisMatch is Match
  Predicate struck describes Match
  Predicate lit describes Match
  Predicate visible describes Match
End vocabulary

Model DampMatchModel
  Actual situation actual
    thisMatch is not struck
    thisMatch is not lit
    thisMatch is not visible
  End situation
  Counterfactual situation dampCase
    thisMatch is struck
    thisMatch is not lit
    thisMatch is not visible
  End situation
  Closest situations
    actual selects dampCase
  End closest situations
End model

Source LewisMatchScenario
  Citation "Original bounded reconstruction informed by David Lewis, Counterfactuals, Blackwell, 1973, pp. 1-2; no sentence below is a quotation"
  Location "opening discussion of counterfactual conditionals, represented by an original match scenario"
  Sentence 1 "Had the match been struck, it would have lit."
  Sentence 2 "Had it lit, its flame would have been visible."
  Sentence 3 "Had the match been struck, its flame would have been visible."
End source

Reconstruction Original
  Claim C1 from LewisMatchScenario sentence 1
    Paraphrase "If the match had been struck, it would have lit."
    Formal meaning If it were the case that thisMatch is struck, then thisMatch is lit
  End claim

  Claim C2 from LewisMatchScenario sentence 2
    Paraphrase "Across the same explicitly selected closest situations, lighting would make the flame visible."
    Formal meaning If it were the case that thisMatch is lit, then thisMatch is visible
  End claim

  Claim Conclusion from LewisMatchScenario sentence 3
    Paraphrase "If the match had been struck, its flame would have been visible."
    Formal meaning If it were the case that thisMatch is struck, then thisMatch is visible
  End claim

  Deduction CounterfactualConsequence
    Step VisibilityFollows
      From C1 and C2 conclude Conclusion
  End deduction
End reconstruction

Alternative DampMatch based on Original
  Change C1
    Original meaning If it were the case that thisMatch is struck, then thisMatch is lit
    Alternative meaning If it were the case that thisMatch is struck, then thisMatch is not lit
  End change

  Recheck the same deduction CounterfactualConsequence

  Analyze model DampMatchModel for Conclusion

  Objection SharedSelection about C2
    Statement "The model records the actual match and one selected damp counterfactual situation. Selection remains an interpretation choice; unrestricted similarity reasoning is not formalized."
  End objection
End alternative

End argument
