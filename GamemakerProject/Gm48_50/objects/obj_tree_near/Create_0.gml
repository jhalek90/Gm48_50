/// The one tree that stands in front of the weather.
///
/// Its z is nearer than z_near, and the rain field starts at z_near — so there
/// is no drop in the scene between this tree and the viewer, and every one of
/// them belongs behind it. Drawn with the rest of the stand it had the whole
/// field falling over it, which is what gave the trick away.
///
/// 25 puts it in front of the near rain at 30 and still behind the porch at
/// -100, so the porch post still cuts across it the way it always did.
depth = 25;
