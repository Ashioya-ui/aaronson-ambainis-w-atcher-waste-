#!/usr/bin/env python3
"""Hybrid algorithm on Witten's setup (SU(5), fermions in 5bar + 10, admissible fields on T^4).

Primitives from the Aaronson-Ambainis repository, used where they satisfy the conditions of our
self-approaching paper:
  * rows (fractional certificates, Defs.lean / rowBoundPM): a change of the field is bounded by the
    weights of the coordinates moved. For admissibility the weights are ||1 - R|| per link, and with
    our margin lemma this is the leashed sampler (stages A and B).
  * MarkovEndpoint (RowDefs.lean, Lemma 6.1): |p'(0)| <= D^2 for p bounded by 1 on [0,2], and
    Chebyshev polynomials. Witten computes through D^dag D >= 0, whose zero modes sit at the endpoint
    0 of the spectrum, so MarkovEndpoint gives the least polynomial degree that can resolve them, and
    a Jackson-damped Chebyshev expansion attains it.
Craig's step: compare chiral projectors at successive lattice spacings (here m = 1 and m = 2).
Witten's section 3 claim checked directly: gauge-fixed links on a k-cube obey |U - 1| < (k-1) eps.
"""
import itertools, json, sys, time
import numpy as np
import scipy.sparse.linalg as sla
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pipeline import *

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "results") + "/"
out = {}
t0 = time.time()
rng = np.random.default_rng(7)


# ------------------------------------------------ Witten section 3: (k-1) eps on actual fields
def axial_bound(U):
    L = U.shape[1]
    verts = list(itertools.product((0, 1), repeat=4))
    worst, worst_ladder, n_links = 0.0, 0.0, 0
    for c in itertools.product(range(L), repeat=4):
        site = lambda v: tuple((c[i] + v[i]) % L for i in range(4))
        link = lambda v, mu: U[mu][site(v)]
        eps_cube = 0.0
        for v in verts:
            for mu in range(4):
                for nu in range(mu + 1, 4):
                    if v[mu] == 0 and v[nu] == 0:
                        vm = list(v); vm[mu] = 1
                        vn = list(v); vn[nu] = 1
                        P = link(v, mu) @ link(tuple(vm), nu) @ dag(link(tuple(vn), mu)) @ dag(link(v, nu))
                        eps_cube = max(eps_cube, float(dev(P)))
        g = {(0, 0, 0, 0): np.eye(NC, dtype=complex)}
        for w in sorted(verts, key=sum):
            if sum(w) == 0:
                continue
            mu = min(i for i in range(4) if w[i] == 1)
            p = list(w); p[mu] = 0; p = tuple(p)
            g[w] = g[p] @ link(p, mu)
        for v in verts:
            for mu in range(4):
                if v[mu] == 1:
                    continue
                vp = list(v); vp[mu] = 1; vp = tuple(vp)
                dv = float(dev(g[v] @ link(v, mu) @ dag(g[vp])))
                m = sum(v[i] for i in range(mu))
                if m == 0:
                    assert dv < 1e-9
                    continue
                n_links += 1
                worst = max(worst, dv / (3 * eps_cube))
                worst_ladder = max(worst_ladder, dv / (m * eps_cube))
    return dict(hypercubes=L ** 4, remaining_links=n_links,
                max_dev_over_3eps=worst, max_dev_over_ladder_eps=worst_ladder)


for name in ("U0", "U2"):
    out[f"witten_k_minus_1_bound_{name}"] = axial_bound(np.load(D + name + ".npy"))
print("axial done", round(time.time() - t0), flush=True)


# ------------------------------------------------ Craig: projectors at lattice spacings m = 1 and m = 2
U2 = np.load(D + "U2.npy")
W2 = np.load(D + "W2.npy")
L = U2.shape[1]
Lf = W2.shape[1]
coarse_in_fine = np.arange(Lf ** 4).reshape((Lf,) * 4)[::2, ::2, ::2, ::2].ravel()
craig = {}
for rep, expect in (("5bar", 2), ("10", 6)):
    d = 5 if rep == "5bar" else 10
    nb = 2 * d
    res = {}
    for chir in (0, 1):
        ev = np.linalg.eigvalsh(laplace_like(rep_links(U2, rep), chir).toarray())
        res[f"m1_chirality{chir}_lowest"] = [round(float(v), 5) for v in ev[: expect + 4]]
    Hc = laplace_like(rep_links(U2, rep), 1).toarray()
    evc, vc = np.linalg.eigh(Hc)
    Qc = vc[:, :expect]
    Hf = laplace_like(rep_links(W2, rep), 1)
    evf, vf = sla.eigsh(Hf, k=expect + 2, which="SA", tol=1e-9)
    order = np.argsort(evf)
    evf, vf = evf[order], vf[:, order]
    rows = (coarse_in_fine[:, None] * nb + np.arange(nb)[None, :]).ravel()
    Qf, _ = np.linalg.qr(vf[rows, :expect])
    cosines = np.linalg.svd(Qc.conj().T @ Qf, compute_uv=False)
    res["m2_lowest"] = [round(float(v), 5) for v in evf]
    res["principal_cosines_m1_vs_m2"] = [round(float(c), 6) for c in cosines]
    craig[rep] = res
out["craig_successive_spacings"] = craig
print("craig done", round(time.time() - t0), flush=True)


# ------------------------------------------------ Markov-certified Chebyshev count of zero modes
def jackson(N):
    k = np.arange(N + 1)
    return ((N - k + 1) * np.cos(np.pi * k / (N + 1)) + np.sin(np.pi * k / (N + 1)) / np.tan(np.pi / (N + 1))) / (N + 1)


def kpm_count(Hop, lam_top, E, N, nvec):
    """Number of eigenvalues below E: Jackson-damped Chebyshev expansion of the step, stochastic trace."""
    n = Hop.shape[0]
    X = lambda v: (2.0 / lam_top) * (Hop @ v) - v
    th = np.arccos(2 * E / lam_top - 1)
    c = np.empty(N + 1)
    c[0] = 1 - th / np.pi
    k = np.arange(1, N + 1)
    c[1:] = -2 * np.sin(k * th) / (k * np.pi)
    w = jackson(N) * c
    vals = []
    for _ in range(nvec):
        z = rng.choice([-1.0, 1.0], size=n).astype(complex)
        t_prev, t_cur = z, X(z)
        acc = w[0] * np.vdot(z, t_prev).real + w[1] * np.vdot(z, t_cur).real
        for j in range(2, N + 1):
            t_prev, t_cur = t_cur, 2 * X(t_cur) - t_prev
            acc += w[j] * np.vdot(z, t_cur).real
        vals.append(acc)
    vals = np.array(vals)
    return float(vals.mean()), float(vals.std(ddof=1) / np.sqrt(nvec))


def markov_min_degree(lam_top, width):
    """MarkovEndpoint: degree-N polynomial bounded by 1 on [0,2] has |p'| <= 2N^2 near 0, so dropping
    by 1 within width w of the endpoint (s-units 2w/lam_top) needs N >= sqrt(lam_top / (4 w))."""
    return int(np.ceil(np.sqrt(lam_top / (4 * width))))


stageC = json.load(open(D + "stage_C.json"))
kpm = {}
N, NVEC = 120, 24
for rep in ("5bar", "10"):
    WR = rep_links(W2, rep)
    r = {}
    ops = {"laplace_like_upper": laplace_like(WR, 0), "laplace_like_lower": laplace_like(WR, 1)}
    Dn = naive_weyl(WR)
    ops["naive_upper"] = normal_op(Dn, True)
    ops["naive_lower"] = normal_op(Dn, False)
    for key, Hop in ops.items():
        low = np.array(stageC[rep][key]["lowest"])
        nz = stageC[rep][key]["near_zero"]
        top = float(sla.eigsh(Hop if isinstance(Hop, sla.LinearOperator) else sla.aslinearoperator(Hop),
                              k=1, which="LA", tol=1e-4, return_eigenvectors=False)[0]) * 1.02
        lo_edge = float(low[nz - 1]) if nz > 0 else 0.0
        hi_edge = float(low[nz])
        E = 0.5 * (lo_edge + hi_edge)
        cnt, err = kpm_count(Hop, top, E, N, NVEC)
        r[key] = dict(count=round(cnt, 3), stat_error=round(err, 3), exact=nz, E=round(E, 4),
                      spectrum_top=round(top, 3), gap=round(hi_edge - lo_edge, 4),
                      degree_used=N, markov_min_degree=markov_min_degree(top, hi_edge - lo_edge))
        print(rep, key, r[key], round(time.time() - t0), flush=True)
    r["index_laplace_like"] = round(r["laplace_like_lower"]["count"] - r["laplace_like_upper"]["count"], 3)
    r["index_naive"] = round(r["naive_lower"]["count"] - r["naive_upper"]["count"], 3)
    kpm[rep] = r
out["markov_chebyshev_counts"] = kpm
out["seconds"] = round(time.time() - t0, 1)
json.dump(out, open(D + "hybrid.json", "w"), indent=1)
print(json.dumps(out, indent=1))
