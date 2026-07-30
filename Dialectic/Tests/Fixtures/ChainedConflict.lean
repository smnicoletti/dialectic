import Dialectic.Language

/- Internal regression notebook for chained contradiction detection. -/

Argument ChainedConflict

Logic profile CoreLogic
  Description "constructive unary reasoning with a chained contradiction witness"
End logic

Vocabulary
  Type Theory called theory
  Predicate coherent describes Theory
  Predicate defensible describes Theory
  Predicate admissible describes Theory
  Predicate discussable describes Theory
End vocabulary

Source ChainedConflictPassage
  Citation "Invented philosophical-methodology passage; not a historical quotation"
  Location "sentences 1–6"
  Sentence 1 "Every coherent theory is defensible."
  Sentence 2 "Every defensible theory is admissible."
  Sentence 3 "At least one coherent theory is admissible."
  Sentence 4 "Every admissible theory is discussable."
  Sentence 5 "Every coherent theory is admissible."
  Sentence 6 "Every coherent theory is discussable."
End source

Reconstruction Original
  Claim P1 from ChainedConflictPassage sentence 1
    Paraphrase "Every coherent theory is defensible."
    Formal meaning Every coherent theory is defensible
  End claim

  Claim P2 from ChainedConflictPassage sentence 2
    Paraphrase "Every defensible theory is admissible."
    Formal meaning Every defensible theory is admissible
  End claim

  Claim P3 from ChainedConflictPassage sentence 3
    Paraphrase "Some coherent theory is admissible."
    Formal meaning Some coherent theory is admissible
  End claim

  Claim P4 from ChainedConflictPassage sentence 4
    Paraphrase "Every admissible theory is discussable."
    Formal meaning Every admissible theory is discussable
  End claim

  Claim CoherentIsAdmissible from ChainedConflictPassage sentence 5
    Paraphrase "Every coherent theory is admissible."
    Formal meaning Every coherent theory is admissible
  End claim

  Claim Conclusion from ChainedConflictPassage sentence 6
    Paraphrase "Every coherent theory is discussable."
    Formal meaning Every coherent theory is discussable
  End claim

  Deduction DiscussionChain
    Step AdmissibilityBridge
      From P1 and P2 conclude CoherentIsAdmissible
    Step DiscussionBridge
      From CoherentIsAdmissible and P4 conclude Conclusion
  End deduction
End reconstruction

Alternative ExceptionalTheory based on Original
  Change P3
    Original meaning Some coherent theory is admissible
    Alternative meaning Some coherent theory is not admissible
  End change

  Recheck the same deduction DiscussionChain

  Objection ExceptionalCase about P3
    Statement "The passage may preserve one coherent exception to admissibility; if so, that reading conflicts with the two universal bridges rather than invalidating their Lean-checked composition."
  End objection
End alternative

End argument
