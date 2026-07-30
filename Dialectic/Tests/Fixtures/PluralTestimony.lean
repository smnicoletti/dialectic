import Dialectic.Language

/- Internal regression notebook for a two-individual countermodel. -/

Argument PluralTestimony

Logic profile CoreLogic
  Description "constructive unary reasoning with a two-individual countermodel"
End logic

Vocabulary
  Type Belief called belief
  Predicate testimonyBased describes Belief
  Predicate primaFacieJustified describes Belief
  Predicate warranted describes Belief
End vocabulary

Source PluralTestimonyPassage
  Citation "Invented epistemological passage; not a historical quotation"
  Location "sentences 1–3"
  Sentence 1 "Every testimony-based belief is prima facie justified."
  Sentence 2 "Every prima facie justified belief is warranted."
  Sentence 3 "Every testimony-based belief is warranted."
End source

Reconstruction Original
  Claim P1 from PluralTestimonyPassage sentence 1
    Paraphrase "Every testimony-based belief is prima facie justified."
    Formal meaning Every testimonyBased belief is primaFacieJustified
  End claim

  Claim P2 from PluralTestimonyPassage sentence 2
    Paraphrase "Every prima facie justified belief is warranted."
    Formal meaning Every primaFacieJustified belief is warranted
  End claim

  Claim Conclusion from PluralTestimonyPassage sentence 3
    Paraphrase "Every testimony-based belief is warranted."
    Formal meaning Every testimonyBased belief is warranted
  End claim

  Deduction WarrantBridge
    Step TestimonyWarrant
      From P1 and P2 conclude Conclusion
  End deduction
End reconstruction

Alternative MixedCases based on Original
  Change P2
    Original meaning Every primaFacieJustified belief is warranted
    Alternative meaning Some primaFacieJustified belief is warranted
  End change

  Recheck the same deduction WarrantBridge

  Countermodel TwoBeliefs for Conclusion
    Individual supportingCase
      Predicate testimonyBased does not hold
      Predicate primaFacieJustified holds
      Predicate warranted holds
    Individual disputedCase
      Predicate testimonyBased holds
      Predicate primaFacieJustified holds
      Predicate warranted does not hold
  End countermodel

  Objection MixedPopulation about P2
    Statement "An existential warrant claim may concern one belief while a different testimony-based belief remains unwarranted; the two-individual model makes that separation explicit."
  End objection
End alternative

End argument
