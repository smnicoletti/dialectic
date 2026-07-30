# Contributing to Dialectic

Dialectic welcomes focused contributions to its Lean-native language,
semantics, diagnostics, philosophical examples, tests, and documentation.

## Before opening a pull request

1. Open the repository as a Lean project or work from its root directory.
2. Keep the pinned Lean version from `lean-toolchain`.
3. Run the complete build:

   ```sh
   lake build
   ```

4. Check that your change preserves the verification boundary: Lean establishes
   derivability under declared premises, meanings, models, and logic profiles.
   It does not establish premise truth or interpretive fidelity.

## Contribution requirements

Keep changes narrow enough to review. A contribution should:

- use the Lean-native parser, elaborator, kernel, and standard Infoview;
- avoid external parsers, generated Lean files, custom typecheckers, and custom
  VS Code extensions;
- preserve source locations and stable diagnostic categories;
- add Lean-native regression tests for new syntax, semantics, or diagnostics;
- document the exact scope of a new reasoning rule or evidence mechanism;
- keep logic-specific constructs inside an explicit profile;
- avoid presenting preserved-term rejection as general non-entailment.

Public notebooks under `Dialectic/Examples/` must be grounded in or explicitly
inspired by identifiable philosophical literature. Include a source record,
bounded passage location, original paraphrases, and a clear note about what the
formalization leaves unresolved. Synthetic cases belong under
`Dialectic/Tests/Fixtures/`.

## Documentation

Update the relevant documents with the implementation:

- `README.md` for author-facing syntax and workflow;
- `DESIGN.md` for semantics, architecture, diagnostics, and limits;
- `CORPUS.md` for philosophical source provenance and evaluation cases.

Use direct, technical prose. Keep claims tied to implemented behavior or cited
source material.

## Licensing

This project uses dual licensing:

- the public codebase is licensed under the GNU Affero General Public License
  version 3 or later (`AGPL-3.0-or-later`);
- commercial licenses may be granted separately by the copyright holders.

By submitting a contribution to this repository, you agree that your
contribution may be distributed under both:

- `AGPL-3.0-or-later`; and
- separate commercial license terms granted by the copyright holders.

Submit only work that you have the right to license under these terms. Preserve
existing copyright and license notices.

## Contact

For contribution or licensing questions, contact:

- Stefano Maria Nicoletti — <stefano@duck.com>
- Edoardo Putti — <edoardo.putti@gmail.com>
