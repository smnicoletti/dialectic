import Dialectic.Language

/- Internal regression notebook for a one-individual countermodel. -/

Argument SkepticalWarrant

Logic profile CoreLogic
  Description "constructive unary-predicate reasoning with a finite countermodel certificate"
End logic

Vocabulary
  Type Belief called belief
  Predicate testimonyBased describes Belief
  Predicate primaFacieJustified describes Belief
  Predicate warranted describes Belief
End vocabulary

Source TestimonyVignette
  Citation "Invented epistemology vignette; not presented as a quotation from a historical source"
  Location "sentences 1–3"
  Sentence 1 "Every testimony-based belief is prima facie justified."
  Sentence 2 "Every prima facie justified belief is warranted."
  Sentence 3 "Every testimony-based belief is warranted."
End source

Reconstruction Original
  Claim P1 from TestimonyVignette sentence 1
    Paraphrase "Every testimony-based belief is prima facie justified."
    Formal meaning Every testimonyBased belief is primaFacieJustified
  End claim

  Claim P2 from TestimonyVignette sentence 2
    Paraphrase "Every prima facie justified belief is warranted."
    Formal meaning Every primaFacieJustified belief is warranted
  End claim

  Claim Conclusion from TestimonyVignette sentence 3
    Paraphrase "Every testimony-based belief is warranted."
    Formal meaning Every testimonyBased belief is warranted
  End claim

  Deduction WarrantBridge
    Step WarrantFollows
      From P1 and P2 conclude Conclusion
  End deduction
End reconstruction

Alternative SkepticalReading based on Original
  Change P2
    Original meaning Every primaFacieJustified belief is warranted
    Alternative meaning Every primaFacieJustified belief is not warranted
  End change

  Recheck the same deduction WarrantBridge

  Countermodel SkepticalBelief for Conclusion
    Individual sampleBelief
    Predicate testimonyBased holds
    Predicate primaFacieJustified holds
    Predicate warranted does not hold
  End countermodel

  Objection JustificationIsNotWarrant about P2
    Statement "A skeptical reconstruction separates prima facie justification from warrant; the countermodel tests that formal alternative without endorsing it as the source's true meaning."
  End objection
End alternative

End argument
