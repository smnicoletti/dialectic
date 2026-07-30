import Dialectic.Language.Ast

/-!
A deliberately bounded counterfactual profile.

One declared relation records the worlds selected by the author as closest and
antecedent-relevant. At an evaluation world `w`,

`If it were P, then Q` means `∀ v, selected w v → P v → Q v`.

The profile does not search for closest worlds, impose a ranking, or identify
this connective with material implication.
-/

namespace Dialectic.Counterfactual

open Lean Meta Elab Term
open Dialectic

universe u

def conditional
    {World : Type u}
    (selected : World → World → Prop)
    (antecedent consequent : World → Prop)
    (w : World) : Prop :=
  ∀ v, selected w v → antecedent v → consequent v

theorem consequence
    {World : Type u}
    (selected : World → World → Prop)
    (p q r : World → Prop)
    (w : World)
    (hpq : conditional selected p q w)
    (hqr : conditional selected q r w) :
    conditional selected p r w := by
  intro v hSelected hp
  exact hqr v hSelected (hpq v hSelected hp)

private abbrev NamedExprs := Array (Name × Expr)

private def lookupExpr (entries : NamedExprs) (name : Name) : MetaM Expr :=
  match entries.find? (fun entry => entry.1 == name) with
  | some entry => pure entry.2
  | none => throwError "internal Counterfactual name-resolution failure for '{name}'"

private def meaningType
    (domain relation actual : Expr)
    (predicates : NamedExprs)
    (meaning : Meaning) : MetaM Expr := do
  let conditionalType (antecedent consequent : Name) (negated : Bool) := do
    let p ← lookupExpr predicates antecedent
    let q ← lookupExpr predicates consequent
    withLocalDeclD `v domain fun v => do
      let selected := mkApp2 relation actual v
      let consequentType :=
        if negated then mkApp (mkConst ``Not) (mkApp q v) else mkApp q v
      let body ← mkArrow (mkApp p v) consequentType
      let body ← mkArrow selected body
      mkForallFVars #[v] body
  match meaning with
  | .counterfactual _individual antecedent consequent =>
      conditionalType antecedent consequent false
  | .counterfactualNot _individual antecedent consequent =>
      conditionalType antecedent consequent true
  | _ => throwError "internal Counterfactual checker received another profile's meaning"

private partial def withPredicates
    (domain : Expr)
    (remaining : List PredicateWord)
    (acc : NamedExprs)
    (k : NamedExprs → TermElabM α) : TermElabM α :=
  match remaining with
  | [] => k acc
  | predicate :: tail => do
      let predicateType ← mkArrow domain (mkSort .zero)
      withLocalDeclD predicate.name predicateType fun fvar =>
        withPredicates domain tail (acc.push (predicate.name, fvar)) k

private def withVocabulary
    (vocabulary : Vocabulary)
    (k : Expr → Expr → Expr → NamedExprs → TermElabM α) : TermElabM α := do
  withLocalDeclD `World (mkSort (.succ .zero)) fun domain =>
    withPredicates domain vocabulary.predicates.toList #[] fun predicates => do
      let relationTarget ← mkArrow domain (mkSort .zero)
      let relationType ← mkArrow domain relationTarget
      withLocalDeclD `selectedClosest relationType fun relation =>
        withLocalDeclD `actual domain fun actual =>
          k domain relation actual predicates

private partial def withPremises
    (domain relation actual : Expr)
    (predicates : NamedExprs)
    (remaining : List (Name × Meaning))
    (k : TermElabM α) : TermElabM α :=
  match remaining with
  | [] => k
  | (name, meaning) :: tail => do
      let type ← meaningType domain relation actual predicates meaning
      withLocalDeclD name type fun _ =>
        withPremises domain relation actual predicates tail k

private def lookupClaim
    (reconstruction : Reconstruction)
    (name : Name) : Option Claim :=
  reconstruction.claims.find? (fun claimData => claimData.name == name)

private def meaningWithChanges
    (claimData : Claim)
    (changes : Array MeaningChange) : Meaning :=
  match changes.find? (fun revision => revision.claim == claimData.name) with
  | some revision => revision.alternative
  | none => claimData.meaning

private def premiseClaims
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange) : Array (Name × Meaning) :=
  let derived := deduction.steps.map (·.conclusion)
  reconstruction.claims.foldl (init := #[]) fun acc claimData =>
    if derived.contains claimData.name then acc
    else acc.push (claimData.name, meaningWithChanges claimData changes)

private def meaningLeanSource (meaning : Meaning) : String :=
  let typeName : Name := `World
  let relationName : Name := `selectedClosest
  let type := typeName.toString
  match meaning with
  | .counterfactual _individual antecedent consequent =>
      s!"forall v : {type}, {relationName} actual v -> {antecedent} v -> {consequent} v"
  | .counterfactualNot _individual antecedent consequent =>
      s!"forall v : {type}, {relationName} actual v -> {antecedent} v -> Not ({consequent} v)"
  | _ => "False"

private def deductionLeanSource
    (_vocabulary : Vocabulary)
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange) : Except String String := do
  let mut result := "by\n"
  for step in deduction.steps do
    let conclusion ← match lookupClaim reconstruction step.conclusion with
      | some conclusion => pure conclusion
      | none => throw s!"unknown conclusion Claim '{step.conclusion}'"
    result := result ++
      s!"  have {step.conclusion} : " ++
      meaningLeanSource (meaningWithChanges conclusion changes) ++
      " := by\n" ++
      "    intro v hSelected hAntecedent\n" ++
      s!"    exact {step.right} v hSelected \
        ({step.left} v hSelected hAntecedent)\n"
  let finalStep ← match deduction.steps.back? with
    | some step => pure step
    | none => throw "deduction has no steps"
  pure <| result ++ s!"  exact {finalStep.conclusion}\n"

private def runElaboration
    (sourceName source : String)
    (expectedType : Expr) : TermElabM DeductionStatus := do
  let termStx ←
    match Parser.runParserCategory (← getEnv) `term source sourceName with
    | .ok parsed => pure parsed
    | .error message =>
        throwError "internal Counterfactual term-generation failure: {message}"
  let result ← commitIfNoErrors? do
    let term ← withoutErrToSorry <| elabTermEnsuringType termStx (some expectedType)
    synthesizeSyntheticMVarsNoPostponing
    let term ← instantiateMVars term
    Meta.check term
    Meta.checkWithKernel term
    pure term
  pure <| if result.isSome then .accepted else .rejected

def checkDeduction
    (vocabulary : Vocabulary)
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange := #[]) : TermElabM DeductionStatus := do
  let finalStep ← deduction.steps.back?.getDM <|
    throwErrorAt deduction.ref "Deduction must contain at least one Step"
  let targetClaim ← (lookupClaim reconstruction finalStep.conclusion).getDM <|
    throwErrorAt finalStep.ref "unknown conclusion Claim '{finalStep.conclusion}'"
  let targetMeaning := meaningWithChanges targetClaim changes
  let premises := premiseClaims reconstruction deduction changes
  let source ←
    match deductionLeanSource vocabulary reconstruction deduction changes with
    | .ok generated => pure generated
    | .error message => throwErrorAt deduction.ref message
  withVocabulary vocabulary fun domain relation actual predicates =>
    withPremises domain relation actual predicates premises.toList do
      let expected ← meaningType domain relation actual predicates targetMeaning
      runElaboration s!"<{deduction.name}-Counterfactual-deduction>" source expected

private def assignmentValue?
    (world : ModelWorld)
    (predicate : Name) : Option PredicateValue :=
  (world.assignments.find? fun assignment =>
    assignment.predicate == predicate).map (·.value)

private def worldIndex?
    (worlds : Array ModelWorld)
    (name : Name) : Option Nat := Id.run do
  let mut index := 0
  for world in worlds do
    if world.name == name then return some index
    index := index + 1
  return none

private def disjoinSources : List String → String
  | [] => "False"
  | proposition :: tail => s!"Or ({proposition}) ({disjoinSources tail})"

private def conjoinSources : List String → String
  | [] => "True"
  | proposition :: tail => s!"And ({proposition}) ({conjoinSources tail})"

private def predicateSource
    (certificate : CounterfactualCountermodelCertificate)
    (predicate : Name) : Except String String := do
  let mut holding : Array String := #[]
  let mut index := 0
  for world in certificate.worlds do
    match assignmentValue? world predicate with
    | some .holds => holding := holding.push s!"x.val = {index}"
    | some .doesNotHold => pure ()
    | none => throw s!"World '{world.name}' does not assign Predicate '{predicate}'"
    index := index + 1
  if holding.isEmpty then
    pure s!"(fun _ : Fin {certificate.worlds.size} => False)"
  else if holding.size == certificate.worlds.size then
    pure s!"(fun _ : Fin {certificate.worlds.size} => True)"
  else
    pure s!"(fun x : Fin {certificate.worlds.size} => {disjoinSources holding.toList})"

private def selectionSource
    (certificate : CounterfactualCountermodelCertificate) : Except String String := do
  let mut edges : Array String := #[]
  for edge in certificate.selection do
    let source ← match worldIndex? certificate.worlds edge.source with
      | some index => pure index
      | none => throw s!"unknown selection source World '{edge.source}'"
    let target ← match worldIndex? certificate.worlds edge.target with
      | some index => pure index
      | none => throw s!"unknown selected World '{edge.target}'"
    edges := edges.push s!"And (w.val = {source}) (v.val = {target})"
  pure s!"(fun w v : Fin {certificate.worlds.size} => \
    {disjoinSources edges.toList})"

private def meaningModelSource
    (certificate : CounterfactualCountermodelCertificate)
    (meaning : Meaning)
    (actual : Nat) : Except String String := do
  let relation ← selectionSource certificate
  let domain := s!"Fin {certificate.worlds.size}"
  let pWorld := s!"(⟨{actual}, by decide⟩ : {domain})"
  match meaning with
  | .counterfactual _individual antecedent consequent =>
      let p ← predicateSource certificate antecedent
      let q ← predicateSource certificate consequent
      pure s!"(forall v : {domain}, ({relation}) {pWorld} v -> \
        ({p}) v -> ({q}) v)"
  | .counterfactualNot _individual antecedent consequent =>
      let p ← predicateSource certificate antecedent
      let q ← predicateSource certificate consequent
      pure s!"(forall v : {domain}, ({relation}) {pWorld} v -> \
        ({p}) v -> Not (({q}) v))"
  | _ => throw "Counterfactual finite models interpret only Counterfactual meanings"

private def elaboratePropositionSource
    (sourceName source : String) : TermElabM Expr := do
  let termStx ←
    match Parser.runParserCategory (← getEnv) `term source sourceName with
    | .ok parsed => pure parsed
    | .error message =>
        throwError "internal Counterfactual countermodel-generation failure: {message}"
  let proposition ← withoutErrToSorry <|
    elabTermEnsuringType termStx (some (mkSort .zero))
  synthesizeSyntheticMVarsNoPostponing
  pure <| ← instantiateMVars proposition

private def targetFailureExplanation
    (certificate : CounterfactualCountermodelCertificate)
    (target : Meaning) : String :=
  let selectedStates := certificate.selection.filter fun edge =>
    edge.source == certificate.actualWorld
  match target with
  | .counterfactual individual antecedent consequent =>
      match selectedStates.find? fun edge =>
          (certificate.worlds.find? fun world => world.name == edge.target).any
            fun world =>
              assignmentValue? world antecedent == some .holds &&
              assignmentValue? world consequent == some .doesNotHold with
      | some edge =>
          s!"In selected counterfactual situation {edge.target}, {individual} is \
             {antecedent} but is not {consequent}."
      | none => "The counterfactual target fails at the actual situation."
  | .counterfactualNot individual antecedent consequent =>
      match selectedStates.find? fun edge =>
          (certificate.worlds.find? fun world => world.name == edge.target).any
            fun world =>
              assignmentValue? world antecedent == some .holds &&
              assignmentValue? world consequent == some .holds with
      | some edge =>
          s!"In selected counterfactual situation {edge.target}, {individual} is \
             both {antecedent} and {consequent}."
      | none => "The negative counterfactual target fails at the actual situation."
  | _ => "The target fails in the analyzed model."

def checkCountermodel
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange)
    (certificate : CounterfactualCountermodelCertificate) :
    TermElabM (Option CountermodelEvidence) := do
  let targetClaim ← (lookupClaim reconstruction certificate.target).getDM <|
    throwErrorAt certificate.targetRef
      "unknown counterfactual countermodel target Claim '{certificate.target}'"
  let actual ← (worldIndex? certificate.worlds certificate.actualWorld).getDM <|
    throwErrorAt certificate.actualRef "unknown actual World '{certificate.actualWorld}'"
  let premises := premiseClaims reconstruction deduction changes
  let targetMeaning := meaningWithChanges targetClaim changes
  let premiseSources ← premises.mapM fun (_, meaning) =>
    match meaningModelSource certificate meaning actual with
    | .ok source => pure source
    | .error message => throwErrorAt certificate.ref message
  let targetSource ←
    match meaningModelSource certificate targetMeaning actual with
    | .ok source => pure source
    | .error message => throwErrorAt certificate.targetRef message
  let expected ← elaboratePropositionSource
    s!"<{certificate.name}-counterfactual-countermodel-proposition>"
    (conjoinSources <| (premiseSources.push s!"Not ({targetSource})").toList)
  let status ← runElaboration
    s!"<{certificate.name}-counterfactual-countermodel-certificate>"
    "by decide" expected
  if status == .accepted then
    let worlds := certificate.worlds.map (·.name)
    let selected := String.intercalate ", " <|
      certificate.selection.toList.map fun edge =>
        s!"{edge.source} selects {edge.target}"
    pure <| some {
      certificate := certificate.name
      deduction := deduction.name
      target := certificate.target
      individuals := worlds
      premiseClaims := premises.map (·.1)
      modelSummary :=
        s!"{targetFailureExplanation certificate targetMeaning} \
           Selected situations: {selected}."
      proofMethod :=
        "Dialectic analyzed the declared finite counterfactual model, generated \
         a proposition stating that every alternative premise holds while the \
         target fails, and asked Lean to check it."
    }
  else
    pure none

end Dialectic.Counterfactual
