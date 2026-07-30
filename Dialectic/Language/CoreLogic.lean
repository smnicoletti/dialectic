import Dialectic.Language.Ast

/-!
CoreLogic gives the executable fragment its constructive Lean semantics. The
controlled deduction AST is rendered to ordinary Lean term syntax and
re-elaborated under each reconstruction's local declarations. Lean's term
elaborator and kernel, rather than a custom type checker, decide acceptance.
-/

namespace Dialectic.CoreLogic

open Lean Meta Elab Term
open Dialectic

private abbrev NamedExprs := Array (Name × Expr)

private def lookupExpr (entries : NamedExprs) (name : Name) : MetaM Expr :=
  match entries.find? (fun entry => entry.1 == name) with
  | some entry => pure entry.2
  | none => throwError "internal CoreLogic name-resolution failure for '{name}'"

private def meaningType
    (domain : Expr)
    (predicates : NamedExprs)
    (meaning : Meaning) : MetaM Expr := do
  let (subjectName, predicateName) ←
    match meaning with
    | .everyIs subject _ predicate | .everyIsNot subject _ predicate
    | .someIs subject _ predicate | .someIsNot subject _ predicate =>
        pure (subject, predicate)
    | .modalEvery .. | .modalSome .. | .modalEveryImp ..
    | .counterfactual .. | .counterfactualNot .. =>
        throwError "internal CoreLogic checker received a profile-specific meaning"
  let subject ← lookupExpr predicates subjectName
  let predicate ← lookupExpr predicates predicateName
  withLocalDeclD `x domain fun x => do
    let antecedent := mkApp subject x
    let consequent := mkApp predicate x
    match meaning with
    | .everyIs .. =>
        let body ← mkArrow antecedent consequent
        mkForallFVars #[x] body
    | .everyIsNot .. =>
        let body ← mkArrow antecedent (mkApp (mkConst ``Not) consequent)
        mkForallFVars #[x] body
    | .someIs .. =>
        let body := mkApp2 (mkConst ``And) antecedent consequent
        let predicate ← mkLambdaFVars #[x] body
        pure <| mkApp2 (mkConst ``Exists [Level.succ Level.zero]) domain predicate
    | .someIsNot .. =>
        let negative := mkApp (mkConst ``Not) consequent
        let body := mkApp2 (mkConst ``And) antecedent negative
        let predicate ← mkLambdaFVars #[x] body
        pure <| mkApp2 (mkConst ``Exists [Level.succ Level.zero]) domain predicate
    | .modalEvery .. | .modalSome .. | .modalEveryImp ..
    | .counterfactual .. | .counterfactualNot .. =>
        throwError "internal CoreLogic checker received a profile-specific meaning"

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
    (k : Expr → NamedExprs → TermElabM α) : TermElabM α := do
  withLocalDeclD vocabulary.typeWord.leanName (mkSort (.succ .zero)) fun domain =>
    withPredicates domain vocabulary.predicates.toList #[] (k domain)

private partial def withPremises
    (domain : Expr)
    (predicates : NamedExprs)
    (remaining : List (Name × Meaning))
    (k : TermElabM α) : TermElabM α :=
  match remaining with
  | [] => k
  | (name, meaning) :: tail => do
      let type ← meaningType domain predicates meaning
      withLocalDeclD name type fun _ =>
        withPremises domain predicates tail k

private def lookupClaim
    (reconstruction : Reconstruction)
    (name : Name) : Option Claim :=
  reconstruction.claims.find? (fun claim => claim.name == name)

private def meaningWithChanges
    (claim : Claim)
    (changes : Array MeaningChange) : Meaning :=
  match changes.find? (fun change => change.claim == claim.name) with
  | some change => change.alternative
  | none => claim.meaning

private def derivedNames (deduction : Deduction) : Array Name :=
  deduction.steps.map (·.conclusion)

private def premiseClaims
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange) : Array (Name × Meaning) :=
  let derived := derivedNames deduction
  reconstruction.claims.foldl (init := #[]) fun acc claim =>
    if derived.contains claim.name then acc
    else acc.push (claim.name, meaningWithChanges claim changes)

private def meaningLeanSource
    (typeName : Name)
    (meaning : Meaning) : String :=
  let type := typeName.toString
  match meaning with
  | .everyIs subject _ predicate =>
      s!"forall x : {type}, {subject} x -> {predicate} x"
  | .everyIsNot subject _ predicate =>
      s!"forall x : {type}, {subject} x -> Not ({predicate} x)"
  | .someIs subject _ predicate =>
      s!"exists x : {type}, And ({subject} x) ({predicate} x)"
  | .someIsNot subject _ predicate =>
      s!"exists x : {type}, And ({subject} x) (Not ({predicate} x))"
  | .modalEvery .. | .modalSome .. | .modalEveryImp ..
  | .counterfactual .. | .counterfactualNot .. => "False"

private def deductionLeanSource
    (typeName : Name)
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange) : Except String String := do
  let mut result := "by\n"
  for step in deduction.steps do
    let conclusion ← match lookupClaim reconstruction step.conclusion with
      | some claim => pure claim
      | none => throw s!"unknown conclusion claim '{step.conclusion}'"
    let conclusionMeaning := meaningWithChanges conclusion changes
    result := result ++
      s!"  have {step.conclusion} : " ++
      meaningLeanSource typeName conclusionMeaning ++
      " := by\n" ++
      "    intro x hx\n" ++
      s!"    exact {step.right} x ({step.left} x hx)\n"
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
        throwError "internal CoreLogic term-generation failure: {message}"
  let result ← commitIfNoErrors? do
    let term ← withoutErrToSorry <|
      elabTermEnsuringType termStx (Option.some expectedType)
    synthesizeSyntheticMVarsNoPostponing
    let term ← instantiateMVars term
    Meta.check term
    Meta.checkWithKernel term
    pure term
  pure <| if result.isSome then .accepted else .rejected

private def runElaborationStrict
    (sourceName source : String)
    (expectedType : Expr) : TermElabM Unit := do
  let termStx ←
    match Parser.runParserCategory (← getEnv) `term source sourceName with
    | .ok parsed => pure parsed
    | .error message => throwError "{message}"
  let term ← withoutErrToSorry <|
    elabTermEnsuringType termStx (Option.some expectedType)
  synthesizeSyntheticMVarsNoPostponing
  let term ← instantiateMVars term
  Meta.check term
  Meta.checkWithKernel term

def checkDeduction
    (vocabulary : Vocabulary)
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange := #[]) : TermElabM DeductionStatus := do
  let finalStep ← deduction.steps.back?.getDM <|
    throwErrorAt deduction.ref "Deduction must contain at least one Step"
  let targetClaim ← (lookupClaim reconstruction finalStep.conclusion).getDM <|
    throwErrorAt finalStep.ref
      "unknown conclusion Claim '{finalStep.conclusion}'"
  let targetMeaning := meaningWithChanges targetClaim changes
  let premiseMeanings := premiseClaims reconstruction deduction changes
  let source ←
    match deductionLeanSource vocabulary.typeWord.leanName reconstruction deduction changes with
    | .ok source => pure source
    | .error message => throwErrorAt deduction.ref message
  withVocabulary vocabulary fun domain predicates => do
    withPremises domain predicates premiseMeanings.toList do
      let expected ← meaningType domain predicates targetMeaning
      runElaboration s!"<{deduction.name}-controlled-deduction>" source expected

private structure UniversalRule where
  claim : Name
  source : Name
  target : Name
  negative : Bool

private structure DerivedLiteral where
  predicate : Name
  proofName : String
  claims : Array Name

private structure ContradictionWitness where
  universal : Name
  existential : Name
  participatingClaims : Array Name
  source : String

private def universalRules
    (premises : Array (Name × Meaning)) : Array UniversalRule :=
  premises.foldl (init := #[]) fun rules premise =>
    match premise with
    | (claim, .everyIs source _ target) =>
        rules.push { claim, source, target, negative := false }
    | (claim, .everyIsNot source _ target) =>
        rules.push { claim, source, target, negative := true }
    | _ => rules

private def pushUnique (names : Array Name) (name : Name) : Array Name :=
  if names.contains name then names else names.push name

private def contradictionWitness?
    (premises : Array (Name × Meaning)) : Option ContradictionWitness := Id.run do
  let rules := universalRules premises
  for (existentialName, existentialMeaning) in premises do
    let (subject, predicate, predicateNegative) ←
      match existentialMeaning with
      | .someIs subject _ predicate => pure (subject, predicate, false)
      | .someIsNot subject _ predicate => pure (subject, predicate, true)
      | _ => continue
    let mut positives : Array DerivedLiteral :=
      #[{ predicate := subject, proofName := "hSubject", claims := #[] }]
    let mut negatives : Array DerivedLiteral := #[]
    if predicateNegative then
      negatives := negatives.push {
        predicate
        proofName := "hPredicateNegative"
        claims := #[]
      }
    else if !positives.any (fun fact => fact.predicate == predicate) then
      positives := positives.push {
        predicate
        proofName := "hPredicate"
        claims := #[]
      }
    let destruct :=
      if predicateNegative then
        s!"  rcases {existentialName} with \
          ⟨x, hSubject, hPredicateNegative⟩\n"
      else
        s!"  rcases {existentialName} with ⟨x, hSubject, hPredicate⟩\n"
    let mut derivation := ""
    let mut nextProof := 0
    let mut changed := true
    while changed do
      changed := false
      for rule in rules do
        if let some sourceFact :=
            positives.find? (fun fact => fact.predicate == rule.source) then
          if rule.negative then
            unless negatives.any (fun fact => fact.predicate == rule.target) do
              let proofName := s!"_hNegative{nextProof}"
              nextProof := nextProof + 1
              derivation := derivation ++
                s!"  have {proofName} := {rule.claim} x \
                  {sourceFact.proofName}\n"
              negatives := negatives.push {
                predicate := rule.target
                proofName
                claims := sourceFact.claims.push rule.claim
              }
              changed := true
          else
            unless positives.any (fun fact => fact.predicate == rule.target) do
              let proofName := s!"_hPositive{nextProof}"
              nextProof := nextProof + 1
              derivation := derivation ++
                s!"  have {proofName} := {rule.claim} x \
                  {sourceFact.proofName}\n"
              positives := positives.push {
                predicate := rule.target
                proofName
                claims := sourceFact.claims.push rule.claim
              }
              changed := true
      for positive in positives do
        if let some negative :=
            negatives.find? (fun fact => fact.predicate == positive.predicate) then
          let supporting :=
            if negative.claims.isEmpty then positive.claims else negative.claims
          let universal := supporting.back?.getD existentialName
          let mut involved := #[existentialName]
          for claim in positive.claims do
            involved := pushUnique involved claim
          for claim in negative.claims do
            involved := pushUnique involved claim
          let participating := premises.foldl (init := #[]) fun names premise =>
            if involved.contains premise.1 then names.push premise.1 else names
          return some {
            universal
            existential := existentialName
            participatingClaims := participating
            source :=
              "by\n" ++ destruct ++ derivation ++
              s!"  exact {negative.proofName} {positive.proofName}\n"
          }
  return none

def hasChainedContradictionPattern
    (premises : Array (Name × Meaning)) : Bool :=
  (contradictionWitness? premises).isSome

def checkInconsistency
    (vocabulary : Vocabulary)
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange := #[]) :
    TermElabM InconsistencyResult := do
  let premiseMeanings := premiseClaims reconstruction deduction changes
  let some witness := contradictionWitness? premiseMeanings
    | pure { status := .notWitnessed, evidence? := none }
  withVocabulary vocabulary fun domain predicates => do
    withPremises domain predicates premiseMeanings.toList do
      runElaborationStrict
        "<CoreLogic-contradiction-witness>"
        witness.source
        (mkConst ``False)
      pure {
        status := .witnessed
        evidence? := some {
          universalClaim := witness.universal
          existentialClaim := witness.existential
          participatingClaims := witness.participatingClaims
          deduction := deduction.name
          target := (deduction.steps.back?.map (·.conclusion)).getD Name.anonymous
          proofMethod :=
            "Lean elaborated a contradiction term from an existential witness \
             and a zero-or-more-step chain of universal rules, then checked it \
             against False with the kernel."
        }
      }

private def assignmentValue?
    (individual : CountermodelIndividual)
    (predicate : Name) : Option PredicateValue :=
  (individual.assignments.find? fun assignment =>
    assignment.predicate == predicate).map (·.value)

private def disjoinSources : List String → String
  | [] => "False"
  | proposition :: tail =>
      s!"Or ({proposition}) ({disjoinSources tail})"

private def predicateModelSource
  (certificate : CountermodelCertificate)
    (predicate : Name) : Except String String := do
  let mut holdingIndices : Array String := #[]
  let mut index := 0
  for individual in certificate.individuals do
    match assignmentValue? individual predicate with
    | some .holds =>
        holdingIndices := holdingIndices.push s!"x.val = {index}"
    | some .doesNotHold => pure ()
    | none =>
        throw s!"Countermodel Individual '{individual.name}' does not assign \
          predicate '{predicate}'"
    index := index + 1
  if holdingIndices.isEmpty then
    pure s!"(fun _ : Fin {certificate.individuals.size} => False)"
  else if holdingIndices.size == certificate.individuals.size then
    pure s!"(fun _ : Fin {certificate.individuals.size} => True)"
  else
    pure s!"(fun x : Fin {certificate.individuals.size} => \
      {disjoinSources holdingIndices.toList})"

private def meaningModelSource
    (certificate : CountermodelCertificate)
    (meaning : Meaning) : Except String String := do
  let (subject, predicate) ←
    match meaning with
    | .everyIs subject _ predicate | .everyIsNot subject _ predicate
    | .someIs subject _ predicate | .someIsNot subject _ predicate =>
        pure (subject, predicate)
    | .modalEvery .. | .modalSome .. | .modalEveryImp ..
    | .counterfactual .. | .counterfactualNot .. =>
        throw "CoreLogic countermodels cannot interpret profile-specific meanings"
  let subjectSource ← predicateModelSource certificate subject
  let predicateSource ← predicateModelSource certificate predicate
  let domainSource := s!"Fin {certificate.individuals.size}"
  match meaning with
  | .everyIs .. =>
      pure s!"(forall x : {domainSource}, ({subjectSource}) x -> ({predicateSource}) x)"
  | .everyIsNot .. =>
      pure s!"(forall x : {domainSource}, ({subjectSource}) x -> Not (({predicateSource}) x))"
  | .someIs .. =>
      pure s!"(exists x : {domainSource}, And (({subjectSource}) x) (({predicateSource}) x))"
  | .someIsNot .. =>
      pure s!"(exists x : {domainSource}, And (({subjectSource}) x) (Not (({predicateSource}) x)))"
  | .modalEvery .. | .modalSome .. | .modalEveryImp ..
  | .counterfactual .. | .counterfactualNot .. =>
      throw "CoreLogic countermodels cannot interpret profile-specific meanings"

private def conjoinSources : List String → String
  | [] => "True"
  | proposition :: tail =>
      s!"And ({proposition}) ({conjoinSources tail})"

private def elaboratePropositionSource
    (sourceName source : String) : TermElabM Expr := do
  let termStx ←
    match Parser.runParserCategory (← getEnv) `term source sourceName with
    | .ok parsed => pure parsed
    | .error message =>
        throwError "internal CoreLogic countermodel-generation failure: {message}"
  let proposition ← withoutErrToSorry <|
    elabTermEnsuringType termStx (Option.some (mkSort .zero))
  synthesizeSyntheticMVarsNoPostponing
  pure <| ← instantiateMVars proposition

def checkCountermodel
    (reconstruction : Reconstruction)
    (deduction : Deduction)
    (changes : Array MeaningChange)
    (certificate : CountermodelCertificate) :
    TermElabM (Option CountermodelEvidence) := do
  let targetClaim ← (lookupClaim reconstruction certificate.target).getDM <|
    throwErrorAt certificate.targetRef
      "unknown countermodel target Claim '{certificate.target}'"
  let premises := premiseClaims reconstruction deduction changes
  let premiseSources ← premises.mapM fun (_, meaning) =>
    match meaningModelSource certificate meaning with
    | .ok source => pure source
    | .error message => throwErrorAt certificate.ref message
  let targetSource ←
    match meaningModelSource certificate
        (meaningWithChanges targetClaim changes) with
    | .ok source => pure source
    | .error message => throwErrorAt certificate.targetRef message
  let propositionSource :=
    conjoinSources <| (premiseSources.push s!"Not ({targetSource})").toList
  let expected ←
    elaboratePropositionSource
      s!"<{certificate.name}-countermodel-proposition>"
      propositionSource
  let status ←
    runElaboration
      s!"<{certificate.name}-countermodel-certificate>"
      "by decide"
      expected
  if status == .accepted then
    let individualNames := certificate.individuals.map (·.name)
    let modelSummary := String.intercalate "; " <|
      certificate.individuals.toList.map fun individual =>
        let assignments := String.intercalate ", " <|
          individual.assignments.toList.map fun assignment =>
            let value :=
              if assignment.value == .holds then "holds" else "does not hold"
            s!"{assignment.predicate} {value}"
        s!"{individual.name}: {assignments}"
    pure <| some {
      certificate := certificate.name
      deduction := deduction.name
      target := certificate.target
      individuals := individualNames
      premiseClaims := premises.map (·.1)
      modelSummary
      proofMethod :=
        s!"The certificate is a {certificate.individuals.size}-individual finite \
         model. Lean elaborated a proof that \
         every alternative premise holds and the target fails under the displayed \
         predicate assignment, then checked that proof with the kernel."
    }
  else
    pure none

end Dialectic.CoreLogic
