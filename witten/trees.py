import itertools, random, time
import numpy as np
def cube(k):
    V = list(range(2 ** k))
    E = [(v, v | (1 << i)) for v in V for i in range(k) if not v >> i & 1]
    return V, E
def stretch(k, T):
    adj = {v: [] for v in range(2 ** k)}
    for a, b in T:
        adj[a].append(b); adj[b].append(a)
    def dist(s):
        d = {s: 0}; q = [s]
        for x in q:
            for y in adj[x]:
                if y not in d:
                    d[y] = d[x] + 1; q.append(y)
        return d
    D = {v: dist(v) for v in range(2 ** k)}
    return max(D[a][b] for a, b in cube(k)[1] if (a, b) not in T)
def random_tree(k, rng):
    V, E = cube(k); w = rng.random(len(E)); parent = list(V)
    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]; x = parent[x]
        return x
    T = set()
    for i in np.argsort(w):
        a, b = E[i]; ra, rb = find(a), find(b)
        if ra != rb:
            parent[ra] = rb; T.add(E[i])
    return T
def axial(k):
    return {(v, v | (1 << mu)) for v in range(2 ** k) for mu in range(k)
            if not v >> mu & 1 and all(not v >> i & 1 for i in range(mu))}
rng = np.random.default_rng(1)
out = {}
for k in (3, 4):
    out[f"axial_k{k}"] = stretch(k, axial(k))
# exhaustive for k = 3: all spanning trees among 7-subsets of the 12 edges
V, E = cube(3); best3 = 99; n3 = 0
for S in itertools.combinations(E, 7):
    parent = list(range(8))
    def find(x):
        while parent[x] != x: x = parent[x]
        return x
    ok = True
    for a, b in S:
        ra, rb = find(a), find(b)
        if ra == rb: ok = False; break
        parent[ra] = rb
    if ok:
        n3 += 1; best3 = min(best3, stretch(3, set(S)))
out["k3_spanning_trees"] = n3; out["k3_min_stretch"] = best3
# k = 4: random spanning trees plus edge-swap descent
t0 = time.time(); best4 = 99; tried = 0
V, E = cube(4)
while time.time() - t0 < 150:
    T = random_tree(4, rng); s = stretch(4, T); tried += 1
    for _ in range(60):
        e_out = list(T)[rng.integers(len(T))]
        cand = [e for e in E if e not in T]
        e_in = cand[rng.integers(len(cand))]
        T2 = (T - {e_out}) | {e_in}
        if len(T2) == 15 and len({v for e in T2 for v in e}) == 16:
            try:
                s2 = stretch(4, T2)
            except KeyError:
                continue
            if s2 <= s:
                T, s = T2, s2
    best4 = min(best4, s)
out["k4_trees_searched"] = tried; out["k4_min_stretch_found"] = best4
print(out)
