// hica GUI Theme -- generated for EBI (Stillness Dark with Nordic Blue)
// Usage:
//   1. Copy this file into your project
//   2. Adjust the import path below
//   3. Call apply_theme() at the TOP of your gui_window callback

import "imgui"

pub fun apply_theme() {
  // Ultra-crisp typography against dark backgrounds
  gui_set_color_text(0.9333, 0.9411, 0.9529)       // Soft off-white (#EEF0F3)
  
  // Minimalist, low-sensory slate backdrop
  gui_set_color_bg(0.0941, 0.1098, 0.1451)         // Deep slate (#181C25)
  gui_set_color_surface(0.1411, 0.1608, 0.2039)    // Elevated panels (#242934)
  gui_set_color_border(0.2196, 0.2471, 0.3020)     // Low-contrast borders (#383F4D)
  
  // Intentional visual focus signals
  gui_set_color_accent(0.2314, 0.5098, 0.9647)     // Nordic Blue accent (#3B82F6)
  gui_set_color_plot(0.0588, 0.7098, 0.6549)       // Healthy Green for stable trunk (#0FB5A7)
  gui_set_color_plot_bar(0.9373, 0.3255, 0.3137)   // Soft Crimson for conflicts/hotspots (#EF5350)
  
  // Ambient overlay for modal prompts (like blocking CI pre-flights)
  gui_set_color_modal_dim(0.45)
  
  // Compact, professional desktop geometry
  gui_set_style_rounding(4.0, 4.0, 4.0)            // Subtle, sharp radii for layout precision
  gui_set_style_padding(8.0, 4.0)                  // Tightened widget elements for high information density
  gui_set_style_window_padding(12.0, 12.0)         // Balanced viewport margins
  gui_set_style_spacing(8.0, 6.0, 16.0)            // Intentional layout rhythm
  gui_set_style_borders(1.0, 1.0)                  // Crisp alignment outlines enabled across panels
}

// One Dark Pro
// Colors sourced directly from github.com/Binaryify/OneDark-Pro
pub fun apply_one_dark_theme() {
  gui_set_color_text(0.843, 0.855, 0.878)           // #d7dae0  activityBar.foreground / list active text
  gui_set_color_bg(0.157, 0.173, 0.204)             // #282c34  editor.background
  gui_set_color_surface(0.114, 0.122, 0.137)        // #1d1f23  input.background
  gui_set_color_border(0.243, 0.267, 0.322)         // #3e4452  panel.border
  gui_set_color_accent(0.302, 0.471, 0.800)         // #4d78cc  activityBarBadge / remoteBackground
  gui_set_color_plot(0.596, 0.765, 0.475)           // #98c379  string green — healthy trunk
  gui_set_color_plot_bar(0.878, 0.424, 0.459)       // #e06c75  deleted / error red
  gui_set_color_modal_dim(0.50)
  gui_set_style_rounding(6.0, 4.0, 4.0)
  gui_set_style_padding(6.0, 4.0)
  gui_set_style_window_padding(12.0, 12.0)
  gui_set_style_spacing(8.0, 6.0, 16.0)
  gui_set_style_borders(1.0, 1.0)
}