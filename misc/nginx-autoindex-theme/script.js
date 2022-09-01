(() => {
  'use strict';

  for (let table of document.getElementsByTagName('table')) {
    for (let td of table.getElementsByTagName('td')) {
      let data = td.dataset;
      if (data.col === 'mtime' && data.val != null) {
        let date = new Date(data.val || td.innerText);
        if (!isNaN(date)) {
          data.val = date.getTime();
          let x = '2-digit';
          td.innerText = date.toLocaleString([], {
            year: x,
            month: x,
            day: x,
            hour: x,
            minute: x,
            second: x,
          });
        } else {
          delete data.val;
        }
      }
    }

    let tBody = table.tBodies[1];
    let tRows = Array.from(tBody.rows);
    let tHeaders = table.tHead.getElementsByTagName('th');

    let createSorterFn = (sortCol, sortDir) => {
      let findCol = (tr) => {
        for (let td of tr.getElementsByTagName('td')) {
          if (td.dataset.col === sortCol) {
            return td;
          }
        }
        return null;
      };
      let compare = (a, b) => {
        if (a > b) return 1;
        if (a < b) return -1;
        return 0;
      };
      let getValue = (td) => null;
      let nan2null = (x) => (!isNaN(x) ? x : null);

      if (sortCol === 'name') {
        getValue = (td) => td.innerText;
        if (typeof Intl !== 'undefined') {
          compare = new Intl.Collator(undefined, { numeric: true }).compare;
        } else {
          compare = (a, b) => a.localeCompare(b);
        }
      } else if (sortCol === 'size') {
        getValue = (td) => nan2null(parseInt(td.dataset.val, 10));
      } else if (sortCol === 'mtime') {
        getValue = (td) => nan2null(parseInt(td.dataset.val, 10));
      }

      return (a, b) => compare(getValue(findCol(a)), getValue(findCol(b))) * sortDir;
    };

    let updateSortIcons = (clickedTh, sortDir) => {
      for (let th of tHeaders) {
        let sortDirStr = 'none';
        let icon = 'none';
        if (th === clickedTh) {
          sortDirStr = sortDir > 0 ? 'asc' : sortDir < 0 ? 'dsc' : 'none';
          icon = 'sort-' + sortDirStr;
        }
        th.dataset.sortDir = sortDirStr;
        for (let svgUse of th.querySelectorAll('svg.icon > use')) {
          svgUse.setAttribute('href', '#icon-' + icon);
        }
      }
    };

    for (let th of tHeaders) {
      th.classList.add('sort');

      let thBtn = document.createElement('a');
      thBtn.href = '#';
      for (let child of Array.from(th.childNodes)) {
        thBtn.appendChild(child);
      }
      th.appendChild(thBtn);

      thBtn.addEventListener('click', (event) => {
        event.preventDefault();

        let newSortDir;
        if (th.dataset.sortDir === 'asc') {
          newSortDir = -1;
        } else if (th.dataset.sortDir === 'dsc') {
          newSortDir = 0;
        } else {
          newSortDir = 1;
        }
        updateSortIcons(th, newSortDir);

        let newRows = tRows.slice();
        if (newSortDir !== 0) {
          newRows.sort(createSorterFn(th.dataset.col, newSortDir));
        }
        for (let tr of newRows) {
          tBody.appendChild(tr);
        }
      });
    }
  }
})();
