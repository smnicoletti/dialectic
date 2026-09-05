import Dialectic.Examples.AlgorithmicAccountability

open Dialectic

#guard AlgorithmicAccountability_Original_deductionStatus == .accepted
#guard AlgorithmicAccountability_LimitedReviewPolicy_deductionStatus == .rejected
#guard
  AlgorithmicAccountability_LimitedReviewPolicy_inconsistencyStatus == .notWitnessed
#guard
  AlgorithmicAccountability_LimitedReviewPolicy_nonEntailmentStatus == .certified
