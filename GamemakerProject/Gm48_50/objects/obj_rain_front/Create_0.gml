/// The rain that lands on the porch itself.
///
/// Split out from obj_rain purely for draw order: water striking the top of the
/// railing has to be drawn after the railing, or the railing covers it. Sitting
/// in front of obj_porch (-100) is the whole reason this object exists.
depth = -110;
