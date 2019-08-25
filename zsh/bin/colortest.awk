#!/usr/bin/awk -f

BEGIN {
  print "";
  test_standard_colors();
  print "";
  test_base16_colorscheme();
  print "";
  test_6x6x6_cube();
  print "";
  test_grayscale();
  print "";
  test_true_color();
  print "";
}

function print_color(color) {
  printf "\033[48;5;%sm  \033[0m", color
}

function test_standard_colors() {
  print "16 standard colors:";
  for (color = 0; color < 16; color += 1) print_color(color);
  print "";
}

function test_base16_colorscheme() {
  print "base16 colorscheme:";
  split("0 18 19 8 20 7 21 15 1 16 3 2 6 4 5 17", colors, " ");
  for (i = 1; i <= length(colors); i++) print_color(colors[i]);
  print "";
}

function test_6x6x6_cube() {
  print "6x6x6 cube (216 colors):";
  block_grid_w = 3;
  block_grid_h = 2;
  for (block_y = 0; block_y < block_grid_h; block_y++) {
    for (row = 0; row < 6; row++) {
      for (block_x = 0; block_x < block_grid_w; block_x++) {
        for (col = 0; col < 6; col++) {
          print_color(16 + col + 6*row + 6*6*block_x + block_grid_w*6*6*block_y);
        }
      }
      print "";
    }
  }
}

function test_grayscale() {
  print "grayscale from black to white in 24 steps:";
  for (color = 0; color < 24; color += 1) {
    print_color(16 + 6*6*6 + color)
  }
  print "";
}

function test_true_color() {
  print "24-bit true color test:"
  colors_count = 360;
  for (h = 0; h < colors_count; h++) {
    hsv_to_rgb(h / colors_count, 1, 1, rgb);
    for (i = 0; i < 3; i++) rgb[i] = int(rgb[i] * 255);
    r = rgb[0];
    g = rgb[1];
    b = rgb[2];
    printf "\033[48;2;%d;%d;%dm", r,g,b;
    printf " \033[0m";
  }
  print "";
}

function hsv_to_rgb(h, s, v, rgb) {
  if (s == 0) {
    rgb[0] = rgb[1] = rgb[2] = v;
  } else {
    h *= 6;
    i = int(h);
    f = h - i;
    p = v * (1 - s);
    q = v * (1 - s * f);
    t = v * (1 - s * (1 - f));

    if (i == 0) {
      rgb[0] = v;
      rgb[1] = t;
      rgb[2] = p;
    } else if (i == 1) {
      rgb[0] = q;
      rgb[1] = v;
      rgb[2] = p;
    } else if (i == 2) {
      rgb[0] = p;
      rgb[1] = v;
      rgb[2] = t;
    } else if (i == 3) {
      rgb[0] = p;
      rgb[1] = q;
      rgb[2] = v;
    } else if (i == 4) {
      rgb[0] = t;
      rgb[1] = p;
      rgb[2] = v;
    } else if (i == 5) {
      rgb[0] = v;
      rgb[1] = p;
      rgb[2] = q;
    }
  }
}
