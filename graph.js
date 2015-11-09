// Generated by CoffeeScript 1.10.0
(function() {
  var calcGraphStats, diagonal, h, i, margin, nodeFillColor, nodeRadius, root, toggle, tree, update, vis, w;

  margin = [20, 120, 20, 120];

  w = 1280 - margin[1] - margin[3];

  h = 800 - margin[0] - margin[2];

  i = 0;

  root = void 0;

  nodeRadius = 4.5;

  tree = d3.layout.tree().size([h, w]);

  diagonal = d3.svg.diagonal().projection(function(d) {
    return [d.x, d.y];
  });

  vis = d3.select('#body').append('svg:svg').attr('width', w + margin[1] + margin[3]).attr('height', h + margin[0] + margin[2]).append('svg:g').attr('transform', 'translate(' + margin[3] + ',' + margin[0] + ')');

  nodeFillColor = function(d) {
    if (d._children) {
      if (d.GhostFlag) {
        return '#aaa';
      } else {
        return 'lightsteelblue';
      }
    } else {
      return '#fff';
    }
  };

  calcGraphStats = function(nodes) {
    var d, j, len, maxDepth, maxSnap, minSnap, snap;
    maxDepth = 0;
    minSnap = 99999;
    maxSnap = -1;
    for (j = 0, len = nodes.length; j < len; j++) {
      d = nodes[j];
      if (d.depth > maxDepth) {
        maxDepth = d.depth;
      }
      snap = Number(d.name.split('|')[0]);
      if (snap > maxSnap) {
        maxSnap = snap;
      }
      if (snap < minSnap) {
        minSnap = snap;
      }
    }
    return [maxDepth, minSnap, maxSnap];
  };

  update = function(source) {
    var duration, j, link, linkEnter, maxDepth, maxSnap, minSnap, node, nodeEnter, nodeExit, nodeUpdate, nodes, ref, results, snapLines;
    duration = d3.event && d3.event.altKey ? 5000 : 500;
    nodes = tree.nodes(root).reverse();
    ref = calcGraphStats(nodes), maxDepth = ref[0], minSnap = ref[1], maxSnap = ref[2];
    nodes.forEach(function(d) {
      return d.y = d.depth * (h / maxDepth);
    });
    console.log(minSnap, maxSnap);
    snapLines = vis.selectAll('g.snapLine').data((function() {
      results = [];
      for (var j = minSnap; minSnap <= maxSnap ? j <= maxSnap : j >= maxSnap; minSnap <= maxSnap ? j++ : j--){ results.push(j); }
      return results;
    }).apply(this), function(d, i) {
      var k, results1;
      return (function() {
        results1 = [];
        for (var k = minSnap; minSnap <= maxSnap ? k <= maxSnap : k >= maxSnap; minSnap <= maxSnap ? k++ : k--){ results1.push(k); }
        return results1;
      }).apply(this)[i];
    });
    snapLines.enter().append('svg:g').attr('class', 'snapLine').append('svg:line').attr('x1', 0).attr('x2', w).attr('y1', function(d, i) {
      return i * (h / (maxSnap - minSnap));
    }).attr('y2', function(d, i) {
      return i * (h / (maxSnap - minSnap));
    }).style('stroke', '#aaa').style('stroke-opacity', 0.2).style('stroke-width', 1);
    snapLines.select('line').transition().duration(duration).attr('y1', function(d, i) {
      return i * (h / (maxSnap - minSnap));
    }).attr('y2', function(d, i) {
      return i * (h / (maxSnap - minSnap));
    });
    snapLines.exit().transition().remove().select('line').attr('stroke-opacity', 0);
    node = vis.selectAll('g.node').data(nodes, function(d) {
      return d.id || (d.id = ++i);
    });
    nodeEnter = node.enter().append('svg:g').attr('class', function(d) {
      var cls;
      cls = 'node type' + d.Type;
      if (d.GhostFlag) {
        cls += ' ghost';
      }
      return cls;
    });
    nodeEnter.attr('transform', function(d) {
      if (d.Type === 0) {
        return 'translate(' + source.x0 + ',' + source.y0 + ')';
      } else {
        return 'translate(' + (source.x0 - nodeRadius) + ',' + (source.y0 - nodeRadius) + ')';
      }
    }).on('click', function(d) {
      toggle(d);
      update(d);
    });
    nodeEnter.filter(function(d) {
      return d.Type === 0;
    }).append('svg:circle').attr('r', 1e-6).style('fill', nodeFillColor);
    nodeEnter.filter(function(d) {
      return d.Type > 0;
    }).append('svg:rect').attr('width', 1e-6).attr('height', 1e-6).style('fill', nodeFillColor);
    nodeUpdate = node.transition().duration(duration).attr('transform', function(d) {
      if (d.Type === 0) {
        return 'translate(' + d.x + ',' + d.y + ')';
      } else {
        return 'translate(' + (d.x - nodeRadius) + ',' + (d.y - nodeRadius) + ')';
      }
    });
    nodeUpdate.select('circle').attr('r', nodeRadius).style('fill', nodeFillColor);
    nodeUpdate.select('rect').attr('width', 2 * nodeRadius).attr('height', 2 * nodeRadius).style('fill', nodeFillColor);
    nodeUpdate.select('text').style('fill-opacity', 1);
    nodeExit = node.exit().transition().duration(duration).attr('transform', function(d) {
      return 'translate(' + source.x + ',' + source.y + ')';
    }).remove();
    nodeExit.select('circle').attr('r', 1e-6);
    nodeExit.select('rect').attr('width', 1e-6).attr('height', 1e-6);
    nodeExit.select('text').style('fill-opacity', 1e-6);
    link = vis.selectAll('path.link').data(tree.links(nodes), function(d) {
      return d.target.id;
    });
    linkEnter = link.enter().insert('svg:path', 'g').attr('class', 'link').attr('d', function(d) {
      var o;
      o = {
        x: source.x0,
        y: source.y0
      };
      return diagonal({
        source: o,
        target: o
      });
    });
    linkEnter.transition().duration(duration).attr('d', diagonal);
    linkEnter.style('stroke', function(d) {
      if (d.target.mainProg) {
        return '#000';
      } else {
        return '#ccc';
      }
    });
    link.transition().duration(duration).attr('d', diagonal);
    link.exit().transition().duration(duration).attr('d', function(d) {
      var o;
      o = {
        x: source.x,
        y: source.y
      };
      return diagonal({
        source: o,
        target: o
      });
    }).remove();
    nodes.forEach(function(d) {
      d.x0 = d.x;
      d.y0 = d.y;
    });
  };

  toggle = function(d) {
    if (d.children) {
      d._children = d.children;
      d.children = null;
    } else {
      d.children = d._children;
      d._children = null;
    }
  };

  d3.json('data/tree_040044985.json', function(json) {
    var node, toggleAll;
    this.json = json;
    this.tree = tree;
    toggleAll = function(d) {
      if (d.children) {
        d.children.forEach(toggleAll);
        toggle(d);
      }
    };
    root = json;
    root.x0 = w / 2;
    root.y0 = 0;
    node = root;
    while (node.children) {
      node = node.children[0];
      node.mainProg = true;
    }
    update(root);
  });

}).call(this);
