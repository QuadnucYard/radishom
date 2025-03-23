#import "vendor/valkyrie.typ": valkyrie as z
#import "vendor/mantys.typ": *

#import "../src/lib.typ" as radishom
#import "schemas.typ" as s

#let show-module(name, scope: (:), ..tidy-args) = tidy-module(
  name,
  read("../src/" + name + ".typ"),
  scope: scope,
  // Some defaults you want to set
  legacy-parser: true,
  ..tidy-args.named(),
)

#show: mantys(
  // abstract: [
  //   A few paragraphs of text to describe the package.
  // ],

  examples-scope: (
    scope: (radishom: radishom),
    imports: (radishom: "*"),
  ),

  ..toml("../typst.toml"),
)


= Quick Start


= Usage


= Schemas

#info-alert[
  Some automatic fields are set to a concrete value after certain stages, which are specified after the schemas.

  The typing displayed in the schemas are after @cmd:radish.
]

#frame(title: [@type:vec2])[
  #schema(auto, s.vec2)
]

#frame(title: [@type:dir])[
  #schema("dir", s.dir, expand-choices: 8)
]

#frame(title: [@type:segment])[
  #schema(auto, s.segment, child-schemas: ("vec2",))

  #info-alert[
    Field values determined after @cmd:radish: `disabled`.
  ]
]

#frame(title: [@type:section])[
  #schema(auto, s.section, child-schemas: ("vec2",))

  #info-alert[
    Field values determined after @cmd:radish: `disabled`.
  ]
]

#frame(title: [@type:station])[
  #schema(auto, s.station, child-schemas: ("vec2", "dir"))

  #info-alert[
    Possible #dtype(auto) values before @cmd:metro: `pos`.

    Possible #dtype(auto) values before @cmd:radish: `anchor`.

    Field values determined after @cmd:radish: `disabled`, `terminal` (either undefined or `true`).
  ]
]

#frame(title: [@type:line])[
  #schema(auto, s.line, child-schemas: ("vec2", "segment", "section", "station"))

  #info-alert[
    Field values determined after @cmd:radish: `disabled`.
  ]
]

#frame(title: [@type:metro])[
  #schema(auto, s.metro, child-schemas: ("line",))
]

#frame(title: [@type:radish])[
  #schema(auto, s.radish, child-schemas: ("line",))
]


= API Reference

#let show-module = show-module.with(
  show-outline: false,
  omit-private-definitions: true,
  omit-private-parameters: true,
  sort-functions: false,
)

== Metro Elements

#show-module("elem/station")
#show-module("elem/line")
#show-module("elem/metro")
#show-module("elem/radish")
#show-module("radishom")

== Shapes

#show-module("elem/shapes")

== Utilities

#let q-import(path) = {
  import path as mod
  dictionary(mod)
}
#let show-module-(path) = {
  show-module(path, scope: q-import("/src/" + path + ".typ"))
}

#show-module-("core/dir")
#show-module-("core/anchor")
#show-module-("core/feature")
// show-module("core/vec")
#show-module-("core/utils")
