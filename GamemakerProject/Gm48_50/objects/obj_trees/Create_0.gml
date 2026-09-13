/// The stand of trees on the near bank.
///
/// Its own object purely for depth. The trees stand inside the rain rather
/// than behind it, and the rain is two particle systems either side of them —
/// far at 55, near at 30 — so the stand has to sit between those two numbers
/// or the whole field draws over it.
///
/// 50 also keeps it after obj_scene at 60, which is where the bank it stands
/// in is drawn. The shadows go here too, for the same reason they always did:
/// they belong on the grass, and the grass is drawn before this.
depth = 50;
