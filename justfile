export TYPST_ROOT := justfile_directory()


default:
  @just --list

doc:
  typst c docs/manual.typ -f pdf

# test:
#   tt run --no-fail-fast

# package the library into the specified destination folder
package target="out":
  ./scripts/package.sh "{{target}}"
