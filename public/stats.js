(function () {
  var ECHARTS_CDN = 'https://cdn.jsdelivr.net/npm/echarts@5/dist/echarts.min.js';
  var charts = [];
  var schemeNow = null;

  function loadScript(url, cb) {
    var s = document.createElement('script');
    s.src = url; s.async = true; s.onload = cb;
    document.head.appendChild(s);
  }
  function ensureEcharts(cb) {
    if (window.echarts) return cb();
    loadScript(ECHARTS_CDN, cb);
  }

  function getScheme() {
    return (document.body && document.body.getAttribute('data-md-color-scheme')) ||
           document.documentElement.getAttribute('data-md-color-scheme') ||
           'default';
  }

  function theme() {
    var dark = getScheme() === 'slate';
    return {
      dark: dark,
      fg: dark ? '#e2e8f0' : '#0f172a',
      sub: dark ? '#94a3b8' : '#475569',
      grid: dark ? 'rgba(148,163,184,0.18)' : 'rgba(100,116,139,0.18)',
      bg: dark ? '#0b1220' : '#ffffff',
      cellEmpty: dark ? 'rgba(148,163,184,0.08)' : '#ebedf0',
      heat: dark
        ? ['#0e4429', '#006d32', '#26a641', '#39d353']
        : ['#9be9a8', '#40c463', '#30a14e', '#216e39'],
    };
  }

  var GLOBAL_FONT = {
    fontFamily: "'JetBrains Mono', 'HarmonyOS Sans SC', 'Microsoft YaHei UI Light', 'Microsoft YaHei', sans-serif",
  };

  function mount(id, option) {
    var node = document.getElementById(id);
    if (!node) return null;
    var existing = echarts.getInstanceByDom(node);
    if (existing) existing.dispose();
    var c = echarts.init(node, null, { renderer: 'svg' });
    var t = theme();
    option.textStyle = Object.assign({ color: t.fg }, GLOBAL_FONT, option.textStyle || {});
    var ttDefaults = {
      backgroundColor: t.dark ? 'rgba(15, 23, 42, 0.96)' : 'rgba(255, 255, 255, 0.96)',
      borderColor: t.dark ? 'rgba(148, 163, 184, 0.35)' : 'rgba(100, 116, 139, 0.28)',
      borderWidth: 1,
      padding: [6, 10],
      enterable: false,
      transitionDuration: 0.1,
      extraCssText: 'border-radius: 8px !important; line-height: 1.45 !important; width: max-content !important; width: -moz-max-content !important; max-width: 260px !important; min-width: 0 !important; white-space: normal !important; word-break: break-word !important; box-sizing: border-box !important; box-shadow: 0 6px 18px rgba(15, 23, 42, ' + (t.dark ? '0.55' : '0.10') + ') !important;',
      textStyle: { color: t.fg, fontFamily: GLOBAL_FONT.fontFamily, fontSize: 11 },
    };
    option.tooltip = Object.assign({}, ttDefaults, option.tooltip || {});
    c.setOption(option);
    return c;
  }

  function build(data) {
    var t = theme();
    var palette = data.colors;
    charts.forEach(function (c) { if (c) c.dispose(); });
    charts = [];

    charts.push(mount('chart-gauge', {
      series: [{
        type: 'gauge', radius: '92%',
        startAngle: 200, endAngle: -20,
        min: 0, max: 100, splitNumber: 10,
        axisLine: { lineStyle: { width: 18, color: [
          [0.34, '#f97316'], [0.67, '#eab308'], [1, '#22c55e'],
        ]}},
        pointer: { itemStyle: { color: 'auto' }, length: '62%', width: 5 },
        axisTick: { distance: -22, length: 6, lineStyle: { color: t.bg, width: 2 } },
        splitLine: { distance: -24, length: 14, lineStyle: { color: t.bg, width: 3 } },
        axisLabel: { color: 'auto', distance: 32, fontSize: 11 },
        anchor: { show: true, showAbove: true, size: 16,
          itemStyle: { borderWidth: 2, color: t.fg } },
        detail: { valueAnimation: true, formatter: '{value}%',
          color: t.fg, fontSize: 32, fontWeight: 700, offsetCenter: [0, '24%'] },
        title: { offsetCenter: [0, '46%'], color: t.sub, fontSize: 12 },
        data: [{ value: data.completion_pct, name: 'Course Progress · ' + data.completed + ' / ' + data.total }],
      }],
    }));

    charts.push(mount('chart-score', {
      tooltip: { trigger: 'item', confine: true,
        formatter: function (info) {
          var pct = data.push_total ? Math.round(info.value / data.push_total * 100) : 0;
          return '<b>' + info.name + '</b><br/>' + info.value + ' / ' + data.push_total + ' pushes · ' + pct + '%';
        },
      },
      legend: { bottom: 8, textStyle: { color: t.fg } },
      color: palette,
      series: [{
        type: 'pie',
        radius: ['52%', '78%'],
        center: ['50%', '45%'],
        avoidLabelOverlap: false,
        itemStyle: { borderColor: t.bg, borderWidth: 3, borderRadius: 8 },
        label: { show: true, position: 'center',
          formatter: [
            '{tot|' + (data.push_total || 0) + '}',
            '{lab|pushes}',
          ].join('\n'),
          rich: {
            tot: { color: t.fg, fontSize: 32, fontWeight: 700, lineHeight: 36 },
            lab: { color: t.sub, fontSize: 12, lineHeight: 18 },
          },
        },
        labelLine: { show: false },
        emphasis: { label: { show: false } },
        data: data.push_per_branch.map(function (p) {
          return { value: p.value, name: p.branch };
        }),
      }],
    }));

    charts.push(mount('chart-line', {
      tooltip: { trigger: 'axis' },
      legend: { bottom: 0, data: data.branches, textStyle: { color: t.fg } },
      color: palette,
      grid: { left: 50, right: 24, top: 24, bottom: 56 },
      xAxis: {
        type: 'category', data: data.date_list,
        axisLabel: { color: t.sub },
        axisLine: { lineStyle: { color: t.grid } },
        splitLine: { show: true, lineStyle: { color: t.grid, type: 'dashed' } },
      },
      yAxis: {
        type: 'value', minInterval: 1, name: 'cum lines',
        nameTextStyle: { color: t.sub },
        axisLabel: { color: t.sub }, splitLine: { lineStyle: { color: t.grid } },
      },
      series: data.line_series.map(function (s, i) {
        return {
          name: s.branch, type: 'line', step: 'middle',
          data: s.data.map(function (p) { return p[1]; }),
          showSymbol: true, symbolSize: 7,
          lineStyle: { width: 2.4, color: palette[i] },
          itemStyle: { color: palette[i] },
          emphasis: { focus: 'series' },
        };
      }),
    }));

    var candleData = data.candle.map(function (c) { return c.values; });
    var candleCats = data.candle.map(function (c) { return c.sha; });
    charts.push(mount('chart-candle', {
      tooltip: { trigger: 'axis', axisPointer: { type: 'cross' },
        formatter: function (params) {
          var p = params[0]; if (!p) return '';
          var d = data.candle[p.dataIndex] || {};
          var net = d.values[1];
          return '<b>' + d.sha + '</b> · ' + d.branch + '<br/>' + d.time +
                 '<br/>+' + d.ins + ' / −' + d.dele +
                 '<br/>net ' + (net >= 0 ? '+' : '') + net;
        },
      },
      legend: { show: false },
      grid: { left: 60, right: 24, top: 24, bottom: 56 },
      xAxis: {
        type: 'category', data: candleCats, scale: true, boundaryGap: true,
        axisLabel: { color: t.sub },
        axisLine: { lineStyle: { color: t.grid } },
        splitLine: { show: true, lineStyle: { color: t.grid, type: 'dashed' } },
      },
      yAxis: {
        scale: true, name: 'cumulative',
        nameTextStyle: { color: t.sub },
        axisLabel: { color: t.sub }, splitLine: { lineStyle: { color: t.grid } },
      },
      series: [{
        name: 'commit', type: 'candlestick', data: candleData,
        itemStyle: {
          color: '#22c55e', color0: '#ef4444',
          borderColor: '#22c55e', borderColor0: '#ef4444', borderWidth: 1.5,
        },
      }],
    }));

    var wfPlaceholder = data.waterfall.map(function (w) {
      return w.net >= 0 ? w.before : (w.before + w.net);
    });
    var wfPositive = data.waterfall.map(function (w) {
      return w.net >= 0 ? w.net : '-';
    });
    var wfNegative = data.waterfall.map(function (w) {
      return w.net < 0 ? -w.net : '-';
    });
    var wfCats = data.waterfall.map(function (w) { return w.sha; });
    charts.push(mount('chart-waterfall', {
      tooltip: { trigger: 'axis', axisPointer: { type: 'shadow' },
        formatter: function (params) {
          var idx = params[0] ? params[0].dataIndex : 0;
          var w = data.waterfall[idx] || {};
          return '<b>' + w.sha + '</b> · ' + w.branch + '<br/>' + w.time +
                 '<br/>+' + w.ins + ' / −' + w.dele + ' · net ' +
                 (w.net >= 0 ? '+' : '') + w.net +
                 '<br/>running: ' + w.before + ' → ' + w.after;
        },
      },
      legend: { data: ['Increase', 'Decrease'], bottom: 0, textStyle: { color: t.fg } },
      grid: { left: 56, right: 24, top: 24, bottom: 56 },
      xAxis: {
        type: 'category', data: wfCats,
        axisLabel: { color: t.sub, rotate: 0 },
        axisLine: { lineStyle: { color: t.grid } },
      },
      yAxis: { type: 'value', axisLabel: { color: t.sub }, splitLine: { lineStyle: { color: t.grid } } },
      series: [
        {
          name: 'Placeholder', type: 'bar', stack: 'wf',
          itemStyle: { borderColor: 'transparent', color: 'transparent' },
          emphasis: { itemStyle: { borderColor: 'transparent', color: 'transparent' } },
          data: wfPlaceholder,
        },
        {
          name: 'Increase', type: 'bar', stack: 'wf', barWidth: 18,
          itemStyle: { color: '#22c55e', borderRadius: [4, 4, 0, 0] },
          data: wfPositive,
        },
        {
          name: 'Decrease', type: 'bar', stack: 'wf', barWidth: 18,
          itemStyle: { color: '#ef4444', borderRadius: [0, 0, 4, 4] },
          data: wfNegative,
        },
      ],
    }));

    var treeRoot = (data.treemap && data.treemap[0]) || { children: [] };
    var leafFloor = 8;
    function floorLeaves(node) {
      if (node.children && node.children.length) {
        node.children.forEach(floorLeaves);
      } else {
        node.value = Math.max(Number(node.value) || 0, leafFloor);
      }
    }
    floorLeaves(treeRoot);

    charts.push(mount('chart-treemap', {
      tooltip: {
        formatter: function (info) {
          var d = info.data || {};
          var path = (info.treePathInfo || []).slice(1).map(function (n) { return n.name; }).join(' / ');
          if (d.children && d.children.length) {
            return '<b>' + (path || d.name) + '</b><br/>' + d.children.length + ' children · ' + (info.value || 0) + ' lines';
          }
          return '<b>' + (path || d.name) + '</b><br/>+' + (d.ins || 0) + ' / −' + (d.dele || 0) +
                 (d.label ? '<br/><span style="opacity:.7">' + d.label + '</span>' : '');
        },
      },
      series: [{
        name: 'project', type: 'treemap',
        roam: false, nodeClick: false, breadcrumb: { show: false },
        width: '100%', height: '100%',
        visibleMin: 0, childrenVisibleMin: 0,
        squareRatio: 0.62,
        label: { show: true, formatter: '{b}' },
        upperLabel: { show: true, height: 28, color: '#fff' },
        itemStyle: { borderColor: t.bg, borderWidth: 0, gapWidth: 6 },
        levels: [
          {
            itemStyle: {
              gapWidth: 14, borderWidth: 0, borderRadius: 14,
              color: t.dark ? 'rgba(148,163,184,0.10)' : 'rgba(241,245,249,0.92)',
            },
            upperLabel: {
              show: true, height: 34, color: t.fg, fontWeight: 800, fontSize: 15,
              formatter: '{b}', overflow: 'truncate', padding: [0, 14, 0, 14],
              align: 'left',
            },
          },
          {
            itemStyle: {
              gapWidth: 4, borderWidth: 4, borderColor: t.bg, borderRadius: 10,
            },
            upperLabel: {
              show: true, height: 26, color: '#fff', fontWeight: 700, fontSize: 13,
              formatter: '{b}', overflow: 'truncate', padding: [0, 10, 0, 10],
              align: 'left',
            },
            emphasis: { itemStyle: { borderColor: t.dark ? '#fff' : '#0f172a' } },
          },
          {
            colorSaturation: [0.42, 0.88],
            itemStyle: {
              gapWidth: 2, borderWidth: 2, borderColor: t.bg, borderRadius: 6,
              borderColorSaturation: 0.7,
            },
            label: {
              show: true, position: 'insideTopLeft',
              color: '#fff', fontSize: 11, padding: [4, 6],
              overflow: 'truncate',
              formatter: function (p) {
                var d = p.data || {};
                var n = (d.name || '').slice(0, 7);
                if (d.ins == null && d.dele == null) return '{title|' + n + '}';
                return '{title|' + n + '}\n{body|+' + (d.ins || 0) + ' / −' + (d.dele || 0) + '}';
              },
              rich: {
                title: { fontSize: 12, fontWeight: 700, color: '#fff', lineHeight: 16 },
                body: { fontSize: 10, color: 'rgba(255,255,255,0.88)', lineHeight: 14 },
              },
            },
            emphasis: {
              itemStyle: { borderColor: '#fff', borderWidth: 3 },
              label: { fontSize: 12 },
            },
          },
        ],
        data: [treeRoot],
      }],
    }));

    charts.push(mount('chart-rose', {
      title: { text: 'Commits by date', left: 'center', top: 8,
        textStyle: { color: t.fg, fontSize: 14, fontWeight: 600 } },
      tooltip: { trigger: 'item', formatter: '{b}: {c} commit(s)' },
      legend: { bottom: 0, textStyle: { color: t.fg } },
      color: palette,
      series: [{
        type: 'pie', radius: [30, 130], center: ['50%', '52%'],
        roseType: 'area', avoidLabelOverlap: true,
        itemStyle: { borderRadius: 6, borderColor: t.bg, borderWidth: 2 },
        label: { color: t.fg, formatter: '{b}\n{c}' },
        data: data.rose,
      }],
    }));

    var scatterByBranch = {};
    data.branches.forEach(function (b) { scatterByBranch[b] = []; });
    data.scatter.forEach(function (p) {
      if (scatterByBranch[p.branch]) {
        scatterByBranch[p.branch].push({
          value: [p.time + ':00', p.size],
          label: p.label, ins: p.ins, dele: p.dele,
        });
      }
    });
    charts.push(mount('chart-scatter', {
      title: { text: 'Commit scatter & branch total', left: 'center', top: 8,
        textStyle: { color: t.fg, fontSize: 14, fontWeight: 600 } },
      tooltip: { trigger: 'item', formatter: function (info) {
        if (info.seriesType === 'scatter') {
          var d = info.data || {};
          return '<b>' + info.seriesName + '</b><br/>+' + (d.ins || 0) +
                 ' / −' + (d.dele || 0) + '<br/><span style="opacity:.7">' + (d.label || '') + '</span>';
        }
        return info.name + ': ' + info.value;
      }},
      legend: { data: data.branches, bottom: 0, textStyle: { color: t.fg } },
      grid: [
        { left: 50, right: 24, top: 48, height: '40%' },
        { left: 50, right: 24, top: '64%', height: '24%' },
      ],
      xAxis: [
        { type: 'time', gridIndex: 0, axisLabel: { color: t.sub }, axisLine: { lineStyle: { color: t.grid } }, splitLine: { lineStyle: { color: t.grid, type: 'dashed' } } },
        { type: 'category', gridIndex: 1, data: data.bar_branch.map(function (b) { return b.branch; }), axisLabel: { color: t.sub }, axisLine: { lineStyle: { color: t.grid } } },
      ],
      yAxis: [
        { type: 'value', gridIndex: 0, name: 'lines/commit', nameTextStyle: { color: t.sub }, axisLabel: { color: t.sub }, splitLine: { lineStyle: { color: t.grid } } },
        { type: 'value', gridIndex: 1, name: 'total', nameTextStyle: { color: t.sub }, axisLabel: { color: t.sub }, splitLine: { lineStyle: { color: t.grid } } },
      ],
      color: palette,
      series: data.branches.map(function (b, i) {
        return {
          name: b, type: 'scatter', xAxisIndex: 0, yAxisIndex: 0,
          data: scatterByBranch[b],
          symbolSize: function (val) { return Math.max(10, Math.sqrt(val[1] || 1) * 3.2); },
          itemStyle: { color: palette[i], opacity: 0.82, shadowBlur: 6, shadowColor: 'rgba(0,0,0,0.2)' },
        };
      }).concat([{
        name: 'Total per branch', type: 'bar', xAxisIndex: 1, yAxisIndex: 1,
        data: data.bar_branch.map(function (b, i) {
          return { value: b.value, itemStyle: { color: palette[i % palette.length], borderRadius: [4, 4, 0, 0] } };
        }),
        barWidth: 28,
      }]),
    }));

    var calRange = data.cal_full_range || data.cal_range;
    charts.push(mount('chart-calendar', {
      tooltip: { formatter: function (p) { return p.value[0] + ' · ' + p.value[1] + ' commit(s)'; } },
      visualMap: {
        min: 0, max: Math.max(1, data.cal_max),
        calculable: false, orient: 'horizontal', left: 'center', top: 0,
        textStyle: { color: t.fg }, splitNumber: 4,
        inRange: { color: [t.cellEmpty].concat(t.heat) },
      },
      calendar: {
        top: 56, left: 36, right: 36, bottom: 12,
        cellSize: ['auto', 14],
        range: calRange,
        yearLabel: { show: false },
        monthLabel: { color: t.sub, fontSize: 11 },
        dayLabel: { color: t.sub, fontSize: 10, nameMap: 'en' },
        itemStyle: { borderColor: t.bg, borderWidth: 2, borderRadius: 3,
          color: t.cellEmpty },
        splitLine: { show: false },
      },
      series: { type: 'heatmap', coordinateSystem: 'calendar', data: data.cal_data },
    }));

    charts.push(mount('chart-calgraph', {
      tooltip: {
        trigger: 'item', confine: true,
        formatter: function (p) {
          if (!p) return '';
          if (p.dataType === 'edge') {
            var s = (p.data && p.data.source) || '?';
            var tg = (p.data && p.data.target) || '?';
            return s + ' &rarr; ' + tg;
          }
          var d = p.data || {};
          var name = d.name || p.name || '';
          var v = d.value || [];
          var count = Array.isArray(v) ? (v[1] || 0) : 0;
          var lines = d.lines != null ? d.lines : 0;
          var branches = Array.isArray(d.branches) ? d.branches : [];
          return '<b>' + name + '</b><br/>' + count + ' commit(s) · ' + lines + ' lines' +
                 (branches.length ? '<br/>' + branches.join(' · ') : '');
        },
      },
      calendar: {
        top: 32, left: 36, right: 36, bottom: 16,
        range: calRange, cellSize: ['auto', 18],
        yearLabel: { show: false },
        monthLabel: { color: t.sub, fontSize: 11 },
        dayLabel: { color: t.sub, fontSize: 10, nameMap: 'en' },
        itemStyle: { borderColor: t.bg, borderWidth: 2, borderRadius: 3,
          color: t.cellEmpty },
        splitLine: { show: false },
      },
      series: [{
        type: 'graph', coordinateSystem: 'calendar',
        edgeSymbol: ['none', 'arrow'], edgeSymbolSize: 7,
        symbol: 'circle', z: 10,
        label: { show: false },
        lineStyle: { curveness: 0.3, opacity: 0.9 },
        emphasis: { focus: 'adjacency', lineStyle: { width: 3 } },
        data: data.cal_nodes,
        links: data.cal_links,
      }],
    }));
  }

  function render() {
    var el = document.getElementById('stats-data');
    if (!el) return;
    var data;
    try { data = JSON.parse(el.textContent); } catch (_) { return; }
    ensureEcharts(function () {
      build(data);
      window.addEventListener('resize', resize);
      observeTheme(data);
      observeResize();
    });
  }
  function resize() { charts.forEach(function (c) { if (c) c.resize(); }); }
  function observeResize() {
    if (typeof ResizeObserver === 'undefined') return;
    var ro = new ResizeObserver(function () { resize(); });
    document.querySelectorAll('.echart').forEach(function (n) { ro.observe(n); });
  }
  function observeTheme(data) {
    if (schemeNow === null) {
      schemeNow = getScheme();
      var mo = new MutationObserver(function () {
        var s = getScheme();
        if (s !== schemeNow) { schemeNow = s; build(data); }
      });
      if (document.body) {
        mo.observe(document.body, { attributes: true, attributeFilter: ['data-md-color-scheme'] });
      }
      mo.observe(document.documentElement, { attributes: true, attributeFilter: ['data-md-color-scheme'] });
    }
  }

  if (window.document$) window.document$.subscribe(function () { render(); });
  else document.addEventListener('DOMContentLoaded', render);
})();
