"""Generate the far mountain range for the porch scene.

Authored at the same 4px block size the shaders snap to, then scaled up with
nearest-neighbour, so the ridgeline lands on the scene grid instead of being
sharper than the water and sky it sits between.

The sprite is tonal, not coloured: white down through greys, multiplied by
pal.shore at draw time. Shape comes from here, hour comes from the palette.
"""
import math, random
from PIL import Image

BLOCK = 4
AW, AH = 342, 48            # art pixels -> 1368 x 192 on screen
OCTAVES = 3

# Drawn back to front. The far range is the TALLEST and lightest, the near one
# the lowest and darkest: big hazy peaks standing behind dark low foothills.
# Inverting that puts the heaviest mass in front and the depth disappears.
#
# `sharp` blends between ridged noise and plain noise. At 1.0 every octave is
# folded into a peak and the skyline serrates; at 0.0 it is rolling hills. The
# far layers keep some edge because distance is where actual peaks live, and
# the near layers are rounded, which is what keeps the whole range quiet.
LAYERS = [
    # (seed, peak, roughness, sharp, body tone, ridgeline tone)
    #   roughness = noise cells across the full width, so: how many masses.
    # Seeds and shape picked by search against a prominence metric, not by
    # eye. Prominence is how far a peak stands above the ground either side of
    # it, and it is what makes a skyline read as dramatic rather than restful.
    # The first pass measured mean 9.6 / max 16; this is mean 3.7 / max 9.
    #
    # Seeds matter because each profile is normalised to fill its own height,
    # so a seed whose noise piles up on one side leaves the rest of the
    # skyline flat. These four have the least drift between thirds.
    (165, 0.74, 5.0, 0.55, 252, 255),   # far
    (199, 0.56, 4.0, 0.42, 214, 236),   # mid-far
    (60,  0.40, 3.0, 0.30, 180, 204),   # mid-near
    (25,  0.27, 2.3, 0.18, 146, 172),   # near
]

def make_noise(seed, n=64):
    r = random.Random(seed)
    return [r.random() for _ in range(n)]

def vnoise(x, perm):
    i = math.floor(x); f = x - i
    u = f * f * (3 - 2 * f)
    a = perm[int(i) % len(perm)]
    b = perm[int(i + 1) % len(perm)]
    return a + (b - a) * u

def profile(x, perm, sharp, lac=2.03, gain=0.5):
    v, a, f = 0.0, 0.5, 1.0
    for _ in range(OCTAVES):
        n = vnoise(x * f, perm)
        ridge = 1.0 - abs(2.0 * n - 1.0)
        v += a * (ridge * sharp + n * (1.0 - sharp))
        f *= lac; a *= gain
    return v

img = Image.new("RGBA", (AW, AH), (0, 0, 0, 0))
px = img.load()

for seed, peak, rough, sharp, body, crest in LAYERS:
    perm = make_noise(seed)
    prof = [profile(x / AW * rough, perm, sharp) for x in range(AW)]
    lo, hi = min(prof), max(prof)
    for x in range(AW):
        norm = (prof[x] - lo) / max(hi - lo, 1e-6)
        top = AH - int(round(norm * peak * (AH - 2))) - 1
        for y in range(max(top, 0), AH):
            # Two rows of lighter tone along the ridge reads as light catching
            # the crest; a flat silhouette has no form at all.
            tone = crest if y < top + 2 else body
            px[x, y] = (tone, tone, tone, 255)

out = img.resize((AW * BLOCK, AH * BLOCK), Image.NEAREST)
out.save("spr_mountains.png")
print("wrote spr_mountains.png  %dx%d" % out.size)

# Preview against the real afternoon colours. A tonal sprite on a white page
# tells you nothing about the layer that is near-white.
SKY, SHORE = (168, 180, 196), (120, 132, 148)
prev = Image.new("RGB", out.size, SKY)
pp, op = prev.load(), out.load()
for y in range(out.size[1]):
    for x in range(out.size[0]):
        r, g, b, a = op[x, y]
        if a:
            pp[x, y] = (SHORE[0]*r//255, SHORE[1]*g//255, SHORE[2]*b//255)
prev.save("preview_mountains.png")

tops = []
for seed, peak, rough, sharp, body, crest in LAYERS:
    tops.append("%.0f%%" % (peak * 100))
print("layers far->near, peak height: " + ", ".join(tops))
print("wrote preview_mountains.png (multiplied through pal.shore, on pal.sky_mid)")
