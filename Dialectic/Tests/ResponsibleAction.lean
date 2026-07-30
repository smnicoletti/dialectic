import Dialectic.Tests.Fixtures.ResponsibleAction

open Dialectic

#guard ResponsibleAction_Original_deductionStatus == .accepted
#guard ResponsibleAction_ExistentialChoice_deductionStatus == .rejected
#guard ResponsibleAction_ExistentialChoice_inconsistencyStatus == .notWitnessed
#guard ResponsibleAction_ExistentialChoice_nonEntailmentStatus == .notEstablished
