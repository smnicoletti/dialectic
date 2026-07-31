import Dialectic.Language

/-!
Lean language-server regression input for the exact incomplete form

```
Step
End deduction
```

The stock code-action request must return readable Dialectic syntax, including
an explicit Goal, without exposing a raw parser error.
-/

Argument CounterfactualDraftAction

Logic profile Counterfactual
  Description "bounded selected-situation deduction-state test"
End logic

Vocabulary
  Type Match called matchObject
  Object thisMatch is Match
  Predicate struck describes Match
  Predicate lit describes Match
  Predicate visible describes Match
End vocabulary

Model MatchModel
  Actual situation actual
    thisMatch is not struck
    thisMatch is not lit
    thisMatch is not visible
  End situation
  Counterfactual situation selected
    thisMatch is struck
    thisMatch is lit
    thisMatch is visible
  End situation
  Closest situations
    actual selects selected
  End closest situations
End model

Source MatchSource
  Citation "Original bounded counterfactual test scenario"
  Location "sentences 1-3"
  Sentence 1 "Had the match been struck, it would have lit."
  Sentence 2 "Had it lit, its flame would have been visible."
  Sentence 3 "Had the match been struck, its flame would have been visible."
End source

Reconstruction Original
  Claim C1 from MatchSource sentence 1
    Paraphrase "If struck, the match would light."
    Formal meaning If it were the case that thisMatch is struck, then thisMatch is lit
  End claim
  Claim C2 from MatchSource sentence 2
    Paraphrase "If lit, the match would be visible."
    Formal meaning If it were the case that thisMatch is lit, then thisMatch is visible
  End claim
  Claim Conclusion from MatchSource sentence 3
    Paraphrase "If struck, the match would be visible."
    Formal meaning If it were the case that thisMatch is struck, then thisMatch is visible
  End claim

  Deduction CounterfactualConsequence
    Step
    --^ widgets
    --^ codeAction
  End deduction
End reconstruction

Alternative DampReading based on Original
  Change C1
    Original meaning If it were the case that thisMatch is struck, then thisMatch is lit
    Alternative meaning If it were the case that thisMatch is struck, then thisMatch is not lit
  End change
  Recheck the same deduction CounterfactualConsequence
End alternative

End argument
