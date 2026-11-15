# preview-md-shared snapshot

This is the existing rendering package extracted from the sibling
[preview-md](https://github.com/gas217/preview-md) project. It was copied from
the local `../preview-md-shared` folder on 2026-11-08 because that folder was
not versioned or available as an independently accessible repository.

`Sources/`, `Tests/`, and `Package.swift` preserve that extraction unchanged.
The MIT license is included from MD Editor (same author). XcodeGen consumes
this copy through `project.yml`; neither sibling checkout is needed to build
MD Editor. Changes to either sibling do not automatically update this copy.

To refresh it, compare the extracted package with this directory, review the
source diff, update this note, and run `swift test --package-path
Vendor/preview-md-shared` and the app's tests. The package is a baseline
renderer; bundled KaTeX/Mermaid resources remain unimplemented as described
in `Sources/Shared/HTMLTemplate.swift`.
