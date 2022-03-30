(() => {
  'use strict';

  for (let table of document.getElementsByTagName('table')) {
    for (let td of table.getElementsByTagName('td')) {
      if (td.dataset.col === 'mtime') {
        let date = new Date(td.textContent);
        if (!isNaN(date)) {
          td.innerText = date.toLocaleString([], {
            year: '2-digit',
            month: '2-digit',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
          });
        }
      }
    }

    let tbody = table.tBodies[0];
    let getTableRows = () => {
      let rows = [];
      for (let tr of tbody.rows) {
        if (!tr.classList.contains('parent')) {
          rows.push(tr);
        }
      }
      return rows;
    };

    getTableRows().forEach((tr, i) => {
      tr.dataset.idx = i;
    });

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

      if (sortDir === 0) {
        getValue = (th) => parseInt(th.dataset.idx, 10);
        return (a, b) => compare(getValue(a), getValue(b));
      }

      if (sortCol === 'name') {
        getValue = (td) => td.innerText;
        compare = (a, b) => a.localeCompare(b);
      } else if (sortCol === 'size') {
        getValue = (td) => {
          let val = parseInt(td.dataset.val, 10);
          return !isNaN(val) ? val : null;
        };
      } else if (sortCol === 'mtime') {
        getValue = (td) => {
          let val = new Date(td.dataset.val);
          return !isNaN(val) ? val : null;
        };
      }

      return (a, b) => compare(getValue(findCol(a)), getValue(findCol(b))) * sortDir;
    };

    let updateSortIcons = (clickedTh, sortDir) => {
      for (let th of table.tHead.getElementsByTagName('th')) {
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

    for (let th of table.tHead.getElementsByTagName('th')) {
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

        let rows = getTableRows();
        rows.sort(createSorterFn(th.dataset.col, newSortDir));
        for (let tr of rows) {
          tbody.appendChild(tr);
        }
      });
    }
  }
})();
