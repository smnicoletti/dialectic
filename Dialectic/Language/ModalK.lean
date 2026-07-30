import Dialectic.Language.Ast

/-!
Executable relational modal-K profile. A modal proposition varies by world;
`box` and `diamond` are interpreted using one explicitly declared accessibility
relation. No frame condition and no classical axiom are added.
-/

namespace Dialectic.ModalK

open Lean Meta Elab Term
open Dialectic

universe u

abbrev Proposition (World : Type u) := World → Prop

def box
    {World : Type u}
    (accessible : World → World → Prop)
    (p : Proposition World)
    (w : World) : Prop :=
  ∀ v, accessible w v → p v

def diamond
    {World : Type u}
    (accessible : World → World → Prop)
    (p : Proposition World)
    (w : World) : Prop :=
  ∃ v, accessible w v ∧ p v

theorem boxModusPonens
    {World : Type u}
    (accessible : World → World → Prop)
    (p q : Proposition World)
    (hImp : ∀ w, box accessible (fun v => p v → q v) w)
    (hP : ∀ w, box accessible p w) :
    ∀ w, box accessible q w := by
  intro w v hAccessible
  exact hImp w v hAccessible (hP w v hAccessible)

theorem boxModusPonensAt
    {World : Type u}
    (accessible : World → World → Prop)
    (p q : Proposition World)
    (w : World)
    (hImp : box accessible (fun v => p v → q v) w)
    (hP : box accessible p w) :
    box accessible q w := by
  intro v hAccessible
  exact hImp v hAccessible (hP v hAccessible)

private abbrev NamedExprs := Array (Name × Expr)

private def lookupExpr (entries : NamedExprs) (name : Name) : MetaM Expr :=
  match entries.find? (fun entry => entry.1 == name) with
  | some entry => pure entry.2
  | none => throwError "internal ModalK name-resolution failure for '{name}'"

private def meaningType
    (domain relation : Expr)
    (predicates : NamedExprs)
    (semanticForm : Meaning) : MetaM Expr := do
  let mkBoxBody (w v : Expr) (body : Expr) : MetaM Expr := do
    let accessible := mkApp2 relation w v
    mkArrow accessible body
  match semanticForm with
  | .modalEvery _individual predicateName =>
      let predicate ← lookupExpr predicates predicateName
      withLocalDeclD `w domain fun w =>
        withLocalDeclD `v domain fun v => do
          let body ← mkBoxBody w v (mkApp predicate v)
          mkForallFVars #[w, v] body
  | .modalEveryImp _individual antecedentName consequentName =>
      let antecedent ← lookupExpr predicates antecedentName
      let consequent ← lookupExpr predicates consequentName
      withLocalDeclD `w domain fun w =>
        withLocalDeclD `v domain fun v => do
          let implication ← mkArrow (mkApp antecedent v) (mkApp consequent v)
          let body ← mkBoxBody w v implication
          mkForallFVars #[w, v] body
  | .modalSome _individual predicateName =>
      let predicate ← lookupExpr predicates predicateName
      withLocalDeclD `w domain fun w =>
        withLocalDeclD `v domain fun v => do
          let accessible := mkApp2 relation w v
          let witnessBody := mkApp2 (mkConst ``And) accessible (mkApp predicate v)
          let witnessPredicate ← mkLambdaFVars #[v] witnessBody
          let existsExpr := mkApp2
            (mkConst ``Exists [Level.succ Level.zero])
            domain
            witnessPredicate
          mkForallFVars #[w] existsExpr
  | .counterfactual .. | .counterfactualNot .. =>
      throwError "internal ModalK checker received a Counterfactual meaning"
  | _ =>
      throwError "internal ModalK checker received a non-modal meaning"

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
    (k : Expr → Expr → NamedExprs → TermElabM α) : TermElabM α := do
  withLocalDeclD `World (mkSort (.succ .zero)) fun domain =>
    withPredicates domain vocabulary.predicates.toList #[] fun predicates => do
      let relationTarget ← mkArrow domain (mkSort .zero)
      let relationType ← mkArrow domain relationTarget
      withLocalDeclD `accessible relationType fun relation =>
        k domain relation predicates

private partial def withPremises
    (domain relation : Expr)
    (predicates : NamedExprs)
    (remaining : List (Name × Meaning))
    (k : TermElabM α) : TermElabM α :=
  match remaining with
  | [] => k
  | (name, semanticForm) :: tail => do
      let type ← meaningType domain relation predicates semanticForm
      withLocalDeclD name type fun _ =>
        withPremises domain relation predicates tail k

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

private def meaningLeanSource (semanticForm : Meaning) : String :=
  let typeName : Name := `World
  let relationName : Name := `accessible
  let type := typeName.toString
  match semanticForm with
  | .modalEvery _individual predicate =>
      s!"forall w : {type}, forall v : {type}, {relationName} w v -> {predicate} v"
  | .modalSome _individual predicate =>
      s!"forall w : {type}, exists v : {type}, And ({relationName} w v) ({predicate} v)"
  | .modalEveryImp _individual antecedent consequent =>
      s!"forall w : {type}, forall v : {type}, {relationName} w v -> ({antecedent} v -> {consequent} v)"
  | .counterfactual .. | .counterfactualNot .. =>
      "False"
  | _ => "False"

private def deductionLeanSource
    (_vocabulary : Vocabulary)
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange) : Except String String := do
  let mut result := "by\n"
  for step in deduction.steps do
    let claimData ← match lookupClaim reconstruction step.conclusion with
      | some found => pure found
      | none => throw s!"unknown conclusion claim '{step.conclusion}'"
    result := result ++
      s!"  have {step.conclusion} : " ++
      meaningLeanSource (meaningWithChanges claimData changes) ++
      " := by\n" ++
      "    intro w v hAccessible\n" ++
      s!"    exact {step.left} w v hAccessible ({step.right} w v hAccessible)\n"
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
        throwError "internal ModalK term-generation failure: {message}"
  let result ← commitIfNoErrors? do
    let term ← withoutErrToSorry <|
      elabTermEnsuringType termStx (some expectedType)
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
  let premiseMeanings := premiseClaims reconstruction deduction changes
  let source ←
    match deductionLeanSource vocabulary reconstruction deduction changes with
    | .ok generated => pure generated
    | .error message => throwErrorAt deduction.ref message
  withVocabulary vocabulary fun domain relation predicates =>
    withPremises domain relation predicates premiseMeanings.toList do
      let expected ← meaningType domain relation predicates targetMeaning
      runElaboration s!"<{deduction.name}-ModalK-deduction>" source expected

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

private def predicateModelSource
    (certificate : ModalCountermodelCertificate)
    (predicate : Name) : Except String String := do
  let mut holding : Array String := #[]
  let mut index := 0
  for world in certificate.worlds do
    match assignmentValue? world predicate with
    | some .holds => holding := holding.push s!"x.val = {index}"
    | some .doesNotHold => pure ()
    | none =>
        throw s!"World '{world.name}' does not assign Predicate '{predicate}'"
    index := index + 1
  if holding.isEmpty then
    pure s!"(fun _ : Fin {certificate.worlds.size} => False)"
  else if holding.size == certificate.worlds.size then
    pure s!"(fun _ : Fin {certificate.worlds.size} => True)"
  else
    pure s!"(fun x : Fin {certificate.worlds.size} => \
      {disjoinSources holding.toList})"

private def accessibilityModelSource
    (certificate : ModalCountermodelCertificate) : Except String String := do
  let mut edges : Array String := #[]
  for edge in certificate.accessibility do
    let source ← match worldIndex? certificate.worlds edge.source with
      | some index => pure index
      | none => throw s!"unknown accessibility source World '{edge.source}'"
    let target ← match worldIndex? certificate.worlds edge.target with
      | some index => pure index
      | none => throw s!"unknown accessibility target World '{edge.target}'"
    edges := edges.push s!"And (w.val = {source}) (v.val = {target})"
  pure s!"(fun w v : Fin {certificate.worlds.size} => \
    {disjoinSources edges.toList})"

private def meaningModelSource
    (certificate : ModalCountermodelCertificate)
    (meaning : Meaning)
    (atWorld? : Option Nat := none) : Except String String := do
  let relation ← accessibilityModelSource certificate
  let domain := s!"Fin {certificate.worlds.size}"
  let atBox (world : String) (body : String) :=
    s!"(forall v : {domain}, ({relation}) ({world}) v -> {body})"
  match meaning with
  | .modalEvery _individual predicate =>
      let p ← predicateModelSource certificate predicate
      match atWorld? with
      | some index => pure <| atBox s!"(⟨{index}, by decide⟩ : {domain})" s!"({p}) v"
      | none =>
          pure s!"(forall w : {domain}, {atBox "w" s!"({p}) v"})"
  | .modalEveryImp _individual antecedent consequent =>
      let p ← predicateModelSource certificate antecedent
      let q ← predicateModelSource certificate consequent
      let body := s!"(({p}) v -> ({q}) v)"
      match atWorld? with
      | some index => pure <| atBox s!"(⟨{index}, by decide⟩ : {domain})" body
      | none => pure s!"(forall w : {domain}, {atBox "w" body})"
  | .modalSome _individual predicate =>
      let p ← predicateModelSource certificate predicate
      let atDiamond (world : String) :=
        s!"(exists v : {domain}, And (({relation}) ({world}) v) (({p}) v))"
      match atWorld? with
      | some index => pure <| atDiamond s!"(⟨{index}, by decide⟩ : {domain})"
      | none => pure s!"(forall w : {domain}, {atDiamond "w"})"
  | _ => throw "ModalK finite models interpret only ModalK meanings"

private def elaboratePropositionSource
    (sourceName source : String) : TermElabM Expr := do
  let termStx ←
    match Parser.runParserCategory (← getEnv) `term source sourceName with
    | .ok parsed => pure parsed
    | .error message =>
        throwError "internal ModalK countermodel-generation failure: {message}"
  let proposition ← withoutErrToSorry <|
    elabTermEnsuringType termStx (some (mkSort .zero))
  synthesizeSyntheticMVarsNoPostponing
  pure <| ← instantiateMVars proposition

private def targetFailureExplanation
    (certificate : ModalCountermodelCertificate)
    (target : Meaning) : String :=
  let successors := certificate.accessibility.filter fun edge =>
    edge.source == certificate.designatedWorld
  match target with
  | .modalEvery individual predicate =>
      match successors.find? fun edge =>
          (certificate.worlds.find? fun world => world.name == edge.target).any
            fun world => assignmentValue? world predicate == some .doesNotHold with
      | some edge =>
          s!"From actual world {certificate.designatedWorld}, world {edge.target} \
             is accessible and {individual} is not {predicate} there."
      | none =>
          s!"The necessary claim fails at {certificate.designatedWorld}."
  | .modalEveryImp individual antecedent consequent =>
      match successors.find? fun edge =>
          (certificate.worlds.find? fun world => world.name == edge.target).any
            fun world =>
              assignmentValue? world antecedent == some .holds &&
              assignmentValue? world consequent == some .doesNotHold with
      | some edge =>
          s!"At accessible world {edge.target}, {individual} is {antecedent} but \
             is not {consequent}."
      | none => "The necessary implication fails at the actual world."
  | .modalSome individual predicate =>
      s!"No world accessible from {certificate.designatedWorld} makes \
         {individual} {predicate}."
  | _ => "The target fails in the analyzed model."

def checkCountermodel
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange)
    (certificate : ModalCountermodelCertificate) :
    TermElabM (Option CountermodelEvidence) := do
  let targetClaim ← (lookupClaim reconstruction certificate.target).getDM <|
    throwErrorAt certificate.targetRef
      "unknown modal countermodel target Claim '{certificate.target}'"
  let designated ← (worldIndex? certificate.worlds certificate.designatedWorld).getDM <|
    throwErrorAt certificate.designatedRef
      "unknown designated World '{certificate.designatedWorld}'"
  let premises := premiseClaims reconstruction deduction changes
  let targetMeaning := meaningWithChanges targetClaim changes
  let premiseSources ← premises.mapM fun (_, meaning) =>
    match meaningModelSource certificate meaning with
    | .ok source => pure source
    | .error message => throwErrorAt certificate.ref message
  let targetSource ←
    match meaningModelSource certificate targetMeaning
        (some designated) with
    | .ok source => pure source
    | .error message => throwErrorAt certificate.targetRef message
  let propositionSource :=
    conjoinSources <| (premiseSources.push s!"Not ({targetSource})").toList
  let expected ← elaboratePropositionSource
    s!"<{certificate.name}-modal-countermodel-proposition>" propositionSource
  let status ← runElaboration
    s!"<{certificate.name}-modal-countermodel-certificate>" "by decide" expected
  if status == .accepted then
    let worldNames := certificate.worlds.map (·.name)
    let edgeSummary := String.intercalate ", " <|
      certificate.accessibility.toList.map fun edge =>
        s!"{edge.source} reaches {edge.target}"
    pure <| some {
      certificate := certificate.name
      deduction := deduction.name
      target := certificate.target
      individuals := worldNames
      premiseClaims := premises.map (·.1)
      modelSummary :=
        s!"{targetFailureExplanation certificate targetMeaning} Frame edges: \
          {if edgeSummary.isEmpty then "none" else edgeSummary}."
      proofMethod :=
        "Dialectic analyzed the declared finite Kripke model, generated a \
         proposition stating that every alternative premise holds while the \
         target fails, and asked Lean to check it."
    }
  else
    pure none

end Dialectic.ModalK
