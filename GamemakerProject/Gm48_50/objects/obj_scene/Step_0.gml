/// The things that live here, advanced.
///
/// In a Step rather than inside the Draw that puts them on screen, because
/// birds and the duck are drawn from two different points in that event and
/// neither should be the one that decides how far they have moved. The same
/// split the sequencer and the daylight use: the clock runs once, and drawing
/// only ever reads it.
wildlife_step();
