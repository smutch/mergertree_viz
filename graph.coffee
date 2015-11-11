# Set up margins and canvas size
margin = [
  20
  120
  20
  120
]
w = 1280 - (margin[1]) - (margin[3])
h = 800 - (margin[0]) - (margin[2])

# Init variables
i = 0
root = undefined
nodeRadius = 4.5

# Create the tree layout
tree = d3.layout.tree().size([
  h
  w
])

# define diagonal projection for the tree
diagonal = d3.svg.diagonal().projection((d) ->
  [
    d.x
    d.y
  ]
)

# create the visualisation
vis = d3.select('#body').append('svg:svg')
    .attr('width', w + margin[1] + margin[3])
    .attr('height', h + margin[0] + margin[2])
    .append('svg:g')
    .attr('transform', 'translate(' + margin[3] + ',' + margin[0] + ')')


# Set the node fill color based on properties
nodeFillColor = (d) ->
  if d._children
    if d.GhostFlag
      '#aaa'
    else
      'lightsteelblue'
  else
      '#fff'


# calculate statistics for the visible tree at each update
calcGraphStats = (nodes) ->
  maxDepth = 0
  minSnap = 99999
  maxSnap = -1
  for d in nodes
    if d.depth > maxDepth then maxDepth = d.depth
    snap = Number d.name.split('|')[0]
    if snap > maxSnap then maxSnap = snap
    if snap < minSnap then minSnap = snap
  [maxDepth, minSnap, maxSnap]


toggleTag = (node, tag) ->
    node[tag] = if node[tag] then false else true

# tag a first progenitor line
toggleFirstProgLineTag = (selNode, tag) ->
  toggleTag(selNode, tag)

  node = selNode
  while node.parent
    node = node.parent
    toggleTag(node, tag)

  node = selNode
  while node.children
    node = node.children[0]
    toggleTag(node, tag)


# format galaxy property string
propertyString = (param, value, unit) ->
  '<span class="param">'+param+'</span> = '+value+' '+'<span class="unit">'+unit+'</span>'

# create our tooltip handler
tip = d3.tip()
  .attr('class', 'd3-tip')
  .html((d) ->
    result = ''
    # ID
    result += propertyString('ID', d.ID, '') + '<br>'
    # Type
    result += propertyString('Type', d.Type, '') + '<br>'
    # Len
    result += propertyString('N<sub>p</sub>', d.Len, '') + '<br>'
    # Mvir
    result += propertyString('M<sub>vir</sub>',
      '10<sup>'+Math.log10(d.Mvir * 1e10).toFixed(2)+'</sup>',
      'M<sub>☉</sub>')+ '<br>'
    # StellarMass
    if d.StellarMass is 0
      value = '0'
    else
      value = '10<sup>'+Math.log10(d.StellarMass * 1e10).toFixed(2)+'</sup>'
    result += propertyString('M<sub>*</sub>', value,
      'M<sub>☉</sub>') + '<br>'
    # SFR
    result += propertyString('M<sub>*</sub>',
      d.Sfr.toFixed(2),
      'M<sub>☉</sub>/yr')
    result
  )
  .offset([-2, 0])
vis.call tip

# workhorse function which is used to place nodes, paths and deal with transitions
update = (source) ->
  duration = if d3.event and d3.event.altKey then 5000 else 500

  # Compute the new tree layout.
  nodes = tree.nodes(root).reverse()

  # calculate statistics for the visible tree at each update
  [maxDepth, minSnap, maxSnap] = calcGraphStats nodes

  # normalize positions for fixed-depth
  nodes.forEach (d) -> d.y = d.depth * (h/maxDepth)

  # Enter any new snapshot lines
  if (maxSnap - minSnap + 1) > 50
    snaps = []
    [maxSnap..minSnap].map((v) -> if !(v % 2) then snaps.push(v))
    snapEvery = 2
  else
    snaps = [maxSnap..minSnap]
    snapEvery = 1
  snapLines = vis.selectAll('g.snapLine').data(snaps, (d, i) -> d.valueOf())
  snapLinesEnter = snapLines.enter()
    .append('svg:g')
    .attr('class', 'snapLine')

  ySnapLine = (d, i) ->
    i * (h/(maxSnap-minSnap)) * snapEvery

  snapLinesEnter.append('svg:line')
    .attr('x1', 0)
    .attr('x2', w)
    .attr('y1', ySnapLine)
    .attr('y2', ySnapLine)
    .style('stroke', '#aaa')
    .style('stroke-width', 1)
    .style('stroke-opacity', 0)

  snapLinesEnter.append('svg:text')
    .attr('y', ySnapLine)
    .attr('x', '0')
    .attr('dx', '-5')
    .attr('dy', '.35em')
    .text((d) -> d.valueOf())
    .style('fill-opacity', 0)

  # Update snaplines
  snapLines.select('line').transition().duration(duration)
    .attr('y1', ySnapLine)
    .attr('y2', ySnapLine)
    .style('stroke-opacity', 0.2)

  snapLines.select('text').transition().duration(duration)
    .attr('y', ySnapLine)
    .style('fill-opacity', 0.2)

  # exit snaplines
  snapExit = snapLines.exit().transition().duration(duration).remove()
  snapExit.select('line').style('stroke-opacity', 0)
  snapExit.select('text').style('fill-opacity', 0)

  # Update the nodes...
  node = vis.selectAll('g.node').data(nodes, (d) ->
    d.id or (d.id = ++i)
  )

  # Enter any new nodes at the parent's previous position.
  nodeEnter = node.enter().append('svg:g').attr('class', (d) ->
    cls = 'node type'+d.Type
    if d.GhostFlag then cls+=' ghost'
    cls
  )

  nodeEnter.attr('transform', (d) ->
    if d.Type is 0
      'translate(' + source.x0 + ',' + source.y0 + ')'
    else
      'translate(' + (source.x0 - nodeRadius) + ',' + (source.y0 - nodeRadius) + ')'
  ).on('click', (d) ->
    toggle d
    update d
  ).on('mouseover', (d) ->
    if d3.event and d3.event.shiftKey
      tip.show d
    toggleFirstProgLineTag d, 'hlProg'
    update d
  )
  .on('mouseout', (d) ->
    tip.hide d
    toggleFirstProgLineTag d, 'hlProg'
    update d
  )

  nodeEnter.filter( (d) -> d.Type is 0 ).append('svg:circle').attr('r', 1e-6).style 'fill', nodeFillColor
  nodeEnter.filter( (d) -> d.Type > 0 ).append('svg:rect')
      .attr('width', 1e-6).attr('height', 1e-6).style 'fill', nodeFillColor

  # nodeEnter.append('svg:text')
  #     .attr('y', 10)
  #     .attr('x', '1em')
  #     .attr('transform', 'rotate(45)')
  #     .text((d) -> d.ID).style 'fill-opacity', 1e-6

  # Transition nodes to their new position.
  nodeUpdate = node.transition().duration(duration).attr('transform', (d) ->
    if d.Type is 0
        'translate(' + d.x + ',' + d.y + ')'
    else
        'translate(' + (d.x - nodeRadius) + ',' + (d.y - nodeRadius) + ')'
  )

  nodeUpdate.select('circle').attr('r', nodeRadius).style 'fill', nodeFillColor
  nodeUpdate.select('rect').attr('width', 2*nodeRadius).attr('height', 2*nodeRadius)
      .style 'fill', nodeFillColor

  # nodeUpdate.select('text').style 'fill-opacity', 1

  # Transition exiting nodes to the parent's new position.
  nodeExit = node.exit().transition()
      .duration(duration)
      .attr('transform', (d) -> 'translate(' + source.x + ',' + source.y + ')'
  ).remove()

  nodeExit.select('circle').attr 'r', 1e-6
  nodeExit.select('rect').attr('width', 1e-6).attr('height', 1e-6)
  # nodeExit.select('text').style 'fill-opacity', 1e-6

  # Update the links…
  link = vis.selectAll('path.link').data(tree.links(nodes), (d) ->
    d.target.id
  )

  # Enter any new links at the parent's previous position.
  linkEnter = link.enter().insert('svg:path', 'g').attr('class', 'link').attr('d', (d) ->
    o =
      x: source.x0
      y: source.y0
    diagonal
      source: o
      target: o
  )

  linkEnter.transition().duration(duration).attr 'd', diagonal

  # Transition links to their new position.
  link.transition().duration(duration).attr('d', diagonal)
    .style 'stroke', (d) ->
      if d.target.mainProg
        '#000'
      else if d.target.hlProg
        'red'
      else
        '#ccc'

  # Transition exiting nodes to the parent's new position.
  link.exit().transition().duration(duration).attr('d', (d) ->
    o =
      x: source.x
      y: source.y
    diagonal
      source: o
      target: o
  ).remove()

  # Stash the old positions for transition.
  nodes.forEach (d) ->
    d.x0 = d.x
    d.y0 = d.y
    return
  return


# Toggle children.
toggle = (d) ->
  if d.children
    d._children = d.children
    d.children = null
  else
    d.children = d._children
    d._children = null
  return

# Open all children of nodes below
openAll = (d) ->
  if d._children
    d.children = d._children
    d._children = null
  if d.children
    d.children.forEach openAll

# 'main' function for the tree visualisation using a json file as input
d3.json 'data/tree_040044985.json', (json) ->

  # Let's make these available for debugging...
  @json = json
  @tree = tree

  toggleAll = (d) ->
    if d.children
      d.children.forEach toggleAll
      toggle d
    return

  # define the root and place it
  root = json
  root.x0 = w / 2
  root.y0 = 0

  # Uniquely identify the main progenitor branch
  toggleFirstProgLineTag root, 'mainProg'

  # Initialize the display to show a few nodes.
  # root.children.forEach toggleAll
  # toggle root.children[1]
  # toggle root.children[1].children[2]
  # toggle root.children[9]
  # toggle root.children[9].children[0]
  update root

# 'global' key events
window.addEventListener "keydown", (event) ->
  if event.defaultPrevented
    return # Should do nothing if the key event was already consumed.
  else
    keyCode = if event.which then event.which else event.keyCode
    if keyCode is 65
      openAll root
      update root
