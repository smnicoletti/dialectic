import Dialectic.Tests.Fixtures.ChainedConflict
import Dialectic.Tests.Fixtures.PluralTestimony

open Dialectic

#guard ChainedConflict_Original_deductionStatus == .accepted
#guard ChainedConflict_ExceptionalTheory_deductionStatus == .accepted
#guard ChainedConflict_ExceptionalTheory_inconsistencyStatus == .witnessed
#guard
  ChainedConflict_ExceptionalTheory_nonEntailmentStatus == .notEstablished

#guard PluralTestimony_Original_deductionStatus == .accepted
#guard PluralTestimony_MixedCases_deductionStatus == .rejected
#guard PluralTestimony_MixedCases_inconsistencyStatus == .notWitnessed
#guard PluralTestimony_MixedCases_nonEntailmentStatus == .certified

#guard capabilityMessage `CoreLogic ==
  "CoreLogic can check chained unary contradiction witnesses and author-supplied finite unary countermodels. Other cases remain unestablished."
#guard capabilityMessage `ModalK ==
  "ModalK can recheck box modus ponens and analyze a declared finite Kripke model for counterexamples. It adds no frame conditions and does not synthesize models."
#guard capabilityMessage `Counterfactual ==
  "Counterfactual can recheck its bounded selected-situation consequence rule and analyze declared actual/counterfactual models. It does not infer a closest-situation ordering."
