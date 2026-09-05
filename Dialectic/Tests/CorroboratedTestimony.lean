import Dialectic.Examples.CorroboratedTestimony

open Dialectic

#guard CorroboratedTestimony_Original_deductionStatus == .accepted
#guard CorroboratedTestimony_LimitedCorroboration_deductionStatus == .rejected
#guard CorroboratedTestimony_LimitedCorroboration_inconsistencyStatus == .notWitnessed
#guard CorroboratedTestimony_LimitedCorroboration_nonEntailmentStatus == .notEstablished
