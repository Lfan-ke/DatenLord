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
    var existing = echarts.getInstanceByDom(node);
    if (existing && !existing.isDisposed()) {
      existing.setOption(option, true);
      return existing;
    }
    var c = echarts.init(node, null, { renderer: 'svg' });
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
        type: 'gauge', radius: '82%', center: ['50%', '62%'],
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
      tooltip: { trigger: 'item',
        formatter: function (info) {
          var pct = data.push_total ? Math.round(info.value / data.push_total * 100) : 0;
          return '<b>' + info.name + '</b><br/>' + info.value + ' / ' + data.push_total + ' · ' + pct + '%';
        },
      },
      legend: { bottom: 8, textStyle: { color: t.fg } },
      color: palette,
      graphic: [
        { type: 'text', left: 'center', top: '38%', z: 100, silent: true,
          style: { text: String(data.push_total || 0), fill: t.fg,
            font: '700 32px ' + GLOBAL_FONT.fontFamily, textAlign: 'center' } },
        { type: 'text', left: 'center', top: '49%', z: 100, silent: true,
          style: { text: 'commits', fill: t.sub,
            font: '12px ' + GLOBAL_FONT.fontFamily, textAlign: 'center' } },
      ],
      series: [{
        type: 'pie',
        radius: ['52%', '78%'],
        center: ['50%', '45%'],
        avoidLabelOverlap: false,
        itemStyle: { borderColor: t.bg, borderWidth: 3, borderRadius: 8 },
        label: { show: false },
        labelLine: { show: false },
        emphasis: { scale: true, scaleSize: 4 },
        data: data.push_per_branch.map(function (p) {
          return { value: p.value, name: p.branch };
        }),
      }],
    }));

    charts.push(mount('chart-line', {
      tooltip: { trigger: 'axis' },
      legend: { bottom: 0, data: data.branches, textStyle: { color: t.fg } },
      color: palette,
      grid: { left: 60, right: 30, top: 48, bottom: 60 },
      xAxis: {
        type: 'category', data: data.date_list,
        axisLabel: { color: t.sub },
        axisLine: { lineStyle: { color: t.grid } },
        splitLine: { show: true, lineStyle: { color: t.grid, type: 'dashed' } },
      },
      yAxis: {
        type: 'value', minInterval: 1, name: 'cum lines',
        nameLocation: 'end', nameGap: 14,
        nameTextStyle: { color: t.sub, padding: [0, 0, 6, 0] },
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
      grid: { left: 70, right: 30, top: 48, bottom: 60 },
      xAxis: {
        type: 'category', data: candleCats, scale: true, boundaryGap: true,
        axisLabel: { color: t.sub },
        axisLine: { lineStyle: { color: t.grid } },
        splitLine: { show: true, lineStyle: { color: t.grid, type: 'dashed' } },
      },
      yAxis: {
        scale: true, name: 'cumulative',
        nameLocation: 'end', nameGap: 14,
        nameTextStyle: { color: t.sub, padding: [0, 0, 6, 0] },
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
      grid: { left: 60, right: 30, top: 32, bottom: 60 },
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
        squareRatio: 0.58,
        itemStyle: { borderColor: 'transparent', borderWidth: 0, gapWidth: 8 },
        levels: [
          {
            itemStyle: {
              gapWidth: 16, borderWidth: 0, borderRadius: 16,
              color: 'rgba(148,163,184,0.15)',
            },
            label: { show: false },
            upperLabel: {
              show: true, height: 36, color: t.fg, fontWeight: 800, fontSize: 15,
              formatter: '{b}', overflow: 'truncate', padding: [0, 16, 0, 16],
              align: 'left', letterSpacing: 0.3,
            },
          },
          {
            itemStyle: {
              gapWidth: 5, borderWidth: 5,
              borderColor: 'rgba(148,163,184,0.15)',
              borderRadius: 12,
              color: 'rgba(148,163,184,0.15)',
              shadowBlur: 0,
            },
            label: { show: false },
            upperLabel: {
              show: true, height: 28, fontWeight: 700, fontSize: 13,
              formatter: function (p) {
                return (p.data && p.data.name) || p.name || '';
              },
              color: t.fg,
              overflow: 'truncate', padding: [0, 12, 0, 12],
              align: 'left', letterSpacing: 0.5,
            },
            emphasis: {
              focus: 'none',
              itemStyle: {
                borderColor: t.dark ? 'rgba(255,255,255,0.6)' : 'rgba(15,23,42,0.5)',
                borderWidth: 5,
              },
            },
          },
          {
            itemStyle: {
              gapWidth: 2, borderWidth: 2,
              borderColor: t.dark ? 'rgba(15,23,42,0.45)' : 'rgba(255,255,255,0.85)',
              borderRadius: 8,
            },
            upperLabel: { show: false },
            label: {
              show: true, position: 'insideTopLeft',
              fontSize: 12, fontWeight: 700,
              padding: [6, 8], overflow: 'truncate',
              lineHeight: 14, letterSpacing: 0.4,
              color: function (p) {
                return (p.data && p.data.textColor) || '#fff';
              },
              formatter: function (p) {
                var d = p.data || {};
                var n = (d.name || '').slice(0, 7);
                var ins = d.ins || 0;
                var dele = d.dele || 0;
                return n + '\n+' + ins + ' / −' + dele;
              },
            },
            emphasis: {
              focus: 'none',
              itemStyle: {
                color: 'rgba(148, 163, 184, 0.45)',
                borderColor: t.dark ? 'rgba(255,255,255,0.75)' : 'rgba(15,23,42,0.55)',
                borderWidth: 2,
              },
              label: { fontSize: 13 },
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
      legend: { show: false },
      color: palette,
      series: [{
        type: 'pie', radius: [28, 108], center: ['50%', '50%'],
        roseType: 'area', avoidLabelOverlap: true,
        itemStyle: { borderRadius: 6, borderColor: t.bg, borderWidth: 2 },
        label: {
          color: t.fg, fontSize: 11, align: 'center',
          formatter: function (p) {
            var b = (p.name || '');
            return '{d|' + (b.length > 5 ? b.slice(5) : b) + '}\n{c|' + p.value + '}';
          },
          rich: {
            d: { color: t.fg, fontSize: 11, fontWeight: 600, align: 'center', lineHeight: 14 },
            c: { color: t.sub, fontSize: 11, align: 'center', lineHeight: 14 },
          },
        },
        labelLine: { length: 10, length2: 6, smooth: true },
        data: data.rose,
      }],
    }));

    var scatterByBranch = {};
    data.branches.forEach(function (b) { scatterByBranch[b] = []; });
    data.scatter.forEach(function (p) {
      if (scatterByBranch[p.branch]) {
        scatterByBranch[p.branch].push({
          value: [p.time.replace(' ', 'T'), Math.max(p.size, 0.5)],
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
        { left: 64, right: 30, top: 64, height: '38%' },
        { left: 64, right: 30, top: '66%', height: '22%' },
      ],
      xAxis: [
        { type: 'time', gridIndex: 0, axisLabel: { color: t.sub, hideOverlap: true }, axisLine: { lineStyle: { color: t.grid } }, splitLine: { lineStyle: { color: t.grid, type: 'dashed' } } },
        { type: 'category', gridIndex: 1, data: data.bar_branch.map(function (b) { return b.branch; }), axisLabel: { color: t.sub }, axisLine: { lineStyle: { color: t.grid } } },
      ],
      yAxis: [
        { type: 'value', gridIndex: 0, name: 'lines/commit',
          nameLocation: 'end', nameGap: 14,
          nameTextStyle: { color: t.sub, padding: [0, 0, 6, 0] },
          axisLabel: { color: t.sub }, splitLine: { lineStyle: { color: t.grid } } },
        { type: 'value', gridIndex: 1, name: 'total',
          nameLocation: 'end', nameGap: 14,
          nameTextStyle: { color: t.sub, padding: [0, 0, 6, 0] },
          axisLabel: { color: t.sub }, splitLine: { lineStyle: { color: t.grid } } },
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
        min: 1, max: Math.max(2, data.cal_max),
        calculable: false, orient: 'horizontal', left: 'center', top: 0,
        textStyle: { color: t.fg }, splitNumber: 4,
        inRange: { color: t.heat },
        outOfRange: { color: t.cellEmpty },
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

    var fs = data.files_series || [];
    var fsCats = fs.map(function (f) { return f.sha; });
    var fsAdded = fs.map(function (f) { return f.added || 0; });
    var fsDeleted = fs.map(function (f) { return -(f.deleted || 0); });
    var fsTouched = fs.map(function (f) { return f.touched || 0; });
    charts.push(mount('chart-files', {
      tooltip: { trigger: 'axis', axisPointer: { type: 'cross', crossStyle: { color: t.sub } },
        formatter: function (params) {
          var idx = params[0] ? params[0].dataIndex : 0;
          var f = fs[idx] || {};
          return '<b>' + (f.sha || '') + '</b> · ' + (f.branch || '') +
                 '<br/>' + (f.time || '') +
                 '<br/>+' + (f.added || 0) + ' / −' + (f.deleted || 0) + ' files' +
                 '<br/>' + (f.touched || 0) + ' total touched';
        },
      },
      legend: { data: ['Files added', 'Files deleted', 'Files touched'],
        bottom: 0, textStyle: { color: t.fg } },
      grid: { left: 64, right: 70, top: 48, bottom: 60 },
      xAxis: [{ type: 'category', data: fsCats,
        axisLabel: { color: t.sub },
        axisLine: { lineStyle: { color: t.grid } },
        splitLine: { show: true, lineStyle: { color: t.grid, type: 'dashed' } },
      }],
      yAxis: [
        { type: 'value', name: 'files', minInterval: 1,
          nameLocation: 'end', nameGap: 14,
          nameTextStyle: { color: t.sub, padding: [0, 0, 6, 0] },
          axisLabel: { color: t.sub, formatter: '{value}' },
          splitLine: { lineStyle: { color: t.grid } } },
        { type: 'value', name: 'touched', minInterval: 1,
          nameLocation: 'end', nameGap: 14,
          nameTextStyle: { color: t.sub, padding: [0, 0, 6, 0] },
          axisLabel: { color: t.sub, formatter: '{value}' },
          splitLine: { show: false } },
      ],
      series: [
        { name: 'Files added', type: 'bar', stack: 'fs', barWidth: 18,
          itemStyle: { color: '#22c55e', borderRadius: [4, 4, 0, 0] },
          data: fsAdded },
        { name: 'Files deleted', type: 'bar', stack: 'fs', barWidth: 18,
          itemStyle: { color: '#ef4444', borderRadius: [0, 0, 4, 4] },
          data: fsDeleted },
        { name: 'Files touched', type: 'line', yAxisIndex: 1,
          symbol: 'circle', symbolSize: 8, smooth: false,
          lineStyle: { width: 2.4, color: '#3b82f6' },
          itemStyle: { color: '#3b82f6', borderColor: t.bg, borderWidth: 2 },
          data: fsTouched },
      ],
    }));

    var ringDetailOffsets = ['-28.48%', '8.52%', '45.52%'];
    var ringNameTops = ['29.63%', '45.13%', '60.63%'];
    var ringData = data.push_per_branch.map(function (b, i) {
      var pct = data.push_total ? Math.round(b.value / data.push_total * 100) : 0;
      return {
        value: pct, name: '',
        itemStyle: { color: palette[i] },
        title: { show: false },
        detail: {
          valueAnimation: true,
          offsetCenter: ['0%', ringDetailOffsets[i] || '10%'],
          color: palette[i],
        },
      };
    });
    var ringNamesGraphic = data.push_per_branch.map(function (b, i) {
      return {
        type: 'text', left: 'center', top: ringNameTops[i] || '50%',
        z: 1000, silent: true,
        style: {
          text: b.branch, fill: t.fg,
          font: '700 13px ' + GLOBAL_FONT.fontFamily,
          textAlign: 'center', textVerticalAlign: 'middle',
        },
      };
    });
    charts.push(mount('chart-score-ring', {
      tooltip: { trigger: 'item',
        formatter: function (p) {
          var b = data.push_per_branch[p.dataIndex] || {};
          return '<b>' + (b.branch || '') + '</b><br/>' + (b.value || 0) +
                 ' / ' + (data.push_total || 0) + ' · ' + (p.value || 0) + '%';
        },
      },
      graphic: ringNamesGraphic,
      series: [{
        type: 'gauge',
        startAngle: 90, endAngle: -270,
        radius: '85%',
        min: 0, max: 100,
        pointer: { show: false },
        progress: {
          show: true, overlap: false, roundCap: true, clip: false,
          itemStyle: { borderWidth: 1, borderColor: t.bg },
        },
        axisLine: { lineStyle: { width: 30,
          color: [[1, t.dark ? 'rgba(148,163,184,0.12)' : 'rgba(148,163,184,0.22)']] } },
        splitLine: { show: false },
        axisTick: { show: false },
        axisLabel: { show: false },
        title: { show: false },
        detail: {
          width: 52, height: 16, fontSize: 12,
          color: 'inherit', borderColor: 'inherit',
          borderRadius: 8, borderWidth: 1,
          formatter: '{value}%',
          fontFamily: GLOBAL_FONT.fontFamily,
        },
        data: ringData,
      }],
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

  function disposeStale() {
    charts = charts.filter(function (c) {
      if (!c || c.isDisposed()) return false;
      var dom = c.getDom && c.getDom();
      if (!dom || !document.body.contains(dom)) { c.dispose(); return false; }
      return true;
    });
  }

  function needsBuild() {
    var nodes = document.querySelectorAll('.echart');
    if (!nodes.length) return false;
    for (var i = 0; i < nodes.length; i++) {
      var inst = window.echarts && window.echarts.getInstanceByDom(nodes[i]);
      if (!inst || inst.isDisposed()) return true;
    }
    return false;
  }

  function render(force) {
    var el = document.getElementById('stats-data');
    if (!el) { disposeStale(); return; }
    if (!force && !needsBuild()) return;
    var data;
    try { data = JSON.parse(el.textContent); } catch (_) { return; }
    ensureEcharts(function () {
      disposeStale();
      build(data);
      requestAnimationFrame(resize);
      setTimeout(resize, 120);
      attachGlobal();
      observeResize();
    });
  }
  function resize() { charts.forEach(function (c) { if (c) try { c.resize(); } catch (_) {} }); }

  var globalAttached = false;
  function attachGlobal() {
    if (globalAttached) return;
    globalAttached = true;
    window.addEventListener('resize', resize);
    observeTheme();
  }

  function observeResize() {
    if (typeof ResizeObserver === 'undefined') return;
    document.querySelectorAll('.echart').forEach(function (n) {
      if (n.__dlRO) return;
      n.__dlRO = true;
      new ResizeObserver(function () { resize(); }).observe(n);
    });
  }

  var _ioCharts = null, _ioEntries = null;
  function observeReveal() {
    if (typeof IntersectionObserver === 'undefined') {
      document.querySelectorAll('.echart, .dl-tl-entry').forEach(function (n) {
        n.classList.add('dl-visible');
      });
      return;
    }
    if (!_ioCharts) {
      _ioCharts = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) { e.target.classList.add('dl-visible'); _ioCharts.unobserve(e.target); }
        });
      }, { rootMargin: '0px 0px -10% 0px', threshold: 0.12 });
    }
    if (!_ioEntries) {
      _ioEntries = new IntersectionObserver(function (entries) {
        entries.forEach(function (e) {
          if (e.isIntersecting) { e.target.classList.add('dl-visible'); _ioEntries.unobserve(e.target); }
        });
      }, { rootMargin: '0px 0px -8% 0px', threshold: 0.18 });
    }
    document.querySelectorAll('.echart').forEach(function (n) {
      if (n.__dlIO) return;
      n.__dlIO = true;
      _ioCharts.observe(n);
    });
    document.querySelectorAll('.dl-tl-entry').forEach(function (n) {
      if (n.__dlIO) return;
      n.__dlIO = true;
      _ioEntries.observe(n);
    });
  }
  function observeTheme() {
    schemeNow = getScheme();
    var fire = function () {
      var s = getScheme();
      if (s !== schemeNow) { schemeNow = s; render(true); }
    };
    var mo = new MutationObserver(fire);
    if (document.body) {
      mo.observe(document.body, { attributes: true, attributeFilter: ['data-md-color-scheme'] });
    }
    mo.observe(document.documentElement, { attributes: true, attributeFilter: ['data-md-color-scheme'] });
  }

  function tryRender(force) {
    if (document.getElementById('stats-data')) render(force);
  }

  function attach() {
    tryRender(true);
    observeReveal();
    window.addEventListener('load', function () { tryRender(); observeReveal(); });
    document.addEventListener('change', function (e) {
      if (e.target && e.target.name === '__palette') {
        setTimeout(function () { render(true); }, 60);
      }
    });
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', attach);
  } else {
    attach();
  }
})();
