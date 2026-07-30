import Lean

/-!
Readable surface grammar. Newlines guide formatting in VS Code, while explicit
section endings keep parsing deterministic and diagnostics source-local.
-/

namespace Dialectic.Surface

declare_syntax_cat cnlName
syntax ident : cnlName
syntax "Original" : cnlName
syntax "Alternative" : cnlName
syntax "Source" : cnlName
syntax "Reconstruction" : cnlName
syntax "Counterfactual" : cnlName

declare_syntax_cat cnlMeaning
syntax "Every" ident ident "is" ident : cnlMeaning
syntax "Every" ident ident "is" "not" ident : cnlMeaning
syntax "No" ident ident "is" ident : cnlMeaning
syntax "Some" ident ident "is" ident : cnlMeaning
syntax "Some" ident ident "is" "not" ident : cnlMeaning
syntax "In" "every" "possible" "world" ident "is" ident : cnlMeaning
syntax "In" "some" "possible" "world" ident "is" ident : cnlMeaning
syntax "In" "every" "possible" "world" "if" ident "is" ident
  "then" ident "is" ident : cnlMeaning
syntax "If" "it" "were" "the" "case" "that" ident "is" ident ","
  "then" ident "is" ident : cnlMeaning
syntax "If" "it" "were" "the" "case" "that" ident "is" ident ","
  "then" ident "is" "not" ident : cnlMeaning

declare_syntax_cat cnlVocabularyEntry
syntax "Type" ident "called" ident : cnlVocabularyEntry
syntax "Object" ident "is" ident : cnlVocabularyEntry
syntax "Predicate" ident "describes" ident : cnlVocabularyEntry
syntax "Relation" ident "links" ident "to" ident : cnlVocabularyEntry

declare_syntax_cat cnlVocabulary
syntax "Vocabulary" ppLine
  cnlVocabularyEntry*
  "End" "vocabulary" : cnlVocabulary

declare_syntax_cat cnlSourceSentence
syntax "Sentence" num str : cnlSourceSentence

declare_syntax_cat cnlSource
syntax "Source" ident ppLine
  "Citation" str ppLine
  "Location" str ppLine
  cnlSourceSentence+
  "End" "source" : cnlSource

declare_syntax_cat cnlClaim
syntax "Claim" ident "from" ident "sentence" num ppLine
  "Paraphrase" str ppLine
  "Formal" "meaning" cnlMeaning ppLine
  "End" "claim" : cnlClaim

declare_syntax_cat cnlStep
syntax "Step" ident ppLine
  "From" ident "and" ident "conclude" ident : cnlStep

declare_syntax_cat cnlDeduction
syntax "Deduction" ident ppLine
  cnlStep+
  "End" "deduction" : cnlDeduction

declare_syntax_cat cnlReconstruction
syntax "Reconstruction" cnlName ppLine
  cnlClaim+
  cnlDeduction+
  "End" "reconstruction" : cnlReconstruction

declare_syntax_cat cnlChange
syntax "Change" ident ppLine
  "Original" "meaning" cnlMeaning ppLine
  "Alternative" "meaning" cnlMeaning ppLine
  "End" "change" : cnlChange

declare_syntax_cat cnlObjection
syntax "Objection" ident "about" ident ppLine
  "Statement" str ppLine
  "End" "objection" : cnlObjection

declare_syntax_cat cnlPredicateAssignment
syntax "Predicate" ident "holds" : cnlPredicateAssignment
syntax "Predicate" ident "does" "not" "hold" : cnlPredicateAssignment

declare_syntax_cat cnlCountermodelIndividual
syntax "Individual" ident ppLine
  cnlPredicateAssignment+ : cnlCountermodelIndividual

declare_syntax_cat cnlCountermodel
syntax "Countermodel" ident "for" ident ppLine
  cnlCountermodelIndividual+
  "End" "countermodel" : cnlCountermodel

declare_syntax_cat cnlModelWorld
syntax "Model" "world" ident ppLine
  cnlPredicateAssignment+
"End" "model" "world" : cnlModelWorld

declare_syntax_cat cnlModelEdge
syntax ident "reaches" ident : cnlModelEdge
syntax ident "selects" ident : cnlModelEdge

declare_syntax_cat cnlGroundAssignment
syntax ident "is" ident : cnlGroundAssignment
syntax ident "is" "not" ident : cnlGroundAssignment

declare_syntax_cat cnlModelState
syntax "Actual" "world" ident ppLine
  cnlGroundAssignment+
  "End" "world" : cnlModelState
syntax "Possible" "world" ident ppLine
  cnlGroundAssignment+
  "End" "world" : cnlModelState
syntax "Actual" "situation" ident ppLine
  cnlGroundAssignment+
  "End" "situation" : cnlModelState
syntax "Counterfactual" "situation" ident ppLine
  cnlGroundAssignment+
  "End" "situation" : cnlModelState

declare_syntax_cat cnlModelDescription
declare_syntax_cat cnlAccessibilityBlock
syntax "Accessibility" ppLine
  cnlModelEdge*
  "End" "accessibility" : cnlAccessibilityBlock
declare_syntax_cat cnlSelectionBlock
syntax "Closest" "situations" ppLine
  cnlModelEdge+
  "End" "closest" "situations" : cnlSelectionBlock
syntax "Model" ident ppLine
  cnlModelState+
  (cnlAccessibilityBlock ppLine)?
  (cnlSelectionBlock ppLine)?
  "End" "model" : cnlModelDescription

declare_syntax_cat cnlModelAnalysis
syntax "Analyze" "model" ident "for" ident : cnlModelAnalysis

declare_syntax_cat cnlModalCountermodel
syntax "Modal" "countermodel" ident "for" ident ppLine
  "Designated" "world" ident ppLine
  cnlModelWorld+
  "Accessibility" ppLine
    cnlModelEdge*
  "End" "accessibility" ppLine
  "End" "modal" "countermodel" : cnlModalCountermodel

declare_syntax_cat cnlCounterfactualCountermodel
syntax "Counterfactual" "countermodel" ident "for" ident ppLine
  "Actual" "world" ident ppLine
  cnlModelWorld+
  "Closest" "selection" ppLine
    cnlModelEdge+
  "End" "selection" ppLine
  "End" "counterfactual" "countermodel" : cnlCounterfactualCountermodel

declare_syntax_cat cnlAlternative
syntax "Alternative" ident "based" "on" cnlName ppLine
  cnlChange+
  "Recheck" "the" "same" "deduction" ident ppLine
  (cnlCountermodel)?
  (cnlModalCountermodel)?
  (cnlCounterfactualCountermodel)?
  (cnlModelAnalysis)?
  cnlObjection*
  "End" "alternative" : cnlAlternative

syntax (name := cnlArgument)
  "Argument" ident ppLine
  "Logic" "profile" cnlName ppLine
    "Description" str ppLine
  "End" "logic" ppLine
  cnlVocabulary ppLine
  (cnlModelDescription ppLine)?
  cnlSource ppLine
  cnlReconstruction ppLine
  cnlAlternative ppLine
  "End" "argument" : command

end Dialectic.Surface
