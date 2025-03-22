#import "../../deps.typ": valkyrie
#import valkyrie: base-type, z-ctx, advanced, one-of
#import advanced: *

#let dictionary-type = type((:))

#let literals(
  assertions: (),
  default: (:),
  ..args,
) = {
  let values = args.pos()
  (
    base-type(
      name: "literals",
      assertions: (one-of(values), ..assertions),
      ..args.named(),
    )
      + (
        literals: values,
      )
  )
}

/// Valkyrie schema generator for mapping types.
///
/// -> schema
#let mapping(
  value-schema,
  name: "mapping",
  key-name: none,
  default: (:),
  pre-transform: (self, it) => it,
  ..args,
) = {
  (
    base-type(
      name: name,
      default: default,
      types: (dictionary-type,),
      pre-transform: pre-transform,
      ..args.named(),
    )
      + (
        key-name: key-name,
        value-schema: value-schema,
        handle-descendents: (self, it, ctx: z-ctx(), scope: ()) => {
          if (it.len() == 0 and self.optional) {
            return none
          }

          for (key, schema) in self.value-schema {
            let entry = (
              schema.validate
            )(
              schema,
              it.at(key, default: none), // implicitly handles missing entries
              ctx: ctx,
              scope: (..scope, str(key)),
            )

            if (entry != none or ctx.remove-optional-none == false) {
              it.insert(key, entry)
            }
          }
          return it
        },
      )
  )
}
