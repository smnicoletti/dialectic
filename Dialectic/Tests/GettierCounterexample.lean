import Dialectic.Examples.GettierCounterexample

open Dialectic

#guard GettierCounterexample_Original_deductionStatus == .accepted
#guard GettierCounterexample_GettierReading_deductionStatus == .rejected
#guard
  GettierCounterexample_GettierReading_inconsistencyStatus == .notWitnessed
#guard
  GettierCounterexample_GettierReading_nonEntailmentStatus == .certified
