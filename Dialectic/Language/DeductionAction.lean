import Lean.Server.CodeActions.Provider
import Dialectic.Language.DeductionState

/-!
The stock Lean language-server code action for inserting a suggested
controlled step. The edit replaces only the source-ranged `Continue deduction`
marker and carries the current document version.
-/

namespace Dialectic

open Lean Elab Command

structure DeductionEditAction where
  marker : Syntax
  stepName : Name
  replacement : String
deriving TypeName

structure DeductionEditActions where
  actions : Array DeductionEditAction
deriving TypeName

def versionedStepWorkspaceEdit
    (document : Lean.Lsp.VersionedTextDocumentIdentifier)
    (editRange : Lean.Lsp.Range)
    (replacement : String) : Lean.Lsp.WorkspaceEdit :=
  Lean.Lsp.WorkspaceEdit.ofTextEdit document {
    range := editRange
    newText := replacement
  }

def recordDeductionEditActions
    (proofData : Dialectic.«Deduction»)
    (stateData : DeductionStateData) : CommandElabM Unit := do
  let marker := proofData.stateRef?.getD proofData.ref
  let actions := stateData.suggestions.map fun suggestion => {
    marker
    stepName := suggestion.stepName
    replacement := suggestion.replacement
  }
  pushInfoLeaf <| .ofCustomInfo {
    stx := marker
    value := Dynamic.mk ({ actions } : DeductionEditActions)
  }

open Lean.Server Lean.Server.RequestM Lean.Lsp in
@[code_action_provider]
meta def deductionStepCodeAction : CodeActionProvider :=
  fun params snapshot => do
    let doc ← readDoc
    let requestStart := doc.meta.text.lspPosToUtf8Pos params.range.start
    let requestEnd := doc.meta.text.lspPosToUtf8Pos params.range.end
    let actionGroups := snapshot.infoTree.foldInfo (init := #[]) fun _ info found =>
      match info with
      | .ofCustomInfo custom =>
          match custom.value.get? DeductionEditActions with
          | Option.some actions => found.push actions
          | Option.none => found
      | _ => found
    let mut result : Array LazyCodeAction := #[]
    for group in actionGroups do
      for action in group.actions do
        let Option.some markerStart := action.marker.getPos? true | continue
        let Option.some markerEnd := action.marker.getTailPos? true | continue
        unless markerStart ≤ requestEnd && requestStart ≤ markerEnd do
          continue
        let editRange :=
          doc.meta.text.utf8RangeToLspRange ⟨markerStart, markerEnd⟩
        let codeAction : CodeAction := {
          title := s!"Dialectic: add Step {action.stepName}"
          kind? := Option.some "quickfix"
          isPreferred? := Option.some true
          edit? := Option.some <| versionedStepWorkspaceEdit
            doc.versionedIdentifier editRange action.replacement
        }
        result := result.push codeAction
    pure result

end Dialectic
