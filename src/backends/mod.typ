
#let use(backend) = {
  if backend == "std" {
    import "std.typ" as comp
    comp
  } else {
    panic("unknown backend: ", backend)
  }
}
