// ==UserScript==
// @name     YouTube screenshotter
// @version  1
// @grant    none
// @match    https://www.youtube.com/*
// @run-at   document-end
// ==/UserScript==

(() => {
  'use strict';

  function main() {
    window.__userscript__takeScreenshot = function (video, imageType = 'image/png') {
      if (!(video instanceof HTMLVideoElement)) {
        throw new Error('Assertion failed: video instanceof HTMLVideoElement');
      }

      let canvas = document.createElement('canvas');
      canvas.width = video.videoWidth;
      canvas.height = video.videoHeight;
      let ctx = canvas.getContext('2d');
      ctx.drawImage(video, 0, 0, video.videoWidth, video.videoHeight);
      window.open(canvas.toDataURL(imageType), '_blank');
    };
  }

  let script = document.createElement('script');
  script.append('(' + main + ')();');
  (document.body || document.head || document.documentElement).appendChild(script);
})();
