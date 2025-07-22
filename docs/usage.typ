#import "/src/lib.typ" as rm
#import rm: *


#let (N, S, W, E, NW, NE, SW, SE) = dirs

#let corner-radius = 0.2
#let pin-round = pin.with(corner-radius: corner-radius)

== Positioning Lines

This is a simple _radishom_ with single line.
In the following of the section, we will only change `my-lines` to show basic usages.

```example
#let my-lines = (
  line(
    id: "1",
    color: blue,
    pin(x: -1, y: 0),
    station([AAA]),
    station([BBB], x: 0),
    station([CCC]),
    pin(x: 1),
  ),
)

#let my-metro = metro(my-lines)
#let my-radish = radish(my-metro)
#let my-radishom = radishom(my-radish)
#my-radishom
```

To position a station, you have flexible options:
- `x` and `y`: absolute coordinates.
- `x` or `y` only: absolute coordinate, the other is inferred based to ensure the station is on the line. Will panic if the line is horizontal but only `y` is available, or the line is vertical but only `x` is available.
- `dx` or `dy`: similar to `x` and `y`, relative to the start of the segment, rather than the previous station.
- `r`: ratio of the position in the segment.
To avoid ambiguity and bad positioning due to future changes, you should only specify exactly enough positioning parameters.

When a station's position is not specified:
- If it is an interchange, it is calculated as the interaction point of transferred lines. This does not work when no intersection is available.
- Otherwise, it is interpolated between known positions.

You can specify the @cmd:station.anchor of the station, which controls how its label is placed. By default, the anchor is chosen to avoid overlapping with the line as much as possible.

#{
  let my-lines = (
    line(
      id: "1",
      color: blue,
      pin(x: 0, y: 0),
      station([start]),
      station([absolute], x: 6.5, y: 0.5, anchor: E),
      station([partial-absolute], x: 2, anchor: N),
      station([relative], dx: 4),
      station([by ratio], r: 0.55, anchor: NW),
      station([interpolated]),
      station([end]),
      pin(x: 10, y: 0),
    ),
  )

  let my-metro = metro(my-lines)
  let my-radish = radish(my-metro)
  let my-radishom = radishom(my-radish)
  my-radishom
}

The shape of a line is controlled by a series of pins.
Similar to stations, you can use `x`, `y`, `dx`, `dy` or `d` to specify the position. `d` indicates where the pin will go from the previous one.

#{
  let my-lines = (
    line(
      id: "1",
      color: blue,
      pin(x: 0, y: 0),
      pin(x: 1),
      pin(dx: 1, d: NE),
      pin(dx: 1, dy: -1),
      pin(dx: 2),
      pin(y: 1, d: NW),
    ),
  )

  let my-metro = metro(my-lines)
  let my-radish = radish(my-metro)
  let my-radishom = radishom(my-radish)
  my-radishom
}

_Advanced usage._
A line can contain multiple components, branches and loops.
You can use `end` to mark the end of a segment, allowing you to create disconnected branches.
You can use `branch` to mark the start of a branch, which indicates it is not terminal.
You can use `loop` to close the path by adding a line to the starting point or specified point. A loop pin implies `end`.

You may rely on the order of stations for other usages. In this case, you can use `reverse` to reverse the order of stations in the segment.
You can use `reverse-before` to reverse the order of all previous stations in the segment.
With these two options, you can adjust station orders at your will.

#{
  let my-lines = (
    line(
      id: "1",
      color: blue,
      pin(x: -2, y: 0),
      station([start], r: 0.1),
      station([looped], y: 1, anchor: SE),
      pin(x: 0, y: 2),
      pin(dx: 1, dy: -1),
      loop(target: "looped"),
      pin(x: 0, y: 0),
      station([b1], r: 0),
      station([branched], dx: 2, anchor: N),
      station([b2]),
      pin(dx: 4, end: true),
      pin(x: 2, y: 0, branch: true),
      station([b3]),
      pin(dy: 2),
    ),
  )

  let my-metro = metro(my-lines)
  let my-radish = radish(my-metro)
  let my-radishom = radishom(my-radish)

  my-radishom
}

You can place multiple lines in a single metro.
Each line can have its own color and index.

By default, a line with a larger index will overlay the one with a smaller index. You can specify the layer by the parameter @cmd:pin.layer to adjust the drawing order.

#{
  let my-lines = (
    line(
      id: "1",
      color: blue,
      pin(x: -2, y: 0),
      station([1s]),
      station([12]),
      station([13]),
      station([1t]),
      pin(x: 2, y: 0),
    ),
    line(
      id: "2",
      color: red,
      pin(x: -1, y: 1),
      station([2s]),
      station([12]),
      station([2t]),
      pin(x: -1, y: -1),
    ),
    line(
      id: "3",
      color: green,
      pin(x: 1, y: 1, layer: -1),
      station([3s]),
      station([13]),
      station([3t]),
      pin(x: 1, y: -1),
    ),
  )

  let my-metro = metro(my-lines)
  let my-radish = radish(my-metro)
  let my-radishom = radishom(my-radish)

  my-radishom
}

== Using Features

We provide Cargo-like features to control the rendering of lines.
You can set @cmd:line.features, @cmd:line.default-features, @cmd:metro.features, and @cmd:metro.default-features, and set @cmd:pin.cfg, @cmd:pin.cfg-not, @cmd:station.cfg or @cmd:station.cfg-not.

The features are injected at @cmd:radish. You can turn on all features (@cmd:radish.all-features), or turn off default features (@cmd:radish.default-features), and provide root features (@cmd:radish.features).

Lines have the @cmd:line.optional parameter, which indicates whether the line is optional. If it is optional, it will be disabled if the features are not enabled. // TODO - check

#{
  let my-lines = (
    line(
      id: "1",
      color: blue,
      pin(x: -2, y: 0),
      station([1s]),
      station([12]),
      station([1m]),
      station([13]),
      station([1t]),
      pin(x: 2, y: 0),
    ),
    line(
      id: "2",
      color: red,
      pin(x: -1, y: 1),
      station([2s], r: 0),
      station([12]),
      pin(x: -1, y: -1),
      station([A]),
      pin(x: 1, y: -1),
      station([13]),
      pin(x: 1, y: 1),
      // station([B]),
      loop(),
    ),
  )

  let my-metro = metro(my-lines)
  let my-radish = radish(my-metro)
  let my-radishom = radishom(my-radish)

  my-radishom
  [#my-metro.lines.at("2")]
}
== Customizing Metro Components
