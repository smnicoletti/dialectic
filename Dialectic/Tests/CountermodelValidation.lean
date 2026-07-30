import Dialectic.Language

/--
error: [DIALECTIC/NONENTAILMENT/CERTIFICATE-REJECTED] The displayed finite model is not a counterexample
-/
#guard_msgs (error, substring := true) in
Argument RejectedCountermodel
Logic profile CoreLogic
  Description "countermodel rejection fixture"
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
Alternative SkepticalReading based on Original
  Change P2
    Original meaning Every justified belief is warranted
    Alternative meaning Every justified belief is not warranted
  End change
  Recheck the same deduction WarrantBridge
  Countermodel BadModel for Conclusion
    Individual sampleBelief
    Predicate testimonyBased holds
    Predicate justified holds
    Predicate warranted holds
  End countermodel
End alternative
End argument
