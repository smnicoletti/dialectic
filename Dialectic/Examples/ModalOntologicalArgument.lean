import Dialectic.Language

Argument ModalOntologicalArgument

Logic profile ModalK
  Description "a bounded K reconstruction inspired by modal ontological argumentation"
End logic

Vocabulary
  Type Being called being
  Object candidate is Being
  Predicate maximallyGreat describes Being
  Predicate existent describes Being
End vocabulary

Model OntologicalReading
  Actual world actual
    candidate is not maximallyGreat
    candidate is not existent
  End world
  Possible world greatWorld
    candidate is maximallyGreat
    candidate is existent
  End world
  Possible world absentWorld
    candidate is not maximallyGreat
    candidate is not existent
  End world
  Accessibility
    actual reaches greatWorld
    actual reaches absentWorld
    greatWorld reaches greatWorld
    absentWorld reaches greatWorld
  End accessibility
End model

Source PlantingaModalArgument
  Citation "Original bounded reconstruction inspired by Alvin Plantinga, The Nature of Necessity, Clarendon Press, 1974, chapter 10"
  Location "chapter 10, modal ontological argument; the S5-specific steps are excluded"
  Sentence 1 "In every possible world, maximal greatness implies existence."
  Sentence 2 "In every possible world, the candidate is maximally great."
  Sentence 3 "In every possible world, the candidate exists."
End source

Reconstruction Original
  Claim M1 from PlantingaModalArgument sentence 1
    Paraphrase "Necessarily, if the candidate is maximally great, then it exists."
    Formal meaning In every possible world if candidate is maximallyGreat then candidate is existent
  End claim

  Claim M2 from PlantingaModalArgument sentence 2
    Paraphrase "The candidate is maximally great in every possible world."
    Formal meaning In every possible world candidate is maximallyGreat
  End claim

  Claim Conclusion from PlantingaModalArgument sentence 3
    Paraphrase "The candidate exists in every possible world."
    Formal meaning In every possible world candidate is existent
  End claim

  Deduction NecessaryExistence
    Step NecessityFollows
      From M1 and M2 conclude Conclusion
  End deduction
End reconstruction

Alternative PossibleGreatness based on Original
  Change M2
    Original meaning In every possible world candidate is maximallyGreat
    Alternative meaning In some possible world candidate is maximallyGreat
  End change

  Recheck the same deduction NecessaryExistence

  Analyze model OntologicalReading for Conclusion

  Objection ModalStrength about M2
    Statement "Possibility does not supply the necessary premise used by this K-level deduction. This notebook does not reconstruct Plantinga's S5 argument or establish any premise about maximal greatness."
  End objection
End alternative

End argument
