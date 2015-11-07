margin = [
  20
  120
  20
  120
]

w = 1280 - (margin[1]) - (margin[3])
h = 800 - (margin[0]) - (margin[2])
i = 0
root = undefined

tree = d3.layout.tree().size([
  h
  w
])

diagonal = d3.svg.diagonal().projection((d) ->
  [
    d.x
    d.y
  ]
)

vis = d3.select('#body').append('svg:svg')
    .attr('width', w + margin[1] + margin[3])
    .attr('height', h + margin[0] + margin[2])
    .append('svg:g')
    .attr('transform', 'translate(' + margin[3] + ',' + margin[0] + ')')


update = (source) ->
  duration = if d3.event and d3.event.altKey then 5000 else 500

  # Compute the new tree layout.
  nodes = tree.nodes(root).reverse()

  # Count the longest tree branch nodes
  @maxDepth = 0
  nodes.forEach (d) =>
      if d.depth > @maxDepth
          @maxDepth = d.depth

  # Normalize for fixed-depth.
  nodes.forEach (d) ->
    d.y = d.depth * (h/@maxDepth)
    return

  # Update the nodes...
  node = vis.selectAll('g.node').data(nodes, (d) ->
    d.id or (d.id = ++i)
  )

  # Enter any new nodes at the parent's previous position.
  nodeEnter = node.enter().append('svg:g').attr('class', (d) -> 'node type'+d.Type)
    .attr('transform', (d) ->
      'translate(' + source.x0 + ',' + source.y0 + ')'
  ).on('click', (d) ->
    toggle d
    update d
    return
  )

  nodeEnter.append('svg:circle').attr('r', 1e-6).style 'fill', (d) ->
    if d._children then 'lightsteelblue' else '#fff'

  # nodeEnter.append('svg:text')
  #     .attr('y', 10)
  #     .attr('x', '1em')
  #     .attr('transform', 'rotate(45)')
  #     .text((d) -> d.ID).style 'fill-opacity', 1e-6

  # Transition nodes to their new position.
  nodeUpdate = node.transition().duration(duration)
      .attr('transform', (d) -> 'translate(' + d.x + ',' + d.y + ')'
  )

  nodeUpdate.select('circle').attr('r', 4.5).style 'fill', (d) ->
    if d._children then 'lightsteelblue' else '#fff'

  nodeUpdate.select('text').style 'fill-opacity', 1

  # Transition exiting nodes to the parent's new position.
  nodeExit = node.exit().transition()
      .duration(duration)
      .attr('transform', (d) -> 'translate(' + source.x + ',' + source.y + ')'
  ).remove()

  nodeExit.select('circle').attr 'r', 1e-6
  nodeExit.select('text').style 'fill-opacity', 1e-6

  # Update the links…
  link = vis.selectAll('path.link').data(tree.links(nodes), (d) ->
    d.target.id
  )

  # Enter any new links at the parent's previous position.
  link.enter().insert('svg:path', 'g').attr('class', 'link').attr('d', (d) ->
    o =
      x: source.x0
      y: source.y0
    diagonal
      source: o
      target: o
  ).transition().duration(duration).attr 'd', diagonal

  # Transition links to their new position.
  link.transition().duration(duration).attr 'd', diagonal

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


d3.json 'data/tree_040044985.json', (json) ->

  this.json = json
  toggleAll = (d) ->
    if d.children
      d.children.forEach toggleAll
      toggle d
    return

  root = json
  root.x0 = w / 2
  root.y0 = 0

  # Initialize the display to show a few nodes.
  # root.children.forEach toggleAll
  # toggle root.children[1]
  # toggle root.children[1].children[2]
  # toggle root.children[9]
  # toggle root.children[9].children[0]
  update root
  return
