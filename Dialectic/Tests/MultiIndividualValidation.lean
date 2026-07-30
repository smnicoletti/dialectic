import Dialectic.Language

/--
error: [DIALECTIC/VOCAB] Countermodel Individual 'secondCase' must assign Vocabulary predicate 'warranted'
-/
#guard_msgs (error, substring := true) in
Argument IncompletePluralCountermodel
Logic profile CoreLogic
  Description "per-individual total-assignment validation fixture"
End logic
Vocabulary
  Type Belief called belief
  Predicate testimonyBased describes Belief
  Predicate justified describes Belief
  Predicate warranted describes Belief
End vocabulary
Source Fixture
  Citation "Invented regression fixture"
  Location "sentences 1–3"
  Sentence 1 "Every testimony-based belief is justified."
  Sentence 2 "Every justified belief is warranted."
  Sentence 3 "Every testimony-based belief is warranted."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "Every testimony-based belief is justified."
    Formal meaning Every testimonyBased belief is justified
  End claim
  Claim P2 from Fixture sentence 2
    Paraphrase "Every justified belief is warranted."
    Formal meaning Every justified belief is warranted
  End claim
  Claim Conclusion from Fixture sentence 3
    Paraphrase "Every testimony-based belief is warranted."
    Formal meaning Every testimonyBased belief is warranted
  End claim
  Deduction WarrantBridge
    Step WarrantFollows
      From P1 and P2 conclude Conclusion
  End deduction
End reconstruction
Alternative PluralReading based on Original
  Change P2
    Original meaning Every justified belief is warranted
    Alternative meaning Some justified belief is warranted
  End change
  Recheck the same deduction WarrantBridge
  Countermodel IncompleteModel for Conclusion
    Individual firstCase
      Predicate testimonyBased does not hold
      Predicate justified holds
      Predicate warranted holds
    Individual secondCase
      Predicate testimonyBased holds
      Predicate justified holds
  End countermodel
End alternative
End argument
