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

    for (let th of table.tHead.getElementsByTagName('th')) {
      th.classList.add('sort');

      th.addEventListener('click', (event) => {
        event.preventDefault();

        let sortDir = 1;
        if (th.dataset.sortDir === '1') {
          sortDir = -1;
        }

        for (let th2 of table.tHead.getElementsByTagName('th')) {
          th2.dataset.sortDir = th === th2 ? sortDir : '0';
          for (let svgUse of th2.querySelectorAll('svg.icon > use')) {
            let icon = 'none';
            if (th2 === th && sortDir > 0) {
              icon = 'sort-asc';
            } else if (th2 === th && sortDir < 0) {
              icon = 'sort-dsc';
            }
            svgUse.setAttribute('href', '#icon-' + icon);
          }
        }

        let rows = [];
        let tbody = table.tBodies[0];
        for (let tr of tbody.rows) {
          if (!tr.classList.contains('parent')) {
            rows.push(tr);
          }
        }

        let findCol = (tr) => {
          for (let td of tr.getElementsByTagName('td')) {
            if (td.dataset.col === th.dataset.col) {
              return td;
            }
          }
          return null;
        };
        let getValue = (td) => {
          return null;
        };
        let compare = (a, b) => {
          if (a > b) return 1;
          if (a < b) return -1;
          return 0;
        };

        if (th.dataset.col === 'name') {
          getValue = (td) => {
            return td.innerText;
          };
          compare = (a, b) => {
            return a.localeCompare(b);
          };
        } else if (th.dataset.col === 'size') {
          getValue = (td) => {
            let val = parseInt(td.dataset.val, 10);
            return !isNaN(val) ? val : null;
          };
        } else if (th.dataset.col === 'mtime') {
          getValue = (td) => {
            let val = new Date(td.dataset.val);
            return !isNaN(val) ? val : null;
          };
        }

        rows.sort((a, b) => {
          return compare(getValue(findCol(a)), getValue(findCol(b))) * sortDir;
        });
        for (let tr of rows) {
          tbody.appendChild(tr);
        }
      });
    }
  }
})();
