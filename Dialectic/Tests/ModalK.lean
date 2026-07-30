import Dialectic.Examples.ModalOntologicalArgument

open Dialectic

#check ModalK.boxModusPonens
#guard ModalOntologicalArgument_Original_deductionStatus == .accepted
#guard ModalOntologicalArgument_PossibleGreatness_deductionStatus == .rejected
#guard
  ModalOntologicalArgument_PossibleGreatness_inconsistencyStatus == .notChecked
#guard
  ModalOntologicalArgument_PossibleGreatness_nonEntailmentStatus == .certified
