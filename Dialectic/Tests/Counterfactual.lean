import Dialectic.Examples.CounterfactualMatch

open Dialectic

#check Counterfactual.conditional
#check Counterfactual.consequence
#guard CounterfactualMatch_Original_deductionStatus == .accepted
#guard CounterfactualMatch_DampMatch_deductionStatus == .rejected
#guard CounterfactualMatch_DampMatch_inconsistencyStatus == .notChecked
#guard CounterfactualMatch_DampMatch_nonEntailmentStatus == .certified
