import Lean.Server.Test.Runner

/-!
Runs Dialectic's language-server regression inputs through Lean's own test
runner. This module is developer test infrastructure. Notebook authors use the
standard Lean extension directly.
-/

def main (args : List String) : IO Unit :=
  Lean.Server.Test.Runner.main args
