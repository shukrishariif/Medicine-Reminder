# Daryeel branding

- `assets/branding/daryeel-logo.png` is the unchanged supplied logo, including its original typography. `DaryeelLogo` uses `BoxFit.contain` on startup, welcome, login, signup, and recovery screens.
- `assets/branding/daryeel-symbol.png` is the text-free launcher derivative. Android density-specific launcher PNGs and the adaptive icon use this symbol. The full source logo remains unchanged.
- The Flutter startup logo fades in once and respects reduced-motion settings. Android 12+ uses the symbol for its system splash, following Android's system splash constraints; earlier Android versions show the full logo.
- Existing notification artwork remains separate from the launcher icon.

The symbol was prepared with the built-in imagegen tool. Final prompt: “Produce a square Android launcher icon by extracting only the ORIGINAL heart/capsule/hand/bell symbol from this image. Keep the existing design, shape, color gradients and white capsule half intact. Remove the text below it entirely. Place the complete unchanged symbol centered on a pure solid white background. No transparency, no holes in the artwork, no speckles, no added effects, no typography. Keep a generous 20% margin on all sides for launcher masking. This is a precise extraction and placement, not a logo redesign.”

Android references: https://developer.android.com/develop/ui/views/launch/splash-screen and https://developer.android.com/develop/ui/compose/system/icon_design_adaptive
