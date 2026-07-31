import Lean

/-!
The preserved, logic-neutral document model used by the Lean-native frontend.
Logic profiles interpret `Meaning` and `DeductionStep`; they do not change the
shared source/reconstruction/alternative notebook structure.
-/

namespace Dialectic

open Lean

inductive Meaning where
  | everyIs (subject noun predicate : Name)
  | everyIsNot (subject noun predicate : Name)
  | someIs (subject noun predicate : Name)
  | someIsNot (subject noun predicate : Name)
  | modalEvery (individual predicate : Name)
  | modalSome (individual predicate : Name)
  | modalEveryImp (individual antecedent consequent : Name)
  | counterfactual (individual antecedent consequent : Name)
  | counterfactualNot (individual antecedent consequent : Name)
  deriving Repr, Inhabited, BEq

def Meaning.noun? : Meaning → Option Name
  | .everyIs _ noun _ | .everyIsNot _ noun _
  | .someIs _ noun _ | .someIsNot _ noun _ => some noun
  | .modalEvery _ _ | .modalSome _ _ | .modalEveryImp _ _ _
  | .counterfactual _ _ _ | .counterfactualNot _ _ _ => none

def Meaning.render : Meaning → String
  | .everyIs subject noun predicate =>
      s!"Every {subject} {noun} is {predicate}"
  | .everyIsNot subject noun predicate =>
      s!"Every {subject} {noun} is not {predicate}"
  | .someIs subject noun predicate =>
      s!"Some {subject} {noun} is {predicate}"
  | .someIsNot subject noun predicate =>
      s!"Some {subject} {noun} is not {predicate}"
  | .modalEvery individual predicate =>
      s!"In every possible world {individual} is {predicate}"
  | .modalSome individual predicate =>
      s!"In some possible world {individual} is {predicate}"
  | .modalEveryImp individual antecedent consequent =>
      s!"In every possible world if {individual} is {antecedent} then \
         {individual} is {consequent}"
  | .counterfactual individual antecedent consequent =>
      s!"If it were the case that {individual} is {antecedent}, then \
         {individual} is {consequent}"
  | .counterfactualNot individual antecedent consequent =>
      s!"If it were the case that {individual} is {antecedent}, then \
         {individual} is not {consequent}"

structure TypeWord where
  leanName : Name
  noun : Name
  ref : Syntax

structure PredicateWord where
  name : Name
  domain : Name
  ref : Syntax

structure IndividualWord where
  name : Name
  domain : Name
  ref : Syntax

structure RelationWord where
  name : Name
  domain : Name
  range : Name
  ref : Syntax

structure Vocabulary where
  typeWord : TypeWord
  individuals : Array IndividualWord := #[]
  predicates : Array PredicateWord
  relations : Array RelationWord
  ref : Syntax

structure SourceSentence where
  number : Nat
  text : String
  ref : Syntax

structure SourceRecord where
  name : Name
  citation : String
  location : String
  sentences : Array SourceSentence
  ref : Syntax

structure Claim where
  name : Name
  source : Name
  sentence : Nat
  paraphrase : String
  meaning : Meaning
  ref : Syntax
  meaningRef : Syntax

structure DeductionStep where
  name : Name
  left : Name
  right : Name
  conclusion : Name
  ref : Syntax

inductive DeductionDraftMarker where
  | continueDeduction
  | chooseStep
  deriving Repr, Inhabited, BEq, DecidableEq

structure Deduction where
  name : Name
  steps : Array DeductionStep
  intendedConclusion? : Option Name := none
  stateRef? : Option Syntax := none
  draftMarker : DeductionDraftMarker := .continueDeduction
  ref : Syntax

def Deduction.isIncomplete (deduction : Deduction) : Bool :=
  deduction.stateRef?.isSome

def Deduction.target? (deduction : Deduction) : Option Name :=
  deduction.intendedConclusion? <|>
    deduction.steps.back?.map (·.conclusion)

def Deduction.isChoosingStep (deduction : Deduction) : Bool :=
  deduction.isIncomplete && deduction.draftMarker == .chooseStep

private def pushNameUnique (names : Array Name) (name : Name) : Array Name :=
  if names.contains name then names else names.push name

private def resolvedDependencies
    (derived : Array (Name × Array Name))
    (name : Name) : Array Name :=
  (derived.foldl (init := Option.none) fun found entry =>
    if entry.1 == name then some entry.2 else found).getD #[name]

def Deduction.baseDependencies (deduction : Deduction) : Array Name := Id.run do
  let mut derived : Array (Name × Array Name) := #[]
  for step in deduction.steps do
    let mut dependencies := #[]
    for name in resolvedDependencies derived step.left do
      dependencies := pushNameUnique dependencies name
    for name in resolvedDependencies derived step.right do
      dependencies := pushNameUnique dependencies name
    derived := derived.push (step.conclusion, dependencies)
  return (derived.back?).map (·.2) |>.getD #[]

def Deduction.stepNames (deduction : Deduction) : Array Name :=
  deduction.steps.map (·.name)

structure Reconstruction where
  name : Name
  claims : Array Claim
  deductions : Array Deduction
  ref : Syntax

structure MeaningChange where
  claim : Name
  original : Meaning
  alternative : Meaning
  ref : Syntax
  alternativeRef : Syntax

structure Objection where
  name : Name
  target : Name
  statement : String
  ref : Syntax

inductive PredicateValue where
  | holds
  | doesNotHold
  deriving Repr, Inhabited, BEq, DecidableEq

structure PredicateAssignment where
  predicate : Name
  value : PredicateValue
  ref : Syntax

structure CountermodelIndividual where
  name : Name
  assignments : Array PredicateAssignment
  ref : Syntax

structure CountermodelCertificate where
  name : Name
  target : Name
  individuals : Array CountermodelIndividual
  ref : Syntax
  targetRef : Syntax

structure ModelWorld where
  name : Name
  assignments : Array PredicateAssignment
  ref : Syntax

structure ModelEdge where
  source : Name
  target : Name
  ref : Syntax

structure GroundAssignment where
  individual : Name
  predicate : Name
  value : PredicateValue
  ref : Syntax

inductive ModelStateKind where
  | actualWorld
  | possibleWorld
  | actualSituation
  | counterfactualSituation
  deriving Repr, Inhabited, BEq, DecidableEq

structure ModelState where
  name : Name
  kind : ModelStateKind
  assignments : Array GroundAssignment
  ref : Syntax

structure ModelDescription where
  name : Name
  states : Array ModelState
  accessibility : Array ModelEdge
  selection : Array ModelEdge
  ref : Syntax

def ModelDescription.actualState? (model : ModelDescription) : Option ModelState :=
  model.states.find? fun state =>
    state.kind == .actualWorld || state.kind == .actualSituation

structure ModelAnalysis where
  model : Name
  target : Name
  ref : Syntax
  modelRef : Syntax
  targetRef : Syntax

structure ModalCountermodelCertificate where
  name : Name
  target : Name
  designatedWorld : Name
  worlds : Array ModelWorld
  accessibility : Array ModelEdge
  ref : Syntax
  targetRef : Syntax
  designatedRef : Syntax

structure CounterfactualCountermodelCertificate where
  name : Name
  target : Name
  actualWorld : Name
  worlds : Array ModelWorld
  selection : Array ModelEdge
  ref : Syntax
  targetRef : Syntax
  actualRef : Syntax

structure Alternative where
  name : Name
  base : Name
  changes : Array MeaningChange
  recheck : Name
  countermodel? : Option CountermodelCertificate
  modalCountermodel? : Option ModalCountermodelCertificate := none
  counterfactualCountermodel? : Option CounterfactualCountermodelCertificate := none
  modelAnalysis? : Option ModelAnalysis := none
  objections : Array Objection
  ref : Syntax
  recheckRef : Syntax

structure Notebook where
  name : Name
  profile : Name
  profileDescription : String
  profileRef : Syntax
  vocabulary : Vocabulary
  model? : Option ModelDescription := none
  source : SourceRecord
  original : Reconstruction
  alternative : Alternative
  ref : Syntax

inductive DeductionStatus where
  | accepted
  | rejected
  deriving Repr, Inhabited, BEq, DecidableEq

def DeductionStatus.label : DeductionStatus → String
  | .accepted => "accepted"
  | .rejected => "rejected"

inductive InconsistencyStatus where
  | witnessed
  | notWitnessed
  | notChecked
  deriving Repr, Inhabited, BEq, DecidableEq

def InconsistencyStatus.label : InconsistencyStatus → String
  | .witnessed => "Lean-checked contradiction witnessed"
  | .notWitnessed => "no contradiction witnessed by the implemented fragment"
  | .notChecked => "no contradiction procedure is implemented for this profile"

structure ContradictionEvidence where
  universalClaim : Name
  existentialClaim : Name
  participatingClaims : Array Name
  deduction : Name
  target : Name
  proofMethod : String
  deriving Repr, Inhabited, BEq

structure InconsistencyResult where
  status : InconsistencyStatus
  evidence? : Option ContradictionEvidence
  deriving Repr, Inhabited, BEq

inductive NonEntailmentStatus where
  | certified
  | notEstablished
  deriving Repr, Inhabited, BEq, DecidableEq

def NonEntailmentStatus.label : NonEntailmentStatus → String
  | .certified => "certified by a Lean-checked countermodel or complete procedure"
  | .notEstablished => "not established; no certified countermodel"

structure CountermodelEvidence where
  certificate : Name
  deduction : Name
  target : Name
  individuals : Array Name
  premiseClaims : Array Name
  modelSummary : String
  proofMethod : String
  deriving Repr, Inhabited, BEq

structure NonEntailmentResult where
  status : NonEntailmentStatus
  evidence? : Option CountermodelEvidence
  deriving Repr, Inhabited, BEq

end Dialectic
