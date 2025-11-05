<?xml version="1.0" encoding="utf-8"?>

<!--

A theme for nginx's autoindex module for directory listings. Directly based on
a few other projects:

https://gist.github.com/wilhelmy/5a59b8eea26974a468c9/00c657fec00da06c14f92a58f4ecffa123a41ae4
A lot of code was taken directly from here, the license of that project is
replicated below. This and its fork also were my starting point for learning
XSLT.

https://github.com/jbox-web/nginx-index-template/blob/01243a08a9feb6f355e95f7c74d9cad1b5b921b4/nginx_template.xslt
This is a fork of dirlist.xslt, the "breadcrumbs" template was taken from there
and rewritten.

https://github.com/linuxmint/mint-themes/blob/08ac147633d436c92d412e27d3ea375f1347dfe8/src/Mint-Y/gtk-3.0/sass/_common.scss
The look and feel, color palette, and the rest of the CSS styles of the page
are based on the newer Linux Mint theme.


The most basic usage is as follows:

    default_type text/html;
    index index.html;
    root /srv/localhost;

    location / {
      try_files $uri @autoindex;
    }

    location @autoindex {
      autoindex on;
      autoindex_format xml;
      xslt_string_param ngx_scheme $scheme;
      xslt_string_param ngx_host $host;
      xslt_string_param ngx_uri $request_uri;
      xslt_string_param ngx_path $uri;
      xslt_stylesheet nginx_autoindex_theme.xslt;
      xslt_last_modified on;
    }


Here are some other interesting links:

https://github.com/nginx/nginx/blob/828fb94e1dbe1c433edd39147ba085c4622c99ed/src/http/modules/ngx_http_autoindex_module.c
The implementation of the autoindex module in nginx.

https://github.com/lighttpd/lighttpd2/blob/29e57d3005c77c7abfa0f60568dcb59fef2aa031/src/modules/mod_dirlist.c
The implementation of directory indexes in lighttpd. Actually, I wish nginx's
module had at least the features of this one, it's pretty tiny and yet rather
nice.

https://github.com/caddyserver/caddy/blob/e81369e2208e47d9650f9699ad8bc7692640b275/modules/caddyhttp/fileserver/browse.html
The implementation of directory listings in the caddy web server. Inarguably,
the most stylish one of the three.

https://github.com/aperezdc/ngx-fancyindex
Definitely fancier than the default autoindex module of nginx, but, honestly,
looks outdated.

https://github.com/y2361547758/autoIndexBaidu
https://github.com/gibatronic/ngx-superbindex
https://github.com/fulicat/autoindex
https://github.com/lfelipe1501/Nginxy
https://github.com/Naereen/Nginx-Fancyindex-Theme
https://github.com/nervo/nginx-indexer
https://github.com/manala/nginx-autoindex-theme
A few more themes.

https://github.com/lrsjng/h5ai
This one has a lot of bells and whistles, but isn't really a theme, rather a
full-fledged PHP application.

https://www.w3.org/TR/xslt-10/#stylesheet-element
https://www.w3.org/TR/1999/REC-xpath-19991116/
Specifications of XSLT 1.0 and XPath 1.0 (respectively). Note that libxslt,
which nginx's XSLT templating module uses, supports just these two (most basic)
features, plus the EXSLT extensions.

-->

<!--
The license of dirlist.xslt

Copyright (c) 2016 by Moritz Wilhelmy <mw@barfooze.de>
All rights reserved

Redistribution and use in source and binary forms, with or without
modification, are permitted providing that the following conditions
are met:
1. Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
2. Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-->

<xsl:stylesheet
  version="1.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:str="http://exslt.org/strings"
  extension-element-prefixes="str">
  <xsl:output method="html" doctype-system="about:legacy-compat" indent="no" />

  <xsl:param name="ngx_scheme" />
  <xsl:param name="ngx_host" />
  <xsl:param name="ngx_uri" />
  <xsl:param name="ngx_path" />
  <xsl:param name="site_name" select="$ngx_host" />
  <xsl:param name="favicon" />
  <xsl:param name="og_meta" select="true()" />
  <xsl:param name="og_url" />
  <xsl:param name="og_site_name" />
  <xsl:param name="og_title" />
  <xsl:param name="og_description" />
  <xsl:param name="og_image" />
  <xsl:param name="redirect_to_https_in_browsers" select="false()" />

  <xsl:template match="/">
    <html>
      <head>
        <meta charset="utf-8" />

        <xsl:if test="$redirect_to_https_in_browsers">
          <script type="text/javascript"><![CDATA[if(location.protocol==='http:')location.protocol='https:']]></script>
        </xsl:if>

        <meta name="viewport" content="width=device-width, initial-scale=1.0" />

        <xsl:variable name="title">Index of <xsl:value-of select="$ngx_path" /></xsl:variable>
        <title><xsl:value-of select="$title" /> - <xsl:value-of select="$site_name" /></title>

        <xsl:if test="$og_meta">
          <meta property="og:type" content="website" />
          <xsl:if test="og_url"><meta property="og:url" content="{$og_url}" /></xsl:if>
          <xsl:if test="not($og_url)"><meta property="og:url" content="{$ngx_scheme}://{$ngx_host}{$ngx_uri}" /></xsl:if>
          <xsl:if test="$og_site_name"><meta property="og:site_name" content="{$og_site_name}" /></xsl:if>
          <xsl:if test="not($og_site_name)"><meta property="og:site_name" content="{$site_name}" /></xsl:if>
          <xsl:if test="$og_title"><meta property="og:title" content="{$og_title}" /></xsl:if>
          <xsl:if test="not($og_title)"><meta property="og:title" content="{$title}" /></xsl:if>
          <xsl:if test="$og_description"><meta property="og:description" content="{$og_description}" /></xsl:if>
          <xsl:if test="$og_image"><meta property="og:image" content="{$og_image}" /></xsl:if>
        </xsl:if>

        <xsl:if test="$favicon">
          <link rel="icon" href="{$favicon}" />
        </xsl:if>

        <meta property="theme-color" content="#2b2b2b" />

<style type="text/css"><!-- include styles.css start -->
  <xsl:text>*{box-sizing:border-box}body{background:#383838;color:#dadada;font-family:monospace;line-height:1.2;margin:8px}a{color:#7eafe9;text-decoration:none}a:active,a:focus,a:hover{color:#d1c5e9;</xsl:text>
  <xsl:text>text-decoration:underline}a:active{color:#e6bdbc}svg.icon{height:1em;width:1em;fill:currentColor;vertical-align:-.125em}.main,.nav{border:1px solid #292929;margin:8px auto;max-width:900px;overflow:</xsl:text>
  <xsl:text>auto}.nav{background:#404040;padding:6px 12px}.nav&gt;*{display:inline-block;margin-right:3px}table{border-spacing:0;width:100%}tr&gt;*{background:#404040;border:1px #292929;border-style:none none solid}</xsl:text>
  <xsl:text>table&gt;:last-child&gt;tr:last-child&gt;*{border-bottom-style:none}thead&gt;tr&gt;*{background:#353535;border-right-style:solid}table&gt;*&gt;tr&gt;:last-child{border-right-style:none}tfoot&gt;tr&gt;*{background:#383838}tbody&gt;tr:</xsl:text>
  <xsl:text>focus-within&gt;*,tbody&gt;tr:hover&gt;*{background:#4c4c4c}tr&gt;*{text-align:left;white-space:nowrap}th{font-weight:700}th.sort&gt;a,tr&gt;*{padding:4px 12px}th.sort{padding:0}th.sort&gt;a{color:unset;cursor:pointer;</xsl:text>
  <xsl:text>display:block;text-decoration:unset}th.sort&gt;a:active,th.sort&gt;a:focus,th.sort&gt;a:hover{background:#3d3d3d}th&gt;svg.icon{height:.75em;width:.75em}tr&gt;[data-col=icon]{padding-right:0;width:1em}tr&gt;[data-col=</xsl:text>
  <xsl:text>icon]+*{padding-left:6px}tr&gt;[data-col=name]{width:100%}.nav,td[data-col=name]{white-space:pre}td[data-col=size]{text-align:right}@media (prefers-color-scheme:light){body{background:#f5f5f5;color:</xsl:text>
  <xsl:text>#303030}a{color:#5294e2}a:active,a:focus,a:hover{color:#8c6ec9}a:active{color:#c15b58}.nav{border-color:#bababa}.main,tr&gt;*{border-color:#c7c7c7}.nav,tr&gt;*{background:#fff}tfoot&gt;tr&gt;*,thead&gt;tr&gt;*{</xsl:text>
  <xsl:text>background:#f5f5f5}tbody&gt;tr:focus-within&gt;*,tbody&gt;tr:hover&gt;*{background:#f5f5f5}th.sort&gt;a:active,th.sort&gt;a:focus,th.sort&gt;a:hover{background:#fafafa}}</xsl:text>
<!-- include styles.css end --></style>

      </head>
      <body>

        <div class="nav">
          <xsl:call-template name="breadcrumbs"><xsl:with-param name="full_path" select="$ngx_path" /></xsl:call-template>
        </div>

        <div class="main">
          <table summary="Directory Listing">

            <thead>
              <tr>
                <th data-col="name" colspan="2">
                  <xsl:text>Name </xsl:text>
                  <svg class="icon"><use href="#icon-none" /></svg>
                </th>
                <th data-col="size">
                  <xsl:text>Size </xsl:text>
                  <svg class="icon"><use href="#icon-none" /></svg>
                </th>
                <th data-col="mtime">
                  <xsl:text>Last Modified </xsl:text>
                  <svg class="icon"><use href="#icon-none" /></svg>
                </th>
              </tr>
            </thead>

            <tbody>
              <xsl:if test="$ngx_path != '' and $ngx_path != '/'">
                <tr class="parent dir">
                  <td data-col="icon">
                    <svg class="icon"><use href="#icon-parent" /></svg>
                  </td>
                  <td data-col="name"><a href="../">..</a>/</td>
                  <td data-col="size">-</td>
                  <td data-col="mtime">-</td>
                </tr>
              </xsl:if>
            </tbody>

            <tbody>
              <xsl:for-each select="list/*">
                <xsl:call-template name="file" />
              </xsl:for-each>
            </tbody>

            <tfoot>
              <tr>
                <td colspan="4">
                  <b><xsl:value-of select="count(list/directory)" /></b>
                  <xsl:text> directories, </xsl:text>
                  <b><xsl:value-of select="count(list/*) - count(list/directory)" /></b>
                  <xsl:text> files, </xsl:text>
                  <b><xsl:call-template name="size"><xsl:with-param name="bytes" select="sum(list/*/@size)" /></xsl:call-template></b>
                  <xsl:text> total</xsl:text>
                </td>
              </tr>
            </tfoot>

          </table>
        </div>

        <svg width="0" height="0" style="display: none">
          <defs>
            <symbol id="icon-none" viewBox="0 0 16 16"></symbol>
            <!-- <https://icons.getbootstrap.com/icons/file-earmark-text/> -->
            <symbol id="icon-file" viewBox="0 0 16 16">
              <path d="M5.5 7a.5.5 0 0 0 0 1h5a.5.5 0 0 0 0-1h-5zM5 9.5a.5.5 0 0 1 .5-.5h5a.5.5 0 0 1 0 1h-5a.5.5 0 0 1-.5-.5zm0 2a.5.5 0 0 1 .5-.5h2a.5.5 0 0 1 0 1h-2a.5.5 0 0 1-.5-.5z"/>
              <path d="M9.5 0H4a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h8a2 2 0 0 0 2-2V4.5L9.5 0zm0 1v2A1.5 1.5 0 0 0 11 4.5h2V14a1 1 0 0 1-1 1H4a1 1 0 0 1-1-1V2a1 1 0 0 1 1-1h5.5z"/>
            </symbol>
            <!-- <https://icons.getbootstrap.com/icons/folder2/> -->
            <symbol id="icon-dir" viewBox="0 0 16 16">
              <path d="M1 3.5A1.5 1.5 0 0 1 2.5 2h2.764c.958 0 1.76.56 2.311 1.184C7.985 3.648 8.48 4 9 4h4.5A1.5 1.5 0 0 1 15 5.5v7a1.5 1.5 0 0 1-1.5 1.5h-11A1.5 1.5 0 0 1 1 12.5v-9zM2.5 3a.5.5 0 0 0-.5.5V6h12v-.5a.5.5 0 0 0-.5-.5H9c-.964 0-1.71-.629-2.174-1.154C6.374 3.334 5.82 3 5.264 3H2.5zM14 7H2v5.5a.5.5 0 0 0 .5.5h11a.5.5 0 0 0 .5-.5V7z"/>
            </symbol>
            <!-- <https://icons.getbootstrap.com/icons/file-earmark/> -->
            <symbol id="icon-other" viewBox="0 0 16 16">
              <path d="M14 4.5V14a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V2a2 2 0 0 1 2-2h5.5L14 4.5zm-3 0A1.5 1.5 0 0 1 9.5 3V1H4a1 1 0 0 0-1 1v12a1 1 0 0 0 1 1h8a1 1 0 0 0 1-1V4.5h-2z"/>
            </symbol>
            <!-- <https://icons.getbootstrap.com/icons/arrow-90deg-up/> -->
            <symbol id="icon-parent" viewBox="0 0 16 16">
              <path fill-rule="evenodd" d="M4.854 1.146a.5.5 0 0 0-.708 0l-4 4a.5.5 0 1 0 .708.708L4 2.707V12.5A2.5 2.5 0 0 0 6.5 15h8a.5.5 0 0 0 0-1h-8A1.5 1.5 0 0 1 5 12.5V2.707l3.146 3.147a.5.5 0 1 0 .708-.708l-4-4z"/>
            </symbol>
              <!-- <https://icons.getbootstrap.com/icons/caret-down-fill/> -->
            <symbol id="icon-sort-asc" viewBox="0 0 16 16">
              <path d="M7.247 11.14 2.451 5.658C1.885 5.013 2.345 4 3.204 4h9.592a1 1 0 0 1 .753 1.659l-4.796 5.48a1 1 0 0 1-1.506 0z"/>
            </symbol>
            <!-- <https://icons.getbootstrap.com/icons/caret-up-fill/> -->
            <symbol id="icon-sort-dsc" viewBox="0 0 16 16">
              <path d="m7.247 4.86-4.796 5.481c-.566.647-.106 1.659.753 1.659h9.592a1 1 0 0 0 .753-1.659l-4.796-5.48a1 1 0 0 0-1.506 0z"/>
            </symbol>
          </defs>
        </svg>

<script type="text/javascript"><!-- include script.js start -->
  <xsl:text>(()=&gt;{"use strict";for(let table of document.getElementsByTagName("table")){for(let td of table.getElementsByTagName("td")){let data=td.dataset;if("mtime"===data.col&amp;&amp;null!=data.val){let date=new Date</xsl:text>
  <xsl:text>(data.val||td.innerText);if(isNaN(date))delete data.val;else{data.val=date.getTime();let x="2-digit";td.innerText=date.toLocaleString([],{year:x,month:x,day:x,hour:x,minute:x,second:x})}}}let tBody=</xsl:text>
  <xsl:text>table.tBodies[1],tRows=Array.from(tBody.rows),tHeaders=table.tHead.getElementsByTagName("th"),createSorterFn=(sortCol,sortDir)=&gt;{let findCol=tr=&gt;{for(let td of tr.getElementsByTagName("td"))if(td.</xsl:text>
  <xsl:text>dataset.col===sortCol)return td;return null},compare=(a,b)=&gt;a&gt;b?1:a&lt;b?-1:0,getValue=_td=&gt;null,nan2null=x=&gt;isNaN(x)?null:x;return"name"===sortCol?(getValue=td=&gt;td.innerText,compare="undefined"!=typeof </xsl:text>
  <xsl:text>Intl?new Intl.Collator(void 0,{numeric:!0}).compare:(a,b)=&gt;a.localeCompare(b)):("size"===sortCol||"mtime"===sortCol)&amp;&amp;(getValue=td=&gt;nan2null(parseInt(td.dataset.val,10))),(a,b)=&gt;compare(getValue(</xsl:text>
  <xsl:text>findCol(a)),getValue(findCol(b)))*sortDir},updateSortIcons=(clickedTh,sortDir)=&gt;{for(let th of tHeaders){let sortDirStr="none",icon="none";th===clickedTh&amp;&amp;(sortDirStr=sortDir&gt;0?"asc":sortDir&lt;0?"dsc":"</xsl:text>
  <xsl:text>none",icon="sort-"+sortDirStr),th.dataset.sortDir=sortDirStr;for(let svgUse of th.querySelectorAll("svg.icon &gt; use"))svgUse.setAttribute("href","#icon-"+icon)}};for(let th of tHeaders){th.classList.</xsl:text>
  <xsl:text>add("sort");let thBtn=document.createElement("a");thBtn.href="#";for(let child of Array.from(th.childNodes))thBtn.appendChild(child);th.appendChild(thBtn),thBtn.addEventListener("click",(event=&gt;{let </xsl:text>
  <xsl:text>newSortDir;event.preventDefault(),newSortDir="asc"===th.dataset.sortDir?-1:"dsc"===th.dataset.sortDir?0:1,updateSortIcons(th,newSortDir);let newRows=tRows.slice();0!==newSortDir&amp;&amp;newRows.sort(</xsl:text>
  <xsl:text>createSorterFn(th.dataset.col,newSortDir));for(let tr of newRows)tBody.appendChild(tr)}))}}window.addEventListener("keydown",(event=&gt;{if(!(event.shiftKey||event.altKey||event.ctrlKey||event.metaKey)){</xsl:text>
  <xsl:text>let dir;switch(event.code){case"ArrowUp":case"KeyK":dir=-1;break;case"ArrowDown":case"KeyJ":dir=1;break;default:return}event.preventDefault();let focusable=Array.from(document.querySelectorAll("tbody </xsl:text>
  <xsl:text>a")),current=focusable.indexOf(document.activeElement);if(current&lt;0)(dir&gt;0?focusable[0]:focusable[focusable.length-1]).focus();else{let elem=focusable[current+dir];elem&amp;&amp;elem.focus()}}}))})();</xsl:text>
<!-- include script.js end --></script>

      </body>
    </html>
  </xsl:template>

  <xsl:template name="file">
    <xsl:variable name="icon">
      <xsl:choose>
        <xsl:when test="self::directory">dir</xsl:when>
        <xsl:when test="self::file">file</xsl:when>
        <xsl:when test="self::other">other</xsl:when>
      </xsl:choose>
    </xsl:variable>
    <tr class="{$icon}">
      <td data-col="icon">
        <svg class="icon"><use href="#icon-{$icon}" /></svg>
      </td>
      <td data-col="name">
        <xsl:variable name="slash">
          <xsl:if test="self::directory">/</xsl:if>
        </xsl:variable>
        <a href="{str:encode-uri(current(), true())}{$slash}"><xsl:value-of select="current()" /></a><xsl:value-of select="$slash" />
      </td>
      <td data-col="size">
        <xsl:choose>
          <xsl:when test="@size">
            <xsl:attribute name="data-val"><xsl:value-of select="@size" /></xsl:attribute>
            <xsl:call-template name="size"><xsl:with-param name="bytes" select="@size" /></xsl:call-template>
          </xsl:when>
          <xsl:otherwise>-</xsl:otherwise>
        </xsl:choose>
      </td>
      <td data-col="mtime">
        <xsl:choose>
          <xsl:when test="@mtime">
            <xsl:attribute name="data-val" />
            <xsl:value-of select="@mtime" />
          </xsl:when>
          <xsl:otherwise>-</xsl:otherwise>
        </xsl:choose>
      </td>
    </tr>
  </xsl:template>

  <xsl:template name="size">
    <xsl:param name="bytes" />
    <xsl:choose>
      <xsl:when test="$bytes &lt; 1024"><xsl:value-of select="format-number($bytes, '0')" />B</xsl:when>
      <xsl:when test="$bytes &lt; 1024 * 1024"><xsl:value-of select="format-number($bytes div 1024, '0.00')" />K</xsl:when>
      <xsl:when test="$bytes &lt; 1024 * 1024 * 1024"><xsl:value-of select="format-number($bytes div 1024 div 1024, '0.00')" />M</xsl:when>
      <xsl:otherwise><xsl:value-of select="format-number($bytes div 1024 div 1024 div 1024, '0.00')" />G</xsl:otherwise>
    </xsl:choose>
  </xsl:template>

  <xsl:template name="breadcrumbs">
    <xsl:param name="full_path" />
    <xsl:param name="separator" select="'/'"  />
    <xsl:param name="consumed_path" select="''" />

    <xsl:variable name="remaining_path" select="substring-after($full_path, $consumed_path)" />
    <xsl:variable name="has_more_components" select="contains($remaining_path, $separator)" />
    <xsl:variable name="current_component">
      <xsl:choose>
        <xsl:when test="$has_more_components"><xsl:value-of select="substring-before($remaining_path, $separator)" /></xsl:when>
        <xsl:otherwise><xsl:value-of select="$remaining_path" /></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <xsl:variable name="current_path">
      <xsl:choose>
        <xsl:when test="$has_more_components"><xsl:value-of select="concat($consumed_path, $current_component, $separator)" /></xsl:when>
        <xsl:otherwise><xsl:value-of select="concat($consumed_path, $current_component)" /></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>

    <xsl:variable name="link_text">
      <xsl:choose>
        <xsl:when test="$current_path = '/'"><xsl:value-of select="$site_name" /></xsl:when>
        <xsl:otherwise><xsl:value-of select="$current_component" /></xsl:otherwise>
      </xsl:choose>
    </xsl:variable>
    <a href="{str:encode-uri($current_path, false())}"><xsl:value-of select="$link_text" /></a><span>/</span>

    <xsl:if test="$current_path != $full_path">
      <xsl:call-template name="breadcrumbs">
        <xsl:with-param name="full_path" select="$full_path" />
        <xsl:with-param name="separator" select="$separator" />
        <xsl:with-param name="consumed_path" select="$current_path" />
      </xsl:call-template>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
