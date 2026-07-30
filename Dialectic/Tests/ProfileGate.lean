import Dialectic.Language

/--
error: [DIALECTIC/PROFILE] this phrase is unavailable under ModalK
-/
#guard_msgs (error, substring := true) in
Argument FirstOrderPhraseUnderModal
Logic profile ModalK
  Description "relational modal logic K"
End logic
Vocabulary
  Type System called system
  Object testSystem is System
  Predicate stable describes System
  Predicate actual describes System
End vocabulary
Model TestModel
  Actual world here
    testSystem is stable
    testSystem is actual
  End world
End model
Source Fixture
  Citation "Invented profile-gating fixture"
  Location "sentences 1–3"
  Sentence 1 "Every stable realm is actual."
  Sentence 2 "Every actual realm is stable."
  Sentence 3 "Every stable realm is stable."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "Every stable realm is actual."
    Formal meaning Every stable realm is actual
  End claim
  Claim P2 from Fixture sentence 2
    Paraphrase "Every actual realm is stable."
    Formal meaning Every actual realm is stable
  End claim
  Claim C from Fixture sentence 3
    Paraphrase "Every stable realm is stable."
    Formal meaning Every stable realm is stable
  End claim
  Deduction ModalAttempt
    Step Bridge
      From P1 and P2 conclude C
  End deduction
End reconstruction
Alternative DifferentReading based on Original
  Change P2
    Original meaning Every actual realm is stable
    Alternative meaning Some actual realm is stable
  End change
  Recheck the same deduction ModalAttempt
End alternative
End argument

/--
error: [DIALECTIC/PROFILE] this modal phrase is unavailable under CoreLogic
-/
#guard_msgs (error, substring := true) in
Argument ModalPhraseUnderCore
Logic profile CoreLogic
  Description "constructive unary-predicate test"
End logic
Vocabulary
  Type World called realm
  Object testWorld is World
  Predicate stable describes World
  Predicate actual describes World
End vocabulary
Source Fixture
  Citation "Invented profile-gating fixture"
  Location "sentences 1–3"
  Sentence 1 "Stability holds in every possible world."
  Sentence 2 "Actuality holds in every possible world."
  Sentence 3 "Stability implies actuality in every possible world."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "Stability holds in every possible world."
    Formal meaning In every possible world testWorld is stable
  End claim
  Claim P2 from Fixture sentence 2
    Paraphrase "Actuality holds in every possible world."
    Formal meaning In every possible world testWorld is actual
  End claim
  Claim C from Fixture sentence 3
    Paraphrase "Stability implies actuality in every possible world."
    Formal meaning In every possible world if testWorld is stable then testWorld is actual
  End claim
  Deduction CoreAttempt
    Step Bridge
      From P1 and P2 conclude C
  End deduction
End reconstruction
Alternative DifferentReading based on Original
  Change P2
    Original meaning In every possible world testWorld is actual
    Alternative meaning In some possible world testWorld is actual
  End change
  Recheck the same deduction CoreAttempt
End alternative
End argument
