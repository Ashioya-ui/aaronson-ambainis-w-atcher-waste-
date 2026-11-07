#!/usr/bin/env python3
import sys, json, time
import numpy as np
import os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pipeline import *

D = os.path.join(os.path.dirname(os.path.abspath(__file__)), "results") + "/"
stage = sys.argv[1]
out = {"stage": stage}
t0 = time.time()

if stage == "A":   # instanton number 0: sample, interpolate, check Witten's section-3 claims
    L, m = 4, 2
    U = np.broadcast_to(np.eye(NC, dtype=complex), (4,) + (L,) * 4 + (NC, NC)).copy()
    U, st = leashed_sampler(U, beta=120.0, eps=0.35, sweeps=60, step=0.2)
    out["sampler"] = st
    out["coarse_max_plaquette_dev"] = max_plaq_dev(U)
    np.save(D + "U0.npy", U)
    U1, _ = landau(U.copy())
    W1, info = interpolate(U1, m)
    out["interp_landau"] = info
    out["holonomy_error"] = holonomy_error(W1, U1, m)
    out["fine_max_dev_times_m2"] = max_plaq_dev(W1) * m * m
    out["Q"] = top_charge(W1)
    g = haar_su((L,) * 4)
    Ug = gauge_transform(U, g)
    U2, _ = landau(Ug.copy())
    W2, info2 = interpolate(U2, m)
    out["gauge_cov_after_landau_max_diff"] = float(np.abs(fine_plaquette_traces(W1) - fine_plaquette_traces(W2)).max())
    out["Q_after_gauge_transform"] = top_charge(W2)
    W3, info3 = interpolate(Ug.copy(), m)
    out["interp_raw_haar_gauge"] = info3
    out["gauge_cov_raw_haar_max_diff"] = float(np.abs(fine_plaquette_traces(W1) - fine_plaquette_traces(W3)).max())
    out["holonomy_error_raw"] = holonomy_error(W3, Ug, m)
    np.save(D + "W0.npy", W1)

elif stage == "B":  # instanton number 2: flux background plus admissible fluctuations
    L, m = 4, 2
    U = flux_config(L)
    out["flux_only_max_plaquette_dev"] = max_plaq_dev(U)
    U, st = leashed_sampler(U, beta=200.0, eps=0.6, sweeps=60, step=0.15)
    out["sampler"] = st
    out["coarse_max_plaquette_dev"] = max_plaq_dev(U)
    np.save(D + "U2.npy", U)
    W, info = interpolate(U, m)
    out["interp"] = info
    out["holonomy_error"] = holonomy_error(W, U, m)
    out["fine_max_dev_times_m2"] = max_plaq_dev(W) * m * m
    out["Q"] = top_charge(W)
    np.save(D + "W2.npy", W)

elif stage == "C":  # fermions in 5bar + 10 on the instanton-number-2 field
    W = np.load(D + "W2.npy")
    thr = 0.05
    for rep, expect in (("5bar", 2), ("10", 6)):
        WR = rep_links(W, rep)
        res = {}
        for chir, name in ((0, "upper"), (1, "lower")):
            ev = lowest(laplace_like(WR, chir), expect + 6)
            res["laplace_like_" + name] = dict(near_zero=int((ev < thr).sum()), lowest=[round(float(v), 5) for v in ev])
        Dn = naive_weyl(WR)
        k = 16 * expect // 2 + 8
        for adj, name in ((True, "upper"), (False, "lower")):
            ev = lowest(normal_op(Dn, adj), k)
            res["naive_" + name] = dict(near_zero=int((ev < thr).sum()), lowest=[round(float(v), 5) for v in ev])
        out[rep] = res
        print(rep, json.dumps({k2: v["near_zero"] for k2, v in res.items()}), flush=True)

out["seconds"] = round(time.time() - t0, 1)
json.dump(out, open(D + f"stage_{stage}.json", "w"), indent=1)
print(json.dumps(out, indent=1))
