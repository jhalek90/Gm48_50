/// Placeholder backdrop: everything beyond the porch.
///
/// Flat blocks standing in for the painted scene. It exists so the rain can be
/// judged against a horizon and a ground plane — rain over an empty black room
/// tells you nothing about whether the perspective is right.
///
/// Depth has to stay below 100: the room's Background layer sits at depth 100
/// and paints opaque black, so anything further back than it is invisible.
depth = 60;
