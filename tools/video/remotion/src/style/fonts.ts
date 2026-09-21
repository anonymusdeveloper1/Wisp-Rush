import { loadFont as loadAnton } from "@remotion/google-fonts/Anton";
import { loadFont as loadPoppins } from "@remotion/google-fonts/Poppins";
import { loadFont as loadMarker } from "@remotion/google-fonts/PermanentMarker";

/**
 * Three faces, no more — the devlog's whole typographic voice (recipe §6.5).
 * Anton headlines, Poppins-Bold labels and captions, Permanent Marker handwritten notes.
 * These are the same families Palmier bundled, so the type identity survives the move to Remotion.
 */
const anton = loadAnton();
const poppins = loadPoppins("normal", { weights: ["600", "700"] });
const marker = loadMarker();

export const F = {
  display: anton.fontFamily,
  bold: poppins.fontFamily,
  marker: marker.fontFamily,
} as const;

export const fontsReady = Promise.all([
  anton.waitUntilDone(),
  poppins.waitUntilDone(),
  marker.waitUntilDone(),
]);
