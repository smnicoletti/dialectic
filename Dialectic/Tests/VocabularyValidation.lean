import Dialectic.Language

/--
error: [DIALECTIC/VOCAB] unknown CoreLogic predicate 'missing'; declare it in Vocabulary
-/
#guard_msgs (error, substring := true) in
Argument UndeclaredPredicate
Logic profile CoreLogic
  Description "undeclared-vocabulary regression fixture"
End logic
Vocabulary
  Type Thing called thing
  Predicate first describes Thing
  Predicate second describes Thing
End vocabulary
Source Fixture
  Citation "Invented validation fixture"
  Location "sentences 1–2"
  Sentence 1 "Every first thing is missing."
  Sentence 2 "Every first thing is second."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "Every first thing is missing."
    Formal meaning Every first thing is missing
  End claim
  Claim C from Fixture sentence 2
    Paraphrase "Every first thing is second."
    Formal meaning Every first thing is second
  End claim
  Deduction VocabularyCheck
    Step Bridge
      From P1 and P1 conclude C
  End deduction
End reconstruction
Alternative ChangedReading based on Original
  Change P1
    Original meaning Every first thing is missing
    Alternative meaning Some first thing is missing
  End change
  Recheck the same deduction VocabularyCheck
End alternative
End argument

/--
error: [DIALECTIC/VOCAB] unknown domain noun 'object'; Vocabulary declares 'thing'
-/
#guard_msgs (error, substring := true) in
Argument IncompatibleAlias
Logic profile CoreLogic
  Description "domain-alias regression fixture"
End logic
Vocabulary
  Type Thing called thing
  Predicate first describes Thing
  Predicate second describes Thing
End vocabulary
Source Fixture
  Citation "Invented validation fixture"
  Location "sentences 1–2"
  Sentence 1 "Every first object is second."
  Sentence 2 "Every first thing is second."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "Every first object is second."
    Formal meaning Every first object is second
  End claim
  Claim C from Fixture sentence 2
    Paraphrase "Every first thing is second."
    Formal meaning Every first thing is second
  End claim
  Deduction AliasCheck
    Step Bridge
      From P1 and P1 conclude C
  End deduction
End reconstruction
Alternative ChangedReading based on Original
  Change P1
    Original meaning Every first object is second
    Alternative meaning Some first object is second
  End change
  Recheck the same deduction AliasCheck
End alternative
End argument
