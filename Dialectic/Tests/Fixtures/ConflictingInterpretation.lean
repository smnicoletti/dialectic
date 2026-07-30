import Dialectic.Language

/- Internal regression notebook for dependency-aware inconsistency reporting. -/

Argument ConflictingInterpretation

Logic profile CoreLogic
  Description "constructive reasoning over a reconstruction of interpretive admissibility"
End logic

Vocabulary
  Type Theory called theory
  Predicate coherent describes Theory
  Predicate admissible describes Theory
  Predicate discussable describes Theory
End vocabulary

Source SeminarPassage
  Citation "Invented philosophical-methodology passage; not a historical quotation"
  Location "sentences 1–4"
  Sentence 1 "Every coherent theory is admissible for discussion."
  Sentence 2 "At least one coherent theory is admissible."
  Sentence 3 "Every admissible theory is discussable."
  Sentence 4 "Every coherent theory is discussable."
End source

Reconstruction Original
  Claim P1 from SeminarPassage sentence 1
    Paraphrase "Every coherent theory is admissible."
    Formal meaning Every coherent theory is admissible
  End claim

  Claim P2 from SeminarPassage sentence 2
    Paraphrase "Some coherent theory is admissible."
    Formal meaning Some coherent theory is admissible
  End claim

  Claim P3 from SeminarPassage sentence 3
    Paraphrase "Every admissible theory is discussable."
    Formal meaning Every admissible theory is discussable
  End claim

  Claim Conclusion from SeminarPassage sentence 4
    Paraphrase "Every coherent theory is discussable."
    Formal meaning Every coherent theory is discussable
  End claim

  Deduction AdmissibilityBridge
    Step DiscussionFollows
      From P1 and P3 conclude Conclusion
  End deduction
End reconstruction

Alternative IndependentConflict based on Original
  Change P2
    Original meaning Some coherent theory is admissible
    Alternative meaning Some coherent theory is not admissible
  End change

  Recheck the same deduction AdmissibilityBridge

  Objection IndependentAssumptionConflict about P2
    Statement "This alternative is an inconsistency test. Its change to P2 conflicts with P1, but P2 is not used by AdmissibilityBridge; the contradiction therefore does not invalidate that deduction."
  End objection
End alternative

End argument
