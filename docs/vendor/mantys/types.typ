#import "../../deps.typ": mantys
#import mantys: (
  is as is_,
  links,
  styles,
  values,
  custom-type,
  is-custom-type,
  link-custom-type,
  type-box,
  _type-aliases,
  _type-map,
)


/// Dictionary of builtin types, mapping the types name to its actual type.
#let _type-map = (
  "auto": auto,
  "none": none,
  // foundations
  arguments: arguments,
  array: array,
  bool: bool,
  bytes: bytes,
  content: content,
  datetime: datetime,
  dictionary: dictionary,
  float: float,
  function: function,
  int: int,
  location: location,
  module: module,
  plugin: plugin,
  regex: regex,
  selector: selector,
  str: str,
  type: type,
  label: label,
  version: version,
  // layout
  alignment: alignment,
  angle: angle,
  direction: direction,
  fraction: fraction,
  length: length,
  ratio: ratio,
  relative: relative,
  // visualize
  color: color,
  gradient: gradient,
  stroke: stroke,
  // extension
  number: float,
)

/// Dictionary of colors to use for builtin types.
///
/// Modified to keep consistent with official docs.
#let _type-colors = {
  let red = rgb("#ffcbc4") // for keyword
  let gray = rgb("#eff0f3") // for special content
  let pink = rgb("#f9dfff") // for data structure
  let yellow = rgb("#ffedc1") // for arithmetic
  let purple = rgb("#d1d4fd") // for type
  let green = rgb("#d1ffe2") // for string-like
  let blue = rgb("#c6d6ec")
  let cyan = rgb("#a6eaff") // for enum
  let rainbow = gradient.linear(
    (rgb("#7cd5ff"), 0%),
    (rgb("#a6fbca"), 33%),
    (rgb("#fff37c"), 66%),
    (rgb("#ffa49d"), 100%),
  ) // for color-like
  let changeable = gradient.linear(
    (rgb("#a07aaa"), 0%),
    (rgb("#a6aff6"), 28%),
    (rgb("#89c8e5"), 50%),
    (rgb("#b7daec"), 72%),
    (rgb("#dcac68"), 100%),
  ) // for time-like

  (
    // fallback
    default: gray,
    custom: rgb("#fcfdb7"),
    // special
    any: gray,
    // foundations
    arguments: pink,
    array: pink,
    "auto": red,
    bool: yellow,
    bytes: pink,
    content: rgb("#a6ebe6"),
    datetime: changeable,
    decimal: yellow,
    dictionary: pink,
    duration: changeable,
    float: yellow,
    function: blue,
    int: yellow,
    label: blue,
    module: blue,
    "none": red,
    plugin: blue, // not really a type
    regex: green,
    selector: blue,
    str: green,
    string: green,
    symbol: green,
    type: purple,
    version: pink,
    // layout
    alignment: cyan,
    angle: yellow,
    direction: cyan,
    fraction: yellow,
    length: yellow,
    ratio: yellow,
    relative: yellow,
    // visualize
    color: rainbow,
    gradient: rainbow,
    stroke: rainbow,
    tiling: gradient.linear(rgb("#ffd2ec"), rgb("#c6feff"), angle: -16deg).sharp(2).repeat(5), // approximation
    // introspection
    counter: gray,
    location: blue,
    state: gray,
  )
}

/// Displays a type link to the type #arg[name]. #arg[name] can
/// either be a #link(<subsec:shortcuts-types>, "builtin type") or a registered @type:custom-type.
///
/// Builtin types are linked to the official Typst reference documentation. Custom types to their location in the manual.
/// Some builtin types can be referenced by aliases like `dict` for `dictionary`.
///
/// If #arg[name] is given as a #typ.t.str it is taken as the name of the type. If #arg[name] is a #typ.type or any other value, the type of the value is displayed.
///
/// - #ex(`#dtype("string")`)
/// - #ex(`#dtype("dict")`)
/// - #ex(`#dtype(1.0)`)
/// - #ex(`#dtype(true)`)
/// - #ex(`#dtype("document")`)
/// -> content
#let dtype(
  /// Name of the type.
  /// -> any
  name,
  /// If the type should be linked to the Typst documentation or the location of the custom type.
  /// Set to #typ.v.false to disable linking.
  /// -> bool
  link: true,
) = context {
  // TODO: (jneug) parse types like "array[str]"
  let _type

  if is_.type(name) or is_._auto(name) or is_._none(name) {
    _type = name
  } else if not is_.str(name) {
    _type = type(name)
  } else {
    let name = _type-aliases.at(name, default: name)
    if name in _type-map {
      _type = _type-map.at(name)
    } else if is-custom-type(name) {
      return link-custom-type(name)
    } else {
      return links.link-dtype(name, type-box(name, _type-colors.default))
    }
  }

  _type = repr(_type)
  return links.link-dtype(_type, type-box(_type, _type-colors.at(_type)))
}


/// Change:
/// - support `tuple`.
/// - make child-schemas more flexible.
#let parse-schema(
  schema,
  expand-schemas: false,
  expand-choices: 2,
  child-schemas: (),
  // Passing in dtype and value to avoid circular imports
  _dtype: none,
  _value: none,
) = {
  let el = schema

  if schema.name in child-schemas {
    return _dtype(schema.name)
  }

  // TODO: implement expand-schemas and child-schemas options
  let options = (
    expand-schemas: expand-schemas,
    expand-choices: expand-choices,
    _dtype: _dtype,
    _value: _value,
  )

  // Recursivley handle dictionaries
  if "dictionary-schema" in el {
    if el.dictionary-schema == (:) {
      _dtype(dictionary)
    } else {
      show terms: set block(below: 0.6em)
      let inner = terms(
        hanging-indent: 1.28em,
        indent: .64em,
        ..for (key, el) in el.dictionary-schema {
          (
            terms.item(
              styles.arg(key)
                + if el.optional {
                  if el.default == none {
                    `?`
                  } else {
                    `: ` + raw(lang: "typc", repr(el.default))
                  }
                },
              parse-schema(el, child-schemas: child-schemas, ..options),
            ),
          )
        },
      )
      [`(`#inner`)`]
    }
  } else if "descendents-schema" in el {
    let inner = parse-schema(
      el.descendents-schema,
      child-schemas: child-schemas,
      ..options,
    )
    [#_dtype(array) of #inner]
  } else if "choices" in el {
    let inner = if expand-choices in (false, 0) {
      [#sym.dots]
    } else if type(expand-choices) == int and el.choices.len() > expand-choices {
      el.choices.slice(0, expand-choices).map(_value).join(", ") + [ #sym.dots]
    } else {
      el.choices.map(_value).join(", ")
    }
    [one of `(`#inner`)`]
  } else if "options" in el {
    let inner = el
      .options
      .map(el => parse-schema(
        el,
        child-schemas: child-schemas,
        ..options,
      ))
      .join[`|`]
    inner
  } else if "tuple-schema" in el {
    let inner = el
      .tuple-schema
      .map(el => parse-schema(
        el,
        child-schemas: child-schemas,
        ..options,
      ))
      .join[`,`]
    [tuple of `(`#inner`)`]
  } else if "value-schema" in el {
    let key-repr = if el.key-name != none { el.key-name } else { _dtype(str) }
    let inner = parse-schema(
      el.value-schema,
      child-schemas: child-schemas,
      ..options,
    )
    [mapping from #key-repr to #inner]
  } else if "literals" in el {
    let inner = el.literals.map(lit => raw(lang: "typc", repr(lit))).join[`|`]
    inner
  } else {
    // polyfill: `int` and `float` have the same name `number` in valkyrie
    if el.description == "integer" {
      _dtype(int)
    } else if el.description == "float" {
      _dtype(float)
    } else {
      _dtype(el.name)
    }
  }
}


#let schema(name, definition, color: auto, ..args) = {
  assert(is_.dict(definition))
  assert("valkyrie-type" in definition)

  custom-type(if name == auto { definition.name } else { name }, color: color)

  parse-schema(definition, ..args, _dtype: dtype, _value: values.value)
}
