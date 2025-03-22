
/// Cardinal and intercardinal direction constants.
#let dirs = (
  N: "north",
  S: "south",
  W: "west",
  E: "east",
  NW: "north-west",
  NE: "north-east",
  SW: "south-west",
  SE: "south-east",
)

/// Resolves the final position of a segment end point based on given parameters.
///
/// The function handles several cases:
/// 1. When coordinates are 'auto', calculates actual position based on direction;
/// 2. For cardinal directions (N,S,E,W), uses appropriate offset;
/// 3. For diagonal directions (NE,SE,NW,SW), calculates position maintaining 45° angles;
/// 4. When direction is 'auto', uses available offset or maintains last position.
///
/// Returns the modified `end-pos`.
///
/// - origin (dictionary): The previous position object with x, y coordinates.
/// - target (dictionary): A position object containing x, y coordinates, dx, dy offsets and direction.
/// -> dictionary
#let resolve-target-pos(origin, target) = {
  let dir = target.d
  let x = if target.x != auto {
    target.x
  } else if dir == auto {
    if target.dx != auto {
      origin.x + target.dx
    } else {
      origin.x
    }
  } else if dir == dirs.E or dir == dirs.W {
    origin.x + target.dx
  } else if dir == dirs.N or dir == dirs.S {
    origin.x
  } else if dir == dirs.NE or dir == dirs.SW {
    let dx = if target.dx != auto {
      target.dx
    } else if target.dy != auto {
      target.dy
    } else {
      target.y - origin.y
    }
    origin.x + dx
  } else if dir == dirs.SE or dir == dirs.NW {
    let dx = if target.dx != auto {
      target.dx
    } else if target.dy != auto {
      -target.dy
    } else {
      -(target.y - origin.y)
    }
    origin.x + dx
  } else {
    origin.x
  }
  let y = if target.y != auto {
    target.y
  } else if dir == auto {
    if target.dy != auto {
      origin.y + target.dy
    } else {
      origin.y
    }
  } else if dir == dirs.N or dir == dirs.S {
    origin.y + target.dy
  } else if dir == dirs.E or dir == dirs.W {
    origin.y
  } else if dir == dirs.NE or dir == dirs.SW {
    let dy = if target.dy != auto {
      target.dy
    } else if target.dx != auto {
      target.dx
    } else {
      target.x - origin.x
    }
    origin.y + dy
  } else if dir == dirs.SE or dir == dirs.NW {
    let dy = if target.dy != auto {
      target.dy
    } else if target.dx != auto {
      -target.dx
    } else {
      -(target.x - origin.x)
    }
    origin.y + dy
  } else {
    origin.y
  }
  (x, y)
}
