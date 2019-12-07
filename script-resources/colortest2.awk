#!/usr/bin/awk -f

BEGIN {
  pi = atan2(0, -1);
  test_true_color();
}

function test_true_color() {
  for (y = 0; y < HEIGHT; y++) {
    for (x = 0; x < WIDTH; x++) {
      angle = pi - atan2(x + 0.5 - WIDTH/2, y + 0.5 - HEIGHT/2);
      hsv2rgb(angle / (2*pi), 1, 1, rgb);

      for (i = 0; i < 3; i++) rgb[i] = int(rgb[i] * 255);
      r = rgb[0];
      g = rgb[1];
      b = rgb[2];
      printf "\033[48;2;%d;%d;%dm", r,g,b;
      printf "  \033[0m";
    }
    print "";
  }
}

function hsv2rgb(h, s, v, rgb) {
  if (s == 0) {
    r = g = b = v;
  } else {
    h *= 6;
    i = int(h);
    f = h - i;
    p = v * (1 - s);
    q = v * (1 - s * f);
    t = v * (1 - s * (1 - f));
    if (i == 0) {
      r = v; g = t; b = p;
    } else if (i == 1) {
      r = q; g = v; b = p;
    } else if (i == 2) {
      r = p; g = v; b = t;
    } else if (i == 3) {
      r = p; g = q; b = v;
    } else if (i == 4) {
      r = t; g = p; b = v;
    } else if (i == 5) {
      r = v; g = p; b = q;
    }
  }
  rgb[0] = r; rgb[1] = g; rgb[2] = b;
}
