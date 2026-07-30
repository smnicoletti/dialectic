import Dialectic.Language.Frontend
import Dialectic.Language.CoreLogic
import Dialectic.Language.ModalK
import Dialectic.Language.Counterfactual
import Dialectic.Language.Diagnostic

namespace Dialectic

open Lean Elab Command
open Surface

private def throwDiagnosticAt
    (category : DiagnosticCategory)
    (ref : Syntax)
    (body : MessageData) : CommandElabM α :=
  throwErrorAt ref (diagnostic category body)

private def ensureUnique
    (category : DiagnosticCategory)
    (kind : String)
    (entries : Array (Name × Syntax)) : CommandElabM Unit := do
  for index in [:entries.size] do
    for earlier in [:index] do
      if entries[index]!.1 == entries[earlier]!.1 then
        throwDiagnosticAt category entries[index]!.2
          m!"duplicate {kind} identifier '{entries[index]!.1}'"

private def requirePredicate
    (lexicon : Dialectic.Vocabulary)
    (logicName predicate : Name)
    (ref : Syntax) : CommandElabM Unit := do
  unless lexicon.predicates.any (fun word => word.name == predicate) do
    throwDiagnosticAt .vocabulary ref
      m!"unknown {logicName} predicate '{predicate}'; declare it in Vocabulary"

private def requireIndividual
    (lexicon : Dialectic.Vocabulary)
    (logicName individual : Name)
    (ref : Syntax) : CommandElabM Unit := do
  unless lexicon.individuals.any (fun word => word.name == individual) do
    throwDiagnosticAt .vocabulary ref
      m!"unknown {logicName} Object '{individual}'; declare it in Vocabulary"

private def validateMeaning
    (logicName : Name)
    (lexicon : Dialectic.Vocabulary)
    (semanticForm : Meaning)
    (ref : Syntax) : CommandElabM Unit := do
  match logicName, semanticForm with
  | `CoreLogic, .everyIs subject noun predicate
  | `CoreLogic, .everyIsNot subject noun predicate
  | `CoreLogic, .someIs subject noun predicate
  | `CoreLogic, .someIsNot subject noun predicate =>
      unless noun == lexicon.typeWord.noun do
        throwDiagnosticAt .vocabulary ref
          m!"unknown domain noun '{noun}'; Vocabulary declares \
             '{lexicon.typeWord.noun}'"
      requirePredicate lexicon logicName subject ref
      requirePredicate lexicon logicName predicate ref
  | `CoreLogic, _ =>
      throwDiagnosticAt .profile ref
        "this modal phrase is unavailable under CoreLogic; select ModalK in a \
         separately named reconstruction"
  | `ModalK, .modalEvery individual predicate
      | `ModalK, .modalSome individual predicate =>
      requireIndividual lexicon logicName individual ref
      requirePredicate lexicon logicName predicate ref
  | `ModalK, .modalEveryImp individual antecedent consequent =>
      requireIndividual lexicon logicName individual ref
      requirePredicate lexicon logicName antecedent ref
      requirePredicate lexicon logicName consequent ref
  | `ModalK, _ =>
      throwDiagnosticAt .profile ref
        "this phrase is unavailable under ModalK; profiles do not \
         silently share controlled semantics"
  | `Counterfactual, .counterfactual individual antecedent consequent
      | `Counterfactual, .counterfactualNot individual antecedent consequent =>
      requireIndividual lexicon logicName individual ref
      requirePredicate lexicon logicName antecedent ref
      requirePredicate lexicon logicName consequent ref
  | `Counterfactual, _ =>
      throwDiagnosticAt .profile ref
        "this phrase is unavailable under Counterfactual; the bounded \
         counterfactual connective is not material implication or ModalK"
  | _, _ =>
      throwDiagnosticAt .profile ref m!"unsupported logic profile '{logicName}'"

private def validateModelWorlds
    (logicName : Name)
    (lexicon : Dialectic.Vocabulary)
    (worlds : Array ModelWorld)
    (ref : Syntax) : CommandElabM Unit := do
  if worlds.isEmpty then
    throwDiagnosticAt .countermodelRejected ref
      "a finite semantic countermodel must contain at least one World"
  ensureUnique .vocabulary "Model World" <|
    worlds.map fun modelWorld => (modelWorld.name, modelWorld.ref)
  for modelWorld in worlds do
    ensureUnique .vocabulary s!"Predicate assignment in World '{modelWorld.name}'" <|
      modelWorld.assignments.map fun assignment => (assignment.predicate, assignment.ref)
    for assignment in modelWorld.assignments do
      requirePredicate lexicon logicName assignment.predicate assignment.ref
    for predicate in lexicon.predicates do
      unless modelWorld.assignments.any (fun assignment =>
          assignment.predicate == predicate.name) do
        throwDiagnosticAt .vocabulary modelWorld.ref
          m!"Model World '{modelWorld.name}' must assign Vocabulary Predicate \
             '{predicate.name}'"

private def validateModelEdges
    (worlds : Array ModelWorld)
    (kind : String)
    (edges : Array ModelEdge) : CommandElabM Unit := do
  for edge in edges do
    unless worlds.any (fun modelWorld => modelWorld.name == edge.source) do
      throwDiagnosticAt .countermodelRejected edge.ref
        m!"unknown {kind} source World '{edge.source}'"
    unless worlds.any (fun modelWorld => modelWorld.name == edge.target) do
      throwDiagnosticAt .countermodelRejected edge.ref
        m!"unknown {kind} target World '{edge.target}'"

private def validateDescriptionEdges
    (states : Array ModelState)
    (kind : String)
    (edges : Array ModelEdge) : CommandElabM Unit := do
  for edge in edges do
    unless states.any (fun state => state.name == edge.source) do
      throwDiagnosticAt .model edge.ref
        m!"unknown {kind} source state '{edge.source}'"
    unless states.any (fun state => state.name == edge.target) do
      throwDiagnosticAt .model edge.ref
        m!"unknown {kind} target state '{edge.target}'"

private def validateModelDescription
    (profileName : Name)
    (lexicon : Dialectic.Vocabulary)
    (modelData : ModelDescription) : CommandElabM Unit := do
  if modelData.states.isEmpty then
    throwDiagnosticAt .model modelData.ref "Model must describe at least one state"
  ensureUnique .model "Model state" <|
    modelData.states.map fun state => (state.name, state.ref)
  let actualStates := modelData.states.filter fun state =>
    state.kind == .actualWorld || state.kind == .actualSituation
  unless actualStates.size == 1 do
    throwDiagnosticAt .model modelData.ref
      "Model must identify exactly one actual world or actual situation"
  for state in modelData.states do
    ensureUnique .model s!"fact in state '{state.name}'" <|
      state.assignments.map fun assignment =>
        (assignment.individual.append assignment.predicate, assignment.ref)
    for assignment in state.assignments do
      requireIndividual lexicon profileName assignment.individual assignment.ref
      requirePredicate lexicon profileName assignment.predicate assignment.ref
    for individual in lexicon.individuals do
      for predicate in lexicon.predicates do
        unless state.assignments.any fun assignment =>
            assignment.individual == individual.name &&
            assignment.predicate == predicate.name do
          throwDiagnosticAt .model state.ref
            m!"State '{state.name}' must say whether Object '{individual.name}' \
               is '{predicate.name}'"
  validateDescriptionEdges modelData.states "accessibility" modelData.accessibility
  validateDescriptionEdges modelData.states "selection" modelData.selection
  if profileName == `ModalK then
    unless modelData.states.all fun state =>
        state.kind == .actualWorld || state.kind == .possibleWorld do
      throwDiagnosticAt .model modelData.ref
        "ModalK Models use Actual world and Possible world states"
    unless modelData.selection.isEmpty do
      throwDiagnosticAt .profile modelData.ref
        "Closest situations belong to the Counterfactual profile, not ModalK"
  else if profileName == `Counterfactual then
    unless modelData.states.all fun state =>
        state.kind == .actualSituation ||
        state.kind == .counterfactualSituation do
      throwDiagnosticAt .model modelData.ref
        "Counterfactual Models use Actual situation and Counterfactual situation states"
    unless modelData.accessibility.isEmpty do
      throwDiagnosticAt .profile modelData.ref
        "Accessibility belongs to ModalK, not the Counterfactual profile"
    if modelData.selection.isEmpty then
      throwDiagnosticAt .model modelData.ref
        "a Counterfactual Model must select at least one closest situation"
  else
    throwDiagnosticAt .profile modelData.ref
      "first-class world and situation Models are currently implemented for \
       ModalK and Counterfactual"

private def validateNotebook (notebook : Notebook) : CommandElabM Unit := do
  unless notebook.«profile» == `CoreLogic || notebook.«profile» == `ModalK ||
      notebook.«profile» == `Counterfactual do
    throwDiagnosticAt .profile notebook.profileRef
      m!"logic profile '{notebook.«profile»}' is recognized as a profile selection \
         but is not executable in Dialectic. Use CoreLogic, ModalK, or \
         Counterfactual; other \
         profiles are never silently compiled with either semantics."

  unless notebook.«alternative».base == notebook.«original».name do
    throwDiagnosticAt .delta notebook.«alternative».ref
      m!"Alternative '{notebook.«alternative».name}' is based on \
         '{notebook.«alternative».base}', but the reconstruction in this notebook \
         is '{notebook.«original».name}'"

  ensureUnique .vocabulary "Predicate" <|
    notebook.«vocabulary».predicates.map fun predicate =>
      (predicate.name, predicate.ref)
  for predicate in notebook.«vocabulary».predicates do
    unless predicate.domain == notebook.«vocabulary».typeWord.leanName do
      throwDiagnosticAt .vocabulary predicate.ref
        m!"Predicate '{predicate.name}' describes '{predicate.domain}', but the \
           executable fragment's Type is '{notebook.«vocabulary».typeWord.leanName}'"
  ensureUnique .vocabulary "Object" <|
    notebook.«vocabulary».individuals.map fun individual =>
      (individual.name, individual.ref)
  for individual in notebook.«vocabulary».individuals do
    unless individual.domain == notebook.«vocabulary».typeWord.leanName do
      throwDiagnosticAt .vocabulary individual.ref
        m!"Object '{individual.name}' has Type '{individual.domain}', but this \
           notebook declares Type '{notebook.«vocabulary».typeWord.leanName}'"
  ensureUnique .vocabulary "Relation" <|
    notebook.«vocabulary».relations.map fun relationData =>
      (relationData.name, relationData.ref)
  for relationData in notebook.«vocabulary».relations do
    unless relationData.domain == notebook.«vocabulary».typeWord.leanName &&
        relationData.range == notebook.«vocabulary».typeWord.leanName do
      throwDiagnosticAt .vocabulary relationData.ref
        m!"Relation '{relationData.name}' links '{relationData.domain}' to \
           '{relationData.range}', but the executable fragment currently declares \
           only Type '{notebook.«vocabulary».typeWord.leanName}'"
  if (notebook.«profile» == `ModalK || notebook.«profile» == `Counterfactual) &&
      !notebook.«vocabulary».relations.isEmpty then
    throwDiagnosticAt .profile notebook.«vocabulary».ref
      m!"{notebook.«profile»} keeps accessibility or closest-situation structure \
         in Model, not as a domain Relation in Vocabulary"
  if notebook.«profile» == `ModalK || notebook.«profile» == `Counterfactual then
    unless notebook.«vocabulary».individuals.size == 1 do
      throwDiagnosticAt .vocabulary notebook.«vocabulary».ref
        m!"the implemented {notebook.«profile»} ground fragment requires exactly \
           one named Object"
    let modelData ← notebook.model?.getDM <|
      throwDiagnosticAt .model notebook.ref
        m!"{notebook.«profile»} requires a first-class Model section"
    validateModelDescription notebook.«profile» notebook.«vocabulary» modelData

  ensureUnique .parseSection "Source sentence" <|
    notebook.«source».sentences.map fun sourceLine =>
      (Name.mkSimple s!"sentence{sourceLine.number}", sourceLine.ref)
  ensureUnique .parseSection "Claim" <|
    notebook.«original».claims.map fun claimData => (claimData.name, claimData.ref)
  ensureUnique .parseSection "Deduction" <|
    notebook.«original».deductions.map fun proofData => (proofData.name, proofData.ref)

  for claimData in notebook.«original».claims do
    unless claimData.«source» == notebook.«source».name do
      throwDiagnosticAt .parseSection claimData.ref
        m!"Claim '{claimData.name}' links to Source '{claimData.«source»}', but this \
           notebook declares Source '{notebook.«source».name}'"
    unless notebook.«source».sentences.any (fun sourceLine =>
        sourceLine.number == claimData.«sentence») do
      throwDiagnosticAt .parseSection claimData.ref
        m!"Claim '{claimData.name}' links to missing source sentence {claimData.«sentence»}"
    validateMeaning notebook.«profile» notebook.«vocabulary»
      claimData.«meaning» claimData.meaningRef

  for proofData in notebook.«original».deductions do
    ensureUnique .parseSection "Step" <|
      proofData.steps.map fun step => (step.name, step.ref)
    let mut available :=
      notebook.«original».claims.foldl (init := #[]) fun names claimData =>
        names.push claimData.name
    for step in proofData.steps do
      for input in #[step.left, step.right] do
        unless available.contains input do
          throwDiagnosticAt .parseSection step.ref
            m!"Step '{step.name}' refers to unknown Claim or earlier result '{input}'"
      unless notebook.«original».claims.any (fun claimData =>
          claimData.name == step.conclusion) do
        throwDiagnosticAt .parseSection step.ref
          m!"Step '{step.name}' concludes undeclared Claim '{step.conclusion}'"
      available := available.push step.conclusion

  for revision in notebook.«alternative».changes do
    let claimData ←
      match notebook.«original».claims.find? (fun candidate =>
          candidate.name == revision.«claim») with
      | Option.some found => pure found
      | Option.none =>
          throwDiagnosticAt .delta revision.ref
            m!"Change targets unknown Claim '{revision.«claim»}'"
    unless revision.«original» == claimData.«meaning» do
      throwDiagnosticAt .delta revision.ref
        m!"Original meaning does not match Claim '{revision.«claim»}'. The paired \
           delta must quote the preserved reconstruction exactly."
    validateMeaning notebook.«profile» notebook.«vocabulary»
      revision.«alternative» revision.alternativeRef

  unless notebook.«original».deductions.any (fun proofData =>
      proofData.name == notebook.«alternative».recheck) do
    throwDiagnosticAt .parseSection notebook.«alternative».recheckRef
      m!"Recheck names unknown Deduction '{notebook.«alternative».recheck}'"

  if let Option.some certificate := notebook.«alternative».countermodel? then
    unless notebook.«profile» == `CoreLogic do
      throwDiagnosticAt .profile certificate.ref
        "the implemented Countermodel certificate belongs to CoreLogic; modal \
         countermodels require a separate profile-specific semantics"
    ensureUnique .vocabulary "Countermodel Individual" <|
      certificate.individuals.map fun individual =>
        (individual.name, individual.ref)
    for individual in certificate.individuals do
      ensureUnique .vocabulary
          s!"Countermodel Predicate assignment for Individual '{individual.name}'" <|
        individual.assignments.map fun assignment =>
          (assignment.predicate, assignment.ref)
      for assignment in individual.assignments do
        requirePredicate notebook.«vocabulary» notebook.«profile»
          assignment.predicate assignment.ref
      for predicate in notebook.«vocabulary».predicates do
        unless individual.assignments.any fun assignment =>
            assignment.predicate == predicate.name do
          throwDiagnosticAt .vocabulary individual.ref
            m!"Countermodel Individual '{individual.name}' must assign Vocabulary \
               predicate '{predicate.name}'"
    let targetClaim? := notebook.«original».claims.find? fun claimData =>
      claimData.name == certificate.target
    if targetClaim?.isNone then
      throwDiagnosticAt .nonEntailment certificate.targetRef
        m!"Countermodel targets unknown Claim '{certificate.target}'"
    let selected? := notebook.«original».deductions.find? fun proofData =>
      proofData.name == notebook.«alternative».recheck
    if let Option.some selected := selected? then
      let finalTarget? := selected.steps.back?.map (·.conclusion)
      unless finalTarget? == Option.some certificate.target do
        throwDiagnosticAt .nonEntailment certificate.targetRef
          m!"Countermodel target '{certificate.target}' must be the final target \
             of rechecked Deduction '{selected.name}'"

  if let Option.some certificate := notebook.«alternative».modalCountermodel? then
    throwDiagnosticAt .parseSection certificate.ref
      "Do not declare a Modal countermodel. Describe a neutral Model and ask \
       Dialectic to Analyze it; the analyzer determines whether it is a \
       counterexample."

  if let Option.some certificate :=
      notebook.«alternative».counterfactualCountermodel? then
    throwDiagnosticAt .parseSection certificate.ref
      "Do not declare a Counterfactual countermodel. Describe actual and \
       counterfactual situations in Model and ask Dialectic to Analyze it."

  if let Option.some analysis := notebook.«alternative».modelAnalysis? then
    let modelData ← notebook.model?.getDM <|
      throwDiagnosticAt .model analysis.modelRef
        "Analyze model requires a Model section"
    unless analysis.«model» == modelData.name do
      throwDiagnosticAt .model analysis.modelRef
        m!"Analyze model names '{analysis.«model»}', but this notebook declares \
           Model '{modelData.name}'"
    unless notebook.«profile» == `ModalK ||
        notebook.«profile» == `Counterfactual do
      throwDiagnosticAt .profile analysis.ref
        "Model analysis is currently executable under ModalK and Counterfactual"
    let targetClaim? := notebook.«original».claims.find? fun claimData =>
      claimData.name == analysis.target
    if targetClaim?.isNone then
      throwDiagnosticAt .nonEntailment analysis.targetRef
        m!"Model analysis targets unknown Claim '{analysis.target}'"
    let selected? := notebook.«original».deductions.find? fun proofData =>
      proofData.name == notebook.«alternative».recheck
    if let Option.some selected := selected? then
      let finalTarget? := selected.steps.back?.map (·.conclusion)
      unless finalTarget? == Option.some analysis.target do
        throwDiagnosticAt .nonEntailment analysis.targetRef
          m!"Model analysis target '{analysis.target}' must be the final target \
             of rechecked Deduction '{selected.name}'"

  let certificateCount :=
    (if notebook.«alternative».countermodel?.isSome then 1 else 0) +
    (if notebook.«alternative».modalCountermodel?.isSome then 1 else 0) +
    (if notebook.«alternative».counterfactualCountermodel?.isSome then 1 else 0) +
    (if notebook.«alternative».modelAnalysis?.isSome then 1 else 0)
  if certificateCount > 1 then
    throwDiagnosticAt .countermodelRejected notebook.«alternative».ref
      "an Alternative may contain only one profile-specific countermodel"

  for challenge in notebook.«alternative».objections do
    let targetsClaim := notebook.«original».claims.any (fun claimData =>
      claimData.name == challenge.target)
    let targetsDeduction := notebook.«original».deductions.any (fun proofData =>
      proofData.name == challenge.target ||
      proofData.steps.any (fun step => step.name == challenge.target))
    unless targetsClaim || targetsDeduction do
      throwDiagnosticAt .interpretive challenge.ref
        m!"Objection '{challenge.name}' targets unknown Claim, Step, or Deduction \
           '{challenge.target}'"

private def statusTerm
    (status : DeductionStatus) : CommandElabM (TSyntax `term) :=
  match status with
  | .accepted => `(DeductionStatus.accepted)
  | .rejected => `(DeductionStatus.rejected)

private def inconsistencyTerm
    (status : InconsistencyStatus) : CommandElabM (TSyntax `term) :=
  match status with
  | .witnessed => `(InconsistencyStatus.witnessed)
  | .notWitnessed => `(InconsistencyStatus.notWitnessed)
  | .notChecked => `(InconsistencyStatus.notChecked)

private def nonEntailmentTerm
    (status : NonEntailmentStatus) : CommandElabM (TSyntax `term) :=
  match status with
  | .certified => `(NonEntailmentStatus.certified)
  | .notEstablished => `(NonEntailmentStatus.notEstablished)

private def resultName
    (notebookName reconstructionName : Name)
    (suffix : String) : Name :=
  (notebookName.appendAfter s!"_{reconstructionName}").appendAfter suffix

private def defineStatus
    (name : Name)
    (status : DeductionStatus) : CommandElabM Unit := do
  let identifier := mkIdent name
  let value ← statusTerm status
  elabCommand <| ← `(command|
    def $identifier : DeductionStatus := $value)

private def defineInconsistency
    (name : Name)
    (status : InconsistencyStatus) : CommandElabM Unit := do
  let identifier := mkIdent name
  let value ← inconsistencyTerm status
  elabCommand <| ← `(command|
    def $identifier : InconsistencyStatus := $value)

private def defineNonEntailment
    (name : Name)
    (status : NonEntailmentStatus) : CommandElabM Unit := do
  let identifier := mkIdent name
  let value ← nonEntailmentTerm status
  elabCommand <| ← `(command|
    def $identifier : NonEntailmentStatus := $value)

private def stateAsCertificateWorld (state : ModelState) : ModelWorld := {
  name := state.name
  assignments := state.assignments.map fun assignment => {
    predicate := assignment.predicate
    value := assignment.value
    ref := assignment.ref
  }
  ref := state.ref
}

private def modalCertificateFromModel
    (modelData : ModelDescription)
    (analysis : ModelAnalysis) : Option ModalCountermodelCertificate := do
  let actual ← modelData.actualState?
  pure {
    name := modelData.name.appendAfter "_analysis"
    target := analysis.target
    designatedWorld := actual.name
    worlds := modelData.states.map stateAsCertificateWorld
    «accessibility» := modelData.accessibility
    ref := analysis.ref
    targetRef := analysis.targetRef
    designatedRef := actual.ref
  }

private def counterfactualCertificateFromModel
    (modelData : ModelDescription)
    (analysis : ModelAnalysis) :
    Option CounterfactualCountermodelCertificate := do
  let actual ← modelData.actualState?
  pure {
    name := modelData.name.appendAfter "_analysis"
    target := analysis.target
    actualWorld := actual.name
    worlds := modelData.states.map stateAsCertificateWorld
    «selection» := modelData.selection
    ref := analysis.ref
    targetRef := analysis.targetRef
    actualRef := actual.ref
  }

private def checkNegativeEvidence
    (notebook : Notebook)
    (selectedDeduction : Dialectic.«Deduction») :
    CommandElabM (Option CountermodelEvidence) := do
  if notebook.«profile» == `CoreLogic then
    match notebook.«alternative».countermodel? with
    | Option.none => pure Option.none
    | Option.some certificate =>
        liftTermElabM <| CoreLogic.checkCountermodel notebook.«original»
          selectedDeduction notebook.«alternative».changes certificate
  else if notebook.«profile» == `ModalK then
    match notebook.«alternative».modelAnalysis?, notebook.model? with
    | Option.some analysis, Option.some modelData =>
        match modalCertificateFromModel modelData analysis with
        | Option.some certificate =>
            liftTermElabM <| ModalK.checkCountermodel notebook.«original»
              selectedDeduction notebook.«alternative».changes certificate
        | Option.none => pure Option.none
    | _, _ => pure Option.none
  else if notebook.«profile» == `Counterfactual then
    match notebook.«alternative».modelAnalysis?, notebook.model? with
    | Option.some analysis, Option.some modelData =>
        match counterfactualCertificateFromModel modelData analysis with
        | Option.some certificate =>
            liftTermElabM <| Counterfactual.checkCountermodel notebook.«original»
              selectedDeduction notebook.«alternative».changes certificate
        | Option.none => pure Option.none
    | _, _ => pure Option.none
  else
    pure Option.none

@[command_elab Dialectic.Surface.cnlArgument]
meta def elabCnlArgument : CommandElab := fun stx => do
  let notebook ← parseNotebook stx
  validateNotebook notebook

  let selectedDeduction ←
    match notebook.«original».deductions.find? (fun proofData =>
        proofData.name == notebook.«alternative».recheck) with
    | Option.some proofData => pure proofData
    | Option.none => throwErrorAt notebook.«alternative».recheckRef
        "internal validated-deduction lookup failure"
  let originalStatus ← liftTermElabM <| match notebook.«profile» with
    | `CoreLogic =>
        CoreLogic.checkDeduction notebook.«vocabulary» notebook.«original»
          selectedDeduction
    | `ModalK =>
        ModalK.checkDeduction notebook.«vocabulary» notebook.«original»
          selectedDeduction
    | `Counterfactual =>
        Counterfactual.checkDeduction notebook.«vocabulary» notebook.«original»
          selectedDeduction
    | _ => throwError "internal profile dispatch failure"
  let alternativeStatus ← liftTermElabM <| match notebook.«profile» with
    | `CoreLogic =>
        CoreLogic.checkDeduction notebook.«vocabulary» notebook.«original»
          selectedDeduction notebook.«alternative».changes
    | `ModalK =>
        ModalK.checkDeduction notebook.«vocabulary» notebook.«original»
          selectedDeduction notebook.«alternative».changes
    | `Counterfactual =>
        Counterfactual.checkDeduction notebook.«vocabulary» notebook.«original»
          selectedDeduction notebook.«alternative».changes
    | _ => throwError "internal profile dispatch failure"
  let alternativeInconsistency ←
    if notebook.«profile» == `CoreLogic then
      liftTermElabM <|
        CoreLogic.checkInconsistency notebook.«vocabulary» notebook.«original»
          selectedDeduction notebook.«alternative».changes
    else
      pure { status := .notChecked, evidence? := none }
  let alternativeEvidence? ← checkNegativeEvidence notebook selectedDeduction
  let alternativeNonEntailment : NonEntailmentResult ←
    match alternativeEvidence? with
    | Option.some evidence =>
        pure { status := .certified, evidence? := Option.some evidence }
    | Option.none =>
        if notebook.«alternative».modelAnalysis?.isSome then
          pure { status := .notEstablished, evidence? := Option.none }
        else
          let certificateRef? :=
            notebook.«alternative».countermodel?.map (·.ref) <|>
            notebook.«alternative».modalCountermodel?.map (·.ref) <|>
            notebook.«alternative».counterfactualCountermodel?.map (·.ref)
          match certificateRef? with
          | Option.none =>
            pure { status := .notEstablished, evidence? := Option.none }
          | Option.some ref =>
            throwDiagnosticAt .countermodelRejected ref
              "The displayed finite model is not a counterexample: Lean could \
               not check all alternative premises together with the failure of \
               the target under the selected profile semantics."

  defineStatus
    (resultName notebook.name notebook.«original».name "_deductionStatus")
    originalStatus
  defineStatus
    (resultName notebook.name notebook.«alternative».name "_deductionStatus")
    alternativeStatus
  defineInconsistency
    (resultName notebook.name notebook.«alternative».name "_inconsistencyStatus")
    alternativeInconsistency.status
  defineNonEntailment
    (resultName notebook.name notebook.«alternative».name "_nonEntailmentStatus")
    alternativeNonEntailment.status

  match originalStatus with
  | .accepted =>
      logInfoAt selectedDeduction.ref
        (diagnostic .deductionAccepted
          m!"{notebook.«original».name}: Deduction '{selectedDeduction.name}' \
              follows under this reconstruction and the {notebook.«profile»} \
              profile. This does not assess the assumptions or source text.")
  | .rejected =>
      logErrorAt selectedDeduction.ref
        (diagnostic .deductionRejected
          m!"{notebook.«original».name}: Deduction '{selectedDeduction.name}' \
              does not work under this reconstruction and profile.")

  let recheckSummary :=
    recheckSummaryData selectedDeduction notebook.«alternative» alternativeStatus
  match alternativeStatus with
  | .accepted =>
      logInfoAt notebook.«alternative».recheckRef
        (diagnostic .preservedAccepted
          m!"{notebook.«alternative».name}: {recheckSummary.heading} \
              {recheckSummary.detail}")
  | .rejected =>
      logWarningAt notebook.«alternative».recheckRef
        (diagnostic .preservedRejected
          m!"{notebook.«alternative».name}: {recheckSummary.heading} \
              {recheckSummary.detail} This rejects only the preserved \
              deduction. Non-entailment requires separate counterexample \
              evidence.")

  match alternativeInconsistency.status, alternativeInconsistency.evidence? with
  | .witnessed, Option.some evidence =>
      let claims := String.intercalate ", " <|
        evidence.participatingClaims.toList.map (fun name => name.toString)
      let message : MessageData :=
        if recheckSummary.unaffected then
          m!"Alternative assumptions are contradictory in \
              {notebook.«alternative».name}: Claims {claims} cannot all hold \
              together. This contradiction is in the alternative assumption \
              set; it does not come from rechecking accepted Deduction \
              '{selectedDeduction.name}'."
        else
          m!"Alternative assumptions are contradictory in \
              {notebook.«alternative».name}: Claims {claims} cannot all hold \
              together. Rechecking Deduction '{selectedDeduction.name}' is \
              reported separately. This does not decide which reading should \
              change."
      logWarningAt notebook.«alternative».ref
        (diagnostic .alternativeInconsistency message)
  | .witnessed, Option.none =>
      logWarningAt notebook.«alternative».ref
        (diagnostic .alternativeInconsistency
          m!"Alternative assumptions are contradictory in \
              {notebook.«alternative».name}. This result concerns the premise \
              set as a whole; deduction rechecking is reported separately.")
  | .notWitnessed, _ =>
      logInfoAt notebook.«alternative».ref
        (diagnostic .consistencyNotEstablished
          m!"No contradiction found in {notebook.«alternative».name}. The checked \
              assumptions did not produce a contradiction in the available \
              test. This does not show that the assumptions are consistent.")
  | .notChecked, _ =>
      logInfoAt notebook.«alternative».ref
        (diagnostic .consistencyNotEstablished
          m!"No contradiction check is available for {notebook.«profile»}. \
              No consistency judgment is made.")

  for revision in notebook.«alternative».changes do
    logInfoAt revision.ref
      (diagnostic .delta
        m!"{revision.«claim»}: '{revision.«original».render}' → \
            '{revision.«alternative».render}'")
  for challenge in notebook.«alternative».objections do
    logInfoAt challenge.ref
      (diagnostic .interpretive
        m!"Objection {challenge.name} about {challenge.target}: \
            {challenge.statement} This is recorded for comparison; Lean does not \
            judge the interpretation.")
  logInfoAt notebook.profileRef
    (diagnostic .profile
      m!"This notebook uses the {notebook.«profile»} logic profile.")
  logInfoAt notebook.profileRef
    (diagnostic .capability (capabilityMessage notebook.«profile»))
  if let Option.some modelData := notebook.model? then
    logInfoAt modelData.ref
      (diagnostic .model
        m!"Model {modelData.name}: philosopher-authored description with \
            {modelData.states.size} states. Dialectic analyzes this model; the \
            author does not declare it to be a counterexample.")
  match alternativeNonEntailment.status, alternativeNonEntailment.evidence? with
  | .certified, Option.some evidence =>
      let ref :=
        (notebook.«alternative».countermodel?.map (·.ref) <|>
         notebook.«alternative».modalCountermodel?.map (·.ref) <|>
         notebook.«alternative».counterfactualCountermodel?.map (·.ref) <|>
         notebook.«alternative».modelAnalysis?.map (·.ref)).getD
          notebook.«alternative».ref
      logInfoAt ref
        (diagnostic .nonEntailmentCertified
          (if notebook.«alternative».modelAnalysis?.isSome then
            m!"Counterexample found by analyzing the declared Model: \
                {evidence.modelSummary} All alternative assumptions hold there \
                while {evidence.target} is false. Lean checked the analyzer's \
                generated evidence. This establishes non-entailment for the \
                reconstruction, not a judgment about the source text."
           else
            m!"Counterexample evidence accepted: {evidence.modelSummary} All \
                alternative assumptions hold while {evidence.target} is false. \
                Lean checked the supplied finite evidence. This establishes \
                non-entailment for the reconstruction, not a judgment about \
                the source text."))
  | .certified, Option.none =>
      logInfoAt notebook.«alternative».ref
        (diagnostic .nonEntailmentCertified
          "The conclusion does not follow from this alternative. Lean checked \
           a concrete example where all alternative assumptions hold and the \
           conclusion is false. The counterexample, not term rejection alone, \
           establishes non-entailment.")
  | .notEstablished, _ =>
      logInfoAt notebook.«alternative».ref
        (diagnostic .nonEntailmentNotEstablished
          "Non-entailment not established. No checked counterexample shows all \
           alternative assumptions holding while the conclusion is false. The \
           preserved deduction's recheck result does not settle whether another \
           deduction could reach the conclusion.")
  logInfoAt notebook.ref
    (diagnostic .document
      m!"Argument {notebook.name}: reconstruction checks completed.")

  saveDiagnosticsPanel notebook selectedDeduction originalStatus alternativeStatus
    alternativeInconsistency alternativeNonEntailment

end Dialectic
