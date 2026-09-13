/// Placeholder backdrop: everything beyond the porch.
///
/// Flat blocks standing in for the painted scene. It exists so the rain can be
/// judged against a horizon and a ground plane — rain over an empty black room
/// tells you nothing about whether the perspective is right.
///
/// Depth has to stay below 100: the room's Background layer sits at depth 100
/// and paints opaque black, so anything further back than it is invisible.
depth = 60;

// Uniform handles for the lake, the sky and the bank, looked up once.
water_init();
sky_init();
grass_init();

// The stand of trees, as a table of positions rather than as instances.
trees_init();

// And the rocks, the same way.
rocks_init();

// The few flowers in the bank grass. The dock needs no init — it is derived
// entirely from its macros and the live projection.
flowers_init();

// The birds, the duck and the fireflies. Initialised here because two of the
// three are drawn from this object's Draw event, between the layers they
// belong between — see scr_wildlife.
wildlife_init();
