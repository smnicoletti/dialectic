import Dialectic.Language

/--
error: [DIALECTIC/PARSE] Claim 'P1' links to missing source sentence 9
-/
#guard_msgs (error, substring := true) in
Argument MissingSourceLocation
Logic profile CoreLogic
  Description "validation fixture"
End logic
Vocabulary
  Type Thing called thing
  Predicate first describes Thing
  Predicate second describes Thing
End vocabulary
Source Fixture
  Citation "Invented validation fixture"
  Location "sentences 1–2"
  Sentence 1 "Every first thing is second."
  Sentence 2 "Every first thing is first."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 9
    Paraphrase "Every first thing is second."
    Formal meaning Every first thing is second
  End claim
  Claim C from Fixture sentence 2
    Paraphrase "Every first thing is first."
    Formal meaning Every first thing is first
  End claim
  Deduction BrokenLink
    Step Bridge
      From P1 and P1 conclude C
  End deduction
End reconstruction
Alternative SameReading based on Original
  Change P1
    Original meaning Every first thing is second
    Alternative meaning Some first thing is second
  End change
  Recheck the same deduction BrokenLink
End alternative
End argument
