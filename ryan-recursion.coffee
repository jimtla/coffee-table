check = (cond, msg) ->
  throw new Error msg unless cond
checkEq = (a, b, msg) ->
  check b is a, "#{msg ? "-"}: #{b} isnt #{a}"
checkArrayEq = (a, b, msg) ->
  check "#{b}" is "#{a}", "#{msg ? "-"}: #{b} isnt #{a} (!!! HACKY !!!)"

buildGetNeighbors = (cliques) ->
  map = {}
  for clique in cliques
    for n in clique
      map[n] or= {}
      for m in clique when m isnt n
        map[n][m] = true
  (vertex) ->
    k for k of map[vertex] ? {}

shortestPathAssumingReachable = (start, end, getNeighbors) ->
  level = []
  tree = {}
  visit = (n, pathSoFar) ->
    unless tree[n]?
      tree[n] = [n]
      tree[n].unshift pathSoFar...
      level.push n
  visit start, []
  until tree[end]?
    parentLevel = level
    level = []
    for parent in parentLevel
      for n in getNeighbors parent
        visit n, tree[parent]
  tree[end]

do ->
  getNeighbors = buildGetNeighbors [[0, 1], [0, 2], [1, 3, 4], [2, 3]]
  checkArrayEq [1, 2], getNeighbors 0
  checkArrayEq [0, 3, 4], getNeighbors 1
  checkArrayEq [], getNeighbors 5
  checkArrayEq [0, 1, 4], shortestPathAssumingReachable 0, 4, getNeighbors

getRecursiveNeighbors = do ->
  T = ''  # top level of the diagram
  A = 'A'
  B = 'B'
  C = 'C'
  getNonRecursiveNeighbors = buildGetNeighbors [
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
  (recursiveVertex) ->
    vertex = recursiveVertex.split ','
    pos = vertex[1]
    stack = vertex[0]
    check stack.length > 0
    neighbors = {}
    addNeighbors = (nonRecursiveVertex, oldStack) ->
      for n in getNonRecursiveNeighbors nonRecursiveVertex
        n = n.split ','
        unless oldStack is '' and n[0] is T
          neighbors[[n[0] + oldStack, n[1]]] = true
    addNeighbors [T, pos], stack
    addNeighbors [stack[0], pos], stack[1..]
    k for k of neighbors

do ->
  expectNeighbors = (vertex, expected) ->
    actual = getRecursiveNeighbors vertex
    for n in expected
      check n in actual, "#{n} in (getRecursiveNeighbors #{vertex})"
    checkEq expected.length, actual.length, "[#{actual}] vs. [#{expected}]"
  expectNeighbors "A,0", ["AA,0", "A,14", "A,15"]
  expectNeighbors "AC,4", ["BAC,3", "C,2", "BC,6", "CC,0", "C,11" ]

console.log shortestPathAssumingReachable "C,9", "A,11", getRecursiveNeighbors
