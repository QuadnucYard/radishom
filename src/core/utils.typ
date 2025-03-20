/// Utility functions.


#let lerp(a, b, r) = {
  a + (b - a) * r
}

/// Creates an array from the given input.
///
/// Returns:
/// - If input is none: empty array
/// - If input is array: same array
/// - Otherwise: single-element array containing the input
///
/// *Example:*
/// ```example
/// #make-array(none)   // returns ()
/// #make-array((1,2))  // returns (1,2)
/// #make-array(1)      // returns (1,)
/// ```
///
/// - a (any): Any value or array
/// -> array
#let make-array(a) = {
  if a == none { () } else if type(a) == array { a } else { (a,) }
}

/// Returns the index of the minimum element in an array, or -1 if the sequence is empty.
///
/// *Example:*
/// ```example
/// #min-index((3, 1, 4, 1, 5)) // Returns 1
/// #min-index(()) // Returns -1
/// ```
///
/// - a (array): An array of comparable elements.
/// -> int
#let min-index(a) = {
  if a.len() == 0 {
    return -1
  }
  let k = 0
  for (i, x) in a.enumerate() {
    if x < a.at(k) {
      k = i
    }
  }
  return k
}

/// Returns an array of elements that appear exactly once in the input array.
/// The elements in the result are sorted in ascending order.
///
/// *Example:*
/// ```example
/// #pick-once-elements((1,2,2,3,3,3,4)) // Returns (1,4)
/// ```
///
/// - a (array): An array of comparable elements.
/// -> array
#let pick-once-elements(a) = {
  a = a.sorted()
  let res = ()
  let len = a.len()
  let i = 0
  while i < len {
    let j = i
    while j < len and a.at(j) == a.at(i) {
      j += 1
    }
    if j == i + 1 {
      res.push(a.at(i))
    }
    i = j
  }
  return res
}

/// Get a suitable rotation of the transfer marker for the given station.
/// Returns the preferred angle for labeling based on given angles.
///
/// Priority order:
/// 1. For parallel lines: perpendicular to the common angle (angle + 90°)
/// 2. Horizontal (0°) if present among normalized angles
/// 3. Vertical (90°) if present among normalized angles
/// 4. Direction of first line as fallback
///
/// All input angles are first normalized to range (-90°, 90°\] by adding
/// or subtracting 180° as needed.
///
/// *Example:*
/// ```example
/// #get-preferred-angle((45deg, 45deg))    // Returns 135deg (perpendicular)
/// #get-preferred-angle((0deg, 45deg))     // Returns 0deg (horizontal preferred)
/// #get-preferred-angle((90deg, 45deg))    // Returns 90deg (vertical when no horizontal)
/// #get-preferred-angle((30deg, 60deg))    // Returns 30deg (fallback to first)
/// ```
///
/// - angles (array): Array of angles.
/// -> angle
#let get-preferred-angle(angles) = {
  let angles = for angle in angles {
    if angle <= -90deg { angle += 180deg }
    if angle > 90deg { angle -= 180deg }
    (angle,)
  }
  return if angles.dedup().len() == 1 {
    // parallel case
    angles.at(0) + 90deg
  } else if angles.contains(0deg) {
    // prefer horizontal
    0deg
  } else if angles.contains(90deg) {
    90deg
  } else {
    // along the direction of the first line
    angles.at(0)
  }
}
