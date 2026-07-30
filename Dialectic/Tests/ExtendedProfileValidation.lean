import Dialectic.Language

open Dialectic

/--
error: [DIALECTIC/PROFILE] this modal phrase is unavailable under CoreLogic
-/
#guard_msgs (error, substring := true) in
Argument CounterfactualKeywordUnderCore
Logic profile CoreLogic
  Description "profile-gating regression"
End logic
Vocabulary
  Type Case called scenario
  Object testCase is Case
  Predicate antecedent describes Case
  Predicate consequent describes Case
End vocabulary
Source Fixture
  Citation "Invented regression fixture"
  Location "sentences 1–3"
  Sentence 1 "Counterfactual premise."
  Sentence 2 "Universal bridge."
  Sentence 3 "Conclusion."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "Counterfactual premise."
    Formal meaning If it were the case that testCase is antecedent, then testCase is consequent
  End claim
  Claim P2 from Fixture sentence 2
    Paraphrase "Every antecedent scenario is consequent."
    Formal meaning Every antecedent scenario is consequent
  End claim
  Claim Conclusion from Fixture sentence 3
    Paraphrase "Every antecedent scenario is consequent."
    Formal meaning Every antecedent scenario is consequent
  End claim
  Deduction Test
    Step TestStep
      From P2 and P2 conclude Conclusion
  End deduction
End reconstruction
Alternative Changed based on Original
  Change P2
    Original meaning Every antecedent scenario is consequent
    Alternative meaning Every antecedent scenario is not consequent
  End change
  Recheck the same deduction Test
End alternative
End argument

/--
error: [DIALECTIC/MODEL] unknown selection target state 'missing'
-/
#guard_msgs (error, substring := true) in
Argument UnknownSelectedWorld
Logic profile Counterfactual
  Description "finite selected-world validation regression"
End logic
Vocabulary
  Type Case called scenario
  Object testCase is Case
  Predicate p describes Case
  Predicate q describes Case
  Predicate r describes Case
End vocabulary
Model BadSelection
  Actual situation actual
    testCase is p
    testCase is not q
    testCase is not r
  End situation
  Counterfactual situation considered
    testCase is p
    testCase is not q
    testCase is not r
  End situation
  Closest situations
    actual selects missing
  End closest situations
End model
Source Fixture
  Citation "Invented regression fixture"
  Location "sentences 1–3"
  Sentence 1 "If p were so, q would be so."
  Sentence 2 "If q were so, r would be so."
  Sentence 3 "If p were so, r would be so."
End source
Reconstruction Original
  Claim P1 from Fixture sentence 1
    Paraphrase "If p were so, q would be so."
    Formal meaning If it were the case that testCase is p, then testCase is q
  End claim
  Claim P2 from Fixture sentence 2
    Paraphrase "If q were so, r would be so."
    Formal meaning If it were the case that testCase is q, then testCase is r
  End claim
  Claim Conclusion from Fixture sentence 3
    Paraphrase "If p were so, r would be so."
    Formal meaning If it were the case that testCase is p, then testCase is r
  End claim
  Deduction Chain
    Step Result
      From P1 and P2 conclude Conclusion
  End deduction
End reconstruction
Alternative Negative based on Original
  Change P1
    Original meaning If it were the case that testCase is p, then testCase is q
    Alternative meaning If it were the case that testCase is p, then testCase is not q
  End change
  Recheck the same deduction Chain
  Analyze model BadSelection for Conclusion
End alternative
End argument
