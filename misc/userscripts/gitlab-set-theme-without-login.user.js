// ==UserScript==
// @name        GitLab set theme without login
// @description DOES NOT WORK
// @version     1
// @grant       none
// @match       https://gitlab.com/*
// @match       https://salsa.debian.org/*
// @run-at      document-start
// ==/UserScript==

(() => {
  'use strict';

  for (let $link of document.getElementsByTagName('link')) {
    if (!($link.as === 'style' || $link.rel === 'stylesheet')) continue;

    let pattern = /^(https:\/\/assets\.gitlab-static\.net\/assets\/)(.+)(-[0-9a-fA-F]{64}\.css)$/;
    let matches = $link.href.match(pattern);
    if (matches == null) continue;
    let [hrefBefore, assetPath, hrefAfter] = matches.slice(1);
    let newAssetPath = null;

    if (assetPath === 'application' || assetPath === 'application_utilities') {
      newAssetPath = `${assetPath}_dark`;
    } else if (assetPath === 'highlight/themes/white') {
      newAssetPath = 'highlight/themes/dark';
    }

    if (newAssetPath == null) continue;
    $link.href = `${hrefBefore}${newAssetPath}${hrefAfter}`;
  }

  document.body.classList.remove('ui-indigo');
  document.body.classList.add('gl-dark');
})();
