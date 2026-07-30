import Dialectic.Language.Ast
import Dialectic.Language.Diagnostic
import Dialectic.Language.SurfaceSyntax

namespace Dialectic

open Lean Elab Command
open Surface

private def throwParseErrorAt (ref : Syntax) (body : MessageData) :
    CommandElabM α :=
  throwErrorAt ref (diagnostic .parseSection body)

private def throwVocabularyErrorAt (ref : Syntax) (body : MessageData) :
    CommandElabM α :=
  throwErrorAt ref (diagnostic .vocabulary body)

private def parseName (stx : Syntax) : CommandElabM Name :=
  match stx with
  | `(cnlName| $name:ident) => pure name.getId
  | `(cnlName| Original) => pure `Original
  | `(cnlName| Alternative) => pure `Alternative
  | `(cnlName| Source) => pure `Source
  | `(cnlName| Reconstruction) => pure `Reconstruction
  | `(cnlName| Counterfactual) => pure `Counterfactual
  | _ => throwParseErrorAt stx "malformed notebook identifier"

private def parseMeaning (stx : Syntax) : CommandElabM Meaning :=
  match stx with
  | `(cnlMeaning| Every $subject:ident $noun:ident is $predicate:ident) =>
      pure <| .everyIs subject.getId noun.getId predicate.getId
  | `(cnlMeaning| Every $subject:ident $noun:ident is not $predicate:ident) =>
      pure <| .everyIsNot subject.getId noun.getId predicate.getId
  | `(cnlMeaning| No $subject:ident $noun:ident is $predicate:ident) =>
      pure <| .everyIsNot subject.getId noun.getId predicate.getId
  | `(cnlMeaning| Some $subject:ident $noun:ident is $predicate:ident) =>
      pure <| .someIs subject.getId noun.getId predicate.getId
  | `(cnlMeaning| Some $subject:ident $noun:ident is not $predicate:ident) =>
      pure <| .someIsNot subject.getId noun.getId predicate.getId
  | `(cnlMeaning| In every possible world $individual:ident is $predicate:ident) =>
      pure <| .modalEvery individual.getId predicate.getId
  | `(cnlMeaning| In some possible world $individual:ident is $predicate:ident) =>
      pure <| .modalSome individual.getId predicate.getId
  | `(cnlMeaning|
      In every possible world if $left:ident is $antecedent:ident
        then $right:ident is $consequent:ident) => do
      unless left.getId == right.getId do
        throwParseErrorAt stx
          "both sides of a modal implication must name the same Object"
      pure <| .modalEveryImp left.getId antecedent.getId consequent.getId
  | `(cnlMeaning|
      If it were the case that $left:ident is $antecedent:ident,
        then $right:ident is $consequent:ident) => do
      unless left.getId == right.getId do
        throwParseErrorAt stx
          "both sides of a counterfactual must name the same Object"
      pure <| .counterfactual left.getId antecedent.getId consequent.getId
  | `(cnlMeaning|
      If it were the case that $left:ident is $antecedent:ident,
        then $right:ident is not $consequent:ident) => do
      unless left.getId == right.getId do
        throwParseErrorAt stx
          "both sides of a counterfactual must name the same Object"
      pure <| .counterfactualNot left.getId antecedent.getId consequent.getId
  | _ => throwParseErrorAt stx "unsupported formal-meaning phrase"

private def parseVocabularyEntry
    (stx : Syntax) :
    CommandElabM
      (Sum TypeWord (Sum IndividualWord (Sum PredicateWord RelationWord))) :=
  match stx with
  | `(cnlVocabularyEntry| Type $leanName:ident called $noun:ident) =>
      pure <| .inl {
        leanName := leanName.getId
        noun := noun.getId
        ref := stx
      }
  | `(cnlVocabularyEntry| Object $name:ident is $domain:ident) =>
      pure <| .inr <| .inl {
        name := name.getId
        domain := domain.getId
        ref := stx
      }
  | `(cnlVocabularyEntry| Predicate $name:ident describes $domain:ident) =>
      pure <| .inr <| .inr <| .inl {
        name := name.getId
        domain := domain.getId
        ref := stx
      }
  | `(cnlVocabularyEntry|
      Relation $name:ident links $domain:ident to $range:ident) =>
      pure <| .inr <| .inr <| .inr {
        name := name.getId
        domain := domain.getId
        range := range.getId
        ref := stx
      }
  | _ => throwVocabularyErrorAt stx "unsupported vocabulary declaration"

private def parseVocabulary (stx : Syntax) :
    CommandElabM Dialectic.Vocabulary := do
  match stx with
  | `(cnlVocabulary| Vocabulary $entries:cnlVocabularyEntry* End vocabulary) =>
      let mut typeWord? : Option TypeWord := none
      let mut individuals := #[]
      let mut predicates := #[]
      let mut relations := #[]
      for entry in entries do
        match ← parseVocabularyEntry entry with
        | .inl typeWord =>
            if typeWord?.isSome then
              throwVocabularyErrorAt entry
                "the executable fragment supports exactly one Type declaration"
            typeWord? := Option.some typeWord
        | .inr (.inl predicate) =>
            individuals := individuals.push predicate
        | .inr (.inr (.inl predicate)) =>
            predicates := predicates.push predicate
        | .inr (.inr (.inr relationData)) =>
            relations := relations.push relationData
      let typeWord ← typeWord?.getDM <|
        throwVocabularyErrorAt stx "Vocabulary must contain one Type declaration"
      pure { typeWord, individuals, predicates, relations, ref := stx }
  | _ => throwParseErrorAt stx "malformed Vocabulary section"

private def parseSourceSentence
    (stx : Syntax) : CommandElabM SourceSentence :=
  match stx with
  | `(cnlSourceSentence| Sentence $number:num $text:str) =>
      pure { number := number.getNat, text := text.getString, ref := stx }
  | _ => throwParseErrorAt stx "malformed source sentence"

private def parseSource (stx : Syntax) : CommandElabM SourceRecord := do
  match stx with
  | `(cnlSource|
      Source $name:ident
        Citation $citation:str
        Location $location:str
        $sentences:cnlSourceSentence*
      End source) =>
      let parsed ← sentences.mapM parseSourceSentence
      if parsed.isEmpty then
        throwParseErrorAt stx "Source must contain at least one Sentence"
      pure {
        name := name.getId
        citation := citation.getString
        location := location.getString
        sentences := parsed
        ref := stx
      }
  | _ => throwParseErrorAt stx "malformed Source section"

private def parseClaim (stx : Syntax) :
    CommandElabM Dialectic.Claim :=
  match stx with
  | `(cnlClaim|
      Claim $name:ident from $sourceId:ident sentence $sentenceNo:num
        Paraphrase $paraphrase:str
        Formal meaning $meaningStx:cnlMeaning
      End claim) => do
      pure {
        name := name.getId
        «source» := sourceId.getId
        «sentence» := sentenceNo.getNat
        paraphrase := paraphrase.getString
        «meaning» := ← parseMeaning meaningStx
        ref := stx
        meaningRef := meaningStx
      }
  | _ => throwParseErrorAt stx "malformed Claim"

private def parseStep (stx : Syntax) : CommandElabM DeductionStep :=
  match stx with
  | `(cnlStep|
      Step $name:ident
        From $left:ident and $right:ident conclude $conclusion:ident) =>
      pure {
        name := name.getId
        left := left.getId
        right := right.getId
        conclusion := conclusion.getId
        ref := stx
      }
  | _ => throwParseErrorAt stx "malformed deduction Step"

private def parseDeduction (stx : Syntax) :
    CommandElabM Dialectic.Deduction := do
  match stx with
  | `(cnlDeduction|
      Deduction $name:ident
        $steps:cnlStep*
      End deduction) =>
      let parsed ← steps.mapM parseStep
      if parsed.isEmpty then
        throwParseErrorAt stx "Deduction must contain at least one Step"
      pure { name := name.getId, steps := parsed, ref := stx }
  | _ => throwParseErrorAt stx "malformed Deduction"

private def parseReconstruction
    (stx : Syntax) : CommandElabM Dialectic.Reconstruction := do
  match stx with
  | `(cnlReconstruction|
      Reconstruction $name:cnlName
        $claims:cnlClaim*
        $deductions:cnlDeduction*
      End reconstruction) =>
      let parsedClaims ← claims.mapM parseClaim
      let parsedDeductions ← deductions.mapM parseDeduction
      if parsedClaims.isEmpty then
        throwParseErrorAt stx "Reconstruction must contain at least one Claim"
      if parsedDeductions.isEmpty then
        throwParseErrorAt stx "Reconstruction must contain at least one Deduction"
      pure {
        name := ← parseName name
        claims := parsedClaims
        deductions := parsedDeductions
        ref := stx
      }
  | _ => throwParseErrorAt stx "malformed Reconstruction section"

private def parseChange (stx : Syntax) : CommandElabM MeaningChange :=
  match stx with
  | `(cnlChange|
      Change $claimId:ident
        Original meaning $originalMeaning:cnlMeaning
        Alternative meaning $alternativeMeaning:cnlMeaning
      End change) => do
      pure {
        «claim» := claimId.getId
        «original» := ← parseMeaning originalMeaning
        «alternative» := ← parseMeaning alternativeMeaning
        ref := stx
        alternativeRef := alternativeMeaning
      }
  | _ => throwParseErrorAt stx "malformed Change"

private def parseObjection (stx : Syntax) :
    CommandElabM Dialectic.Objection :=
  match stx with
  | `(cnlObjection|
      Objection $name:ident about $target:ident
        Statement $statement:str
      End objection) =>
      pure {
        name := name.getId
        target := target.getId
        statement := statement.getString
        ref := stx
      }
  | _ => throwParseErrorAt stx "malformed Objection"

private def parsePredicateAssignment
    (stx : Syntax) : CommandElabM PredicateAssignment :=
  match stx with
  | `(cnlPredicateAssignment| Predicate $predicate:ident holds) =>
      pure {
        predicate := predicate.getId
        value := .holds
        ref := stx
      }
  | `(cnlPredicateAssignment|
      Predicate $predicate:ident does not hold) =>
      pure {
        predicate := predicate.getId
        value := .doesNotHold
        ref := stx
      }
  | _ => throwParseErrorAt stx "malformed countermodel Predicate assignment"

private def parseCountermodelIndividual
    (stx : Syntax) : CommandElabM CountermodelIndividual :=
  match stx with
  | `(cnlCountermodelIndividual|
      Individual $individual:ident
        $assignments:cnlPredicateAssignment*) => do
      let parsed ← assignments.mapM parsePredicateAssignment
      if parsed.isEmpty then
        throwParseErrorAt stx
          "Countermodel Individual must assign at least one Vocabulary predicate"
      pure {
        name := individual.getId
        assignments := parsed
        ref := stx
      }
  | _ => throwParseErrorAt stx "malformed countermodel Individual"

private def parseCountermodel
    (stx : Syntax) : CommandElabM CountermodelCertificate :=
  match stx with
  | `(cnlCountermodel|
      Countermodel $name:ident for $target:ident
        $individuals:cnlCountermodelIndividual*
      End countermodel) => do
      let parsed ← individuals.mapM parseCountermodelIndividual
      if parsed.isEmpty then
        throwParseErrorAt stx
          "Countermodel must contain at least one Individual"
      pure {
        name := name.getId
        target := target.getId
        individuals := parsed
        ref := stx
        targetRef := target
      }
  | _ => throwParseErrorAt stx "malformed Countermodel certificate"

private def parseModelWorld (stx : Syntax) : CommandElabM ModelWorld :=
  match stx with
  | `(cnlModelWorld|
      Model world $name:ident
        $assignments:cnlPredicateAssignment*
      End model world) => do
      let parsed ← assignments.mapM parsePredicateAssignment
      if parsed.isEmpty then
        throwParseErrorAt stx "Model World must assign at least one Vocabulary predicate"
      pure { name := name.getId, assignments := parsed, ref := stx }
  | _ => throwParseErrorAt stx "malformed finite-model World"

private def parseReachabilityEdge (stx : Syntax) : CommandElabM ModelEdge :=
  match stx with
  | `(cnlModelEdge| $sourceId:ident reaches $targetId:ident) =>
      pure { «source» := sourceId.getId, target := targetId.getId, ref := stx }
  | _ => throwParseErrorAt stx "Accessibility entries must use 'world reaches world'"

private def parseSelectionEdge (stx : Syntax) : CommandElabM ModelEdge :=
  match stx with
  | `(cnlModelEdge| $sourceId:ident selects $targetId:ident) =>
      pure { «source» := sourceId.getId, target := targetId.getId, ref := stx }
  | _ => throwParseErrorAt stx "Selection entries must use 'world selects world'"

private def parseGroundAssignment
    (stx : Syntax) : CommandElabM GroundAssignment :=
  match stx with
  | `(cnlGroundAssignment| $individual:ident is $predicate:ident) =>
      pure {
        individual := individual.getId
        predicate := predicate.getId
        value := .holds
        ref := stx
      }
  | `(cnlGroundAssignment| $individual:ident is not $predicate:ident) =>
      pure {
        individual := individual.getId
        predicate := predicate.getId
        value := .doesNotHold
        ref := stx
      }
  | _ => throwParseErrorAt stx "malformed Model fact"

private def parseModelState (stx : Syntax) : CommandElabM ModelState := do
  let parseAssignments (name : Name) (kind : ModelStateKind)
      (assignments : Array Syntax) := do
    let parsed ← assignments.mapM parseGroundAssignment
    if parsed.isEmpty then
      throwParseErrorAt stx "each Model state must contain at least one fact"
    pure { name, kind, assignments := parsed, ref := stx }
  match stx with
  | `(cnlModelState|
      Actual world $name:ident
        $assignments:cnlGroundAssignment*
      End world) =>
      parseAssignments name.getId .actualWorld assignments
  | `(cnlModelState|
      Possible world $name:ident
        $assignments:cnlGroundAssignment*
      End world) =>
      parseAssignments name.getId .possibleWorld assignments
  | `(cnlModelState|
      Actual situation $name:ident
        $assignments:cnlGroundAssignment*
      End situation) =>
      parseAssignments name.getId .actualSituation assignments
  | `(cnlModelState|
      Counterfactual situation $name:ident
        $assignments:cnlGroundAssignment*
      End situation) =>
      parseAssignments name.getId .counterfactualSituation assignments
  | _ => throwParseErrorAt stx "malformed Model state"

private def parseModelDescription
    (stx : Syntax) : CommandElabM ModelDescription := do
  match stx with
  | `(cnlModelDescription|
      Model $name:ident
        $states:cnlModelState*
        $[$accessibilityBlock:cnlAccessibilityBlock]?
        $[$selectionBlock:cnlSelectionBlock]?
      End model) =>
      let parsedStates ← states.mapM parseModelState
      let parsedAccessibility ←
        match accessibilityBlock with
        | Option.none => pure #[]
        | Option.some block =>
            match block with
            | `(cnlAccessibilityBlock|
                Accessibility
                  $edges:cnlModelEdge*
                End accessibility) =>
                edges.mapM parseReachabilityEdge
            | _ => throwParseErrorAt block "malformed Accessibility section"
      let parsedSelection ←
        match selectionBlock with
        | Option.none => pure #[]
        | Option.some block =>
            match block with
            | `(cnlSelectionBlock|
                Closest situations
                  $edges:cnlModelEdge*
                End closest situations) =>
                edges.mapM parseSelectionEdge
            | _ => throwParseErrorAt block "malformed Closest situations section"
      pure {
        name := name.getId
        states := parsedStates
        «accessibility» := parsedAccessibility
        «selection» := parsedSelection
        ref := stx
      }
  | _ => throwParseErrorAt stx "malformed Model section"

private def parseModelAnalysis
    (stx : Syntax) : CommandElabM ModelAnalysis :=
  match stx with
  | `(cnlModelAnalysis| Analyze model $modelId:ident for $target:ident) =>
      pure {
        «model» := modelId.getId
        target := target.getId
        ref := stx
        modelRef := modelId
        targetRef := target
      }
  | _ => throwParseErrorAt stx "malformed Model analysis request"

private def parseModalCountermodel
    (stx : Syntax) : CommandElabM ModalCountermodelCertificate :=
  match stx with
  | `(cnlModalCountermodel|
      Modal countermodel $name:ident for $target:ident
        Designated world $designated:ident
        $worlds:cnlModelWorld*
        Accessibility
          $edges:cnlModelEdge*
        End accessibility
      End modal countermodel) => do
      let parsedWorlds ← worlds.mapM parseModelWorld
      let parsedEdges ← edges.mapM parseReachabilityEdge
      pure {
        name := name.getId
        target := target.getId
        designatedWorld := designated.getId
        worlds := parsedWorlds
        «accessibility» := parsedEdges
        ref := stx
        targetRef := target
        designatedRef := designated
      }
  | _ => throwParseErrorAt stx "malformed Modal countermodel"

private def parseCounterfactualCountermodel
    (stx : Syntax) : CommandElabM CounterfactualCountermodelCertificate :=
  match stx with
  | `(cnlCounterfactualCountermodel|
      Counterfactual countermodel $name:ident for $target:ident
        Actual world $actual:ident
        $worlds:cnlModelWorld*
        Closest selection
          $edges:cnlModelEdge*
        End selection
      End counterfactual countermodel) => do
      let parsedWorlds ← worlds.mapM parseModelWorld
      let parsedEdges ← edges.mapM parseSelectionEdge
      pure {
        name := name.getId
        target := target.getId
        actualWorld := actual.getId
        worlds := parsedWorlds
        «selection» := parsedEdges
        ref := stx
        targetRef := target
        actualRef := actual
      }
  | _ => throwParseErrorAt stx "malformed Counterfactual countermodel"

private def parseAlternative (stx : Syntax) :
    CommandElabM Dialectic.Alternative := do
  match stx with
  | `(cnlAlternative|
      Alternative $name:ident based on $base:cnlName
        $changes:cnlChange*
        Recheck the same deduction $deductionId:ident
        $[$countermodel?]?
        $[$modalCountermodel?]?
        $[$counterfactualCountermodel?]?
        $[$modelAnalysis?]?
        $objections:cnlObjection*
      End alternative) =>
      let parsedChanges ← changes.mapM parseChange
      let parsedObjections ← objections.mapM parseObjection
      if parsedChanges.isEmpty then
        throwParseErrorAt stx "Alternative must contain at least one explicit Change"
      pure {
        name := name.getId
        base := ← parseName base
        changes := parsedChanges
        recheck := deductionId.getId
        countermodel? := ← countermodel?.mapM parseCountermodel
        modalCountermodel? := ← modalCountermodel?.mapM parseModalCountermodel
        counterfactualCountermodel? :=
          ← counterfactualCountermodel?.mapM parseCounterfactualCountermodel
        modelAnalysis? := ← modelAnalysis?.mapM parseModelAnalysis
        objections := parsedObjections
        ref := stx
        recheckRef := deductionId
      }
  | _ => throwParseErrorAt stx "malformed Alternative section"

def parseNotebook (stx : Syntax) : CommandElabM Dialectic.Notebook :=
  match stx with
  | `(
      Argument $name:ident
      Logic profile $profileId:cnlName
        Description $description:str
      End logic
      $vocabularyStx:cnlVocabulary
      $[$modelStx:cnlModelDescription]?
      $sourceStx:cnlSource
      $originalStx:cnlReconstruction
      $alternativeStx:cnlAlternative
      End argument) => do
      pure {
        name := name.getId
        «profile» := ← parseName profileId
        profileDescription := description.getString
        profileRef := profileId
        «vocabulary» := ← parseVocabulary vocabularyStx
        model? := ← modelStx.mapM parseModelDescription
        «source» := ← parseSource sourceStx
        «original» := ← parseReconstruction originalStx
        «alternative» := ← parseAlternative alternativeStx
        ref := stx
      }
  | _ => throwParseErrorAt stx "malformed Argument notebook"

end Dialectic
