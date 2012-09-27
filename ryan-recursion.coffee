check = (cond, msg) -> cond || throw new Error msg
checkEq = (a, b, msg) -> check b is a, "#{msg ? "-"}: #{b} isnt #{a}"
checkArrayEq = (a, b, msg) -> check "#{b}" is "#{a}", "#{msg ? "-"}: #{b} isnt #{a} (!!! HACKY !!!)"

buildGraph = (cliques) ->
  map = {}
  map[n] = {} for n in clique for clique in cliques
  map[n][m] = true for m in c when m isnt n for n in c for c in cliques
  return (vertex) -> (k for k, _ of map[vertex] ? {})

shortestPathAssumingReachable = (start, end, graph) ->
  level = []
  newLevel = () ->
    oldLevel = level
    level = []
    return oldLevel
  tree = {}
  seen = (n) -> tree[n] isnt undefined
  see = (n, pathSoFar) ->
    unless seen n
      tree[n] = [n]
      tree[n].unshift pathSoFar...
      level.push n
  see start, []
  see n, tree[parent] for n in graph parent for parent in newLevel() until seen end
  return tree[end]

(->
  graph = buildGraph [[0, 1], [0, 2], [1, 3, 4], [2, 3]]
  checkArrayEq [1, 2], graph 0
  checkArrayEq [0, 3, 4], graph 1
  checkArrayEq [], graph 5
  checkArrayEq [0, 1, 4], shortestPathAssumingReachable 0, 4, graph
)()

syllabus = (->
  T = 'T' # top level of the diagram
  A = 'A'
  B = 'B'
  C = 'C'
  diagram = buildGraph [
    [[T, 0], [A, 0], [T, 14], [T, 15]]
    [[T, 1], [A, 3]]
    [[T, 2], [A, 4], [B, 6], [C, 0], [T, 11]]
    [[T, 3], [B, 0]]
    [[T, 4], [B, 3]]
    [[T, 5], [B, 7]]
    [[T, 6], [A, 2], [C, 5]]
    [[T, 7], [T, 9], [A, 10], [T, 12]]
    [[T, 8], [B, 2]]
    [[T, 10], [T, 13], [A, 13]]
    [[A, 7], [B, 15]]
    [[A, 8], [C, 12]]
    [[A, 9], [A, 15]]
    [[B, 10], [C, 3]]
    [[B, 13], [C, 14]]
    [[C, 6], [C, 7]]
  ]
  (vertexString) ->
    vertex = vertexString.split ','
    pos = vertex[1]
    levels = vertex[0]
    check levels.length > 0
    neighbors = {}
    addNeighbors = (diagramVertex, levelsSuffix) ->
      for n in diagram diagramVertex
        n = n.split(',')
        newLevels = (if n[0] is T then '' else n[0]) + levelsSuffix
        neighbors[[newLevels, n[1]]] = true unless newLevels.length is 0
    addNeighbors [T, pos], levels
    addNeighbors [levels[0], pos], levels[1..]
    return (k for k, _ of neighbors)
)()
(->
  expectNeighbors = (vertex, expectedNeighbors) ->
    neighbors = syllabus vertex
    check n in neighbors, "#{n} in (syllabus #{vertex})" for n in expectedNeighbors
    checkEq expectedNeighbors.length, neighbors.length, "[#{neighbors}] vs. [#{expectedNeighbors}]"
  expectNeighbors "A,0", ["AA,0", "A,14", "A,15"]
  expectNeighbors "AC,4", ["BAC,3", "C,2", "BC,6", "CC,0", "C,11" ]
)()
console.log shortestPathAssumingReachable "C,9", "A,11", syllabus
