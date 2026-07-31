import Dialectic.Language

/-!
Open this notebook with the standard Lean VS Code extension and place the
cursor on `Continue deduction`. The Infoview shows the live deduction state.
`GalileoShip.lean` contains the completed counterpart.
-/

Argument GalileoShipDraft

Logic profile CoreLogic
  Description "a work-in-progress reconstruction of the below-decks ship comparison"
End logic

Vocabulary
  Type Trial called trial
  Predicate describedBelowDeck describes Trial
  Predicate satisfiesStipulations describes Trial
  Predicate sameInternalOutcome describes Trial
  Predicate nonDiscriminating describes Trial
End vocabulary

Source GalileoShipPassage
  Citation "Galileo Galilei, Dialogo sopra i due massimi sistemi del mondo (Florence, 1632), Second Day; original paraphrases based on the Smithsonian Libraries public-domain/CC0 scan, not a settled translation"
  Location "Second Day, Salviati's enclosed below-decks ship comparison, from the listed internal phenomena through the conclusion for uniform nonfluctuating motion"
  Sentence 1 "The described trials are conducted inside the ship and under the comparison's stipulated isolation and motion conditions."
  Sentence 2 "A trial satisfying those stipulations has the same internal outcome while the ship is at rest and while it moves uniformly without fluctuation."
  Sentence 3 "For this reconstruction, a trial with the same internal outcome in those two cases does not discriminate rest from uniform shared motion."
  Sentence 4 "The described below-decks trials have the same internal outcomes in the two stipulated cases."
  Sentence 5 "Within the stipulated setting, the described below-decks trials do not distinguish uniform motion from rest."
End source

Reconstruction Original
  Claim P1 from GalileoShipPassage sentence 1
    Paraphrase "Every described below-decks trial satisfies the stipulated isolation and motion conditions."
    Formal meaning Every describedBelowDeck trial is satisfiesStipulations
  End claim

  Claim P2 from GalileoShipPassage sentence 2
    Paraphrase "Every trial satisfying the stipulations has the same internal outcome at rest and in uniform shared motion."
    Formal meaning Every satisfiesStipulations trial is sameInternalOutcome
  End claim

  Claim P3 from GalileoShipPassage sentence 3
    Paraphrase "Every trial with the same internal outcome in the two cases is non-discriminating between them."
    Formal meaning Every sameInternalOutcome trial is nonDiscriminating
  End claim

  Claim DescribedOutcome from GalileoShipPassage sentence 4
    Paraphrase "Every described below-decks trial has the same internal outcome in the two stipulated cases."
    Formal meaning Every describedBelowDeck trial is sameInternalOutcome
  End claim

  Claim Conclusion from GalileoShipPassage sentence 5
    Paraphrase "Every described below-decks trial is non-discriminating between rest and uniform shared motion within the stipulated setting."
    Formal meaning Every describedBelowDeck trial is nonDiscriminating
  End claim

  Deduction ShipComparison
    Goal Conclusion
    Step OutcomeBridge
      From P1 and P2 conclude DescribedOutcome
    Continue deduction
  End deduction
End reconstruction

Alternative RestrictedStipulation based on Original
  Change P1
    Original meaning Every describedBelowDeck trial is satisfiesStipulations
    Alternative meaning Some describedBelowDeck trial is satisfiesStipulations
  End change

  Recheck the same deduction ShipComparison

  Objection ScopeOfIsolation about P1
    Statement "The stipulated enclosure and smooth motion may govern only the particular trials successfully idealized by the passage, rather than every trial classified by the reconstruction as described below-decks."
  End objection
End alternative

End argument
