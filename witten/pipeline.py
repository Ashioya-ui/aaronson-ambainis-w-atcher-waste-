#!/usr/bin/env python3
"""Witten, arXiv:2611.05051, sections 3-4, run on his own setup:
gauge group SU(5), positive-chirality fermions in 5bar + 10 (one Standard Model generation),
on the 4-torus, with admissible lattice gauge fields.

Hybrid pipeline
  1. Leashed sampler over the admissible set A = {U : ||1 - U_P|| < eps for every plaquette}.
     Margin rule (our Lemma A, in Witten's setting): a link update R changes every plaquette
     containing the link by at most ||1 - R||, so a move with ||1 - R|| <= eps - max ||1 - U_P||
     cannot leave A. Moves beyond the margin are checked exactly and refused if they leave.
  2. Witten's continuum interpolation, section 3: on 1-cells the constant connection
     (an m-th root of the link), then on 2-, 3- and 4-cells the Dirichlet problem, solved as
     minimisation of the Yang-Mills (Wilson) action with the boundary fixed (his footnote 17).
     The continuum is a fine lattice, m points per lattice spacing.
  3. |det D+_W| through the Laplace-like operator D+^dag D+ (his section 4), compared with the
     naive lattice Weyl operator.
"""
import json, sys, time
import numpy as np
import scipy.linalg as la
import scipy.sparse as sp
import scipy.sparse.linalg as sla

NC = 5
RNG = np.random.default_rng(20261107)


# ---------------------------------------------------------------- SU(N) helpers
def dag(a):
    return np.conj(np.swapaxes(a, -1, -2))


def expm_ah(X):
    """exp of anti-Hermitian matrices (batched): exp(X) = exp(-iH), H = iX."""
    H = 1j * X
    H = 0.5 * (H + dag(H))
    w, v = np.linalg.eigh(H)
    return (v * np.exp(-1j * w)[..., None, :]) @ dag(v)


def proj_ta(M):
    A = 0.5 * (M - dag(M))
    n = M.shape[-1]
    tr = np.trace(A, axis1=-2, axis2=-1) / n
    return A - tr[..., None, None] * np.eye(n)


def reunit(W):
    u, _, vh = np.linalg.svd(W)
    U = u @ vh
    d = np.linalg.det(U)
    return U * np.exp(-1j * np.angle(d) / U.shape[-1])[..., None, None]


def dev(U):
    """||1 - U|| in operator norm, for unitary U (batched)."""
    return np.max(np.abs(1 - np.linalg.eigvals(U)), axis=-1)


def sh(a, mu, s=1):
    """sh(a, mu, s)[x] = a[x + s*mu] on the periodic lattice (axes 0..3 are x0..x3)."""
    return np.roll(a, -s, axis=mu)


def su_root(U, m):
    """m-th root of SU(N) matrices through the traceless logarithm (Schur, per matrix)."""
    flat = U.reshape(-1, NC, NC)
    out = np.empty_like(flat)
    for i, u in enumerate(flat):
        T, Z = la.schur(u, output="complex")
        th = np.angle(np.diag(T)).copy()
        k = int(np.rint(th.sum() / (2 * np.pi)))
        order = np.argsort(th)
        if k > 0:
            th[order[-k:]] -= 2 * np.pi
        elif k < 0:
            th[order[:-k]] += 2 * np.pi
        out[i] = (Z * np.exp(1j * th / m)) @ Z.conj().T
    return reunit(out.reshape(U.shape))


def haar_su(shape):
    z = (RNG.standard_normal(shape + (NC, NC)) + 1j * RNG.standard_normal(shape + (NC, NC))) / np.sqrt(2)
    q, r = np.linalg.qr(z)
    d = np.diagonal(r, axis1=-2, axis2=-1)
    return reunit(q * (d / np.abs(d))[..., None, :])


def rand_ah(n_links):
    h = RNG.standard_normal((n_links, NC, NC)) + 1j * RNG.standard_normal((n_links, NC, NC))
    h = 0.5 * (h + dag(h))
    h -= (np.trace(h, axis1=-2, axis2=-1) / NC)[:, None, None] * np.eye(NC)
    h /= np.sqrt(np.sum(np.abs(h) ** 2, axis=(-2, -1)))[:, None, None]
    return 1j * h


# ---------------------------------------------------------------- lattice gauge fields
def plaq(U, mu, nu):
    return U[mu] @ sh(U[nu], mu) @ dag(sh(U[mu], nu)) @ dag(U[nu])


def max_plaq_dev(U):
    return max(float(dev(plaq(U, mu, nu)).max()) for mu in range(4) for nu in range(mu + 1, 4))


def staples(U, mu):
    """The six staples of the links U[mu](x): tr(U_mu(x) S) is a plaquette containing it."""
    out = []
    for nu in range(4):
        if nu == mu:
            continue
        up = sh(U[nu], mu) @ dag(sh(U[mu], nu)) @ dag(U[nu])
        dn = dag(sh(sh(U[nu], mu), nu, -1)) @ dag(sh(U[mu], nu, -1)) @ sh(U[nu], nu, -1)
        out += [up, dn]
    return np.stack(out)


def leashed_sampler(U, beta, eps, sweeps, step):
    """Metropolis for the Wilson action restricted to the admissible set, with the margin rule."""
    L = U.shape[1]
    par = np.indices((L,) * 4).sum(0) % 2
    st = dict(proposals=0, accepted=0, refused_inadmissible=0, cleared_by_margin=0, checked_exactly=0)
    for _ in range(sweeps):
        for mu in range(4):
            for p in (0, 1):
                msk = par == p
                S = staples(U, mu)[:, msk]                 # (6, n, N, N)
                W = U[mu][msk]
                n = W.shape[0]
                R = expm_ah(step * rand_ah(n))
                Wn = R @ W
                dS = -(beta / NC) * np.real(np.trace((Wn - W) @ S.sum(0), axis1=-2, axis2=-1))
                margin = eps - dev(W[None] @ S).max(0)
                ok = dev(R) <= margin                       # cleared by the margin rule
                need = np.where(~ok)[0]
                if need.size:
                    ok[need] = (dev(Wn[need][None] @ S[:, need]) < eps).all(0)
                metro = RNG.random(n) < np.exp(np.minimum(0.0, -dS))
                acc = ok & metro
                W[acc] = Wn[acc]
                U[mu][msk] = W
                st["proposals"] += n
                st["accepted"] += int(acc.sum())
                st["refused_inadmissible"] += int((~ok & metro).sum())
                st["cleared_by_margin"] += n - need.size
                st["checked_exactly"] += int(need.size)
    return U, st


def landau(U, iters=3000, tol=1e-13):
    """Coarse Landau gauge: maximise sum Re tr U, so that links are close to 1 before taking roots."""
    L = U.shape[1]
    par = np.indices((L,) * 4).sum(0) % 2
    F_old = None
    for it in range(iters):
        for p in (0, 1):
            K = sum(U[mu] + dag(sh(U[mu], mu, -1)) for mu in range(4))
            g = reunit(dag(K))
            g[par != p] = np.eye(NC)
            for mu in range(4):
                U[mu] = g @ U[mu] @ dag(sh(g, mu))
        F = float(np.mean([np.real(np.trace(U[mu], axis1=-2, axis2=-1)).mean() for mu in range(4)]) / NC)
        if F_old is not None and abs(F - F_old) < tol:
            break
        F_old = F
    return U, F


def gauge_transform(U, g):
    return np.stack([g @ U[mu] @ dag(sh(g, mu)) for mu in range(4)])


# ---------------------------------------------------------------- Witten's interpolation (section 3)
def interpolate(Uc, m, tau=0.06, tol=1e-9, maxit=40000):
    L = Uc.shape[1]
    Lf = L * m
    W = np.broadcast_to(np.eye(NC, dtype=complex), (4,) + (Lf,) * 4 + (NC, NC)).copy()
    # 1-cells: the constant connection on each link (Witten: A = (i/a) log U)
    for mu in range(4):
        R = su_root(Uc[mu], m)
        for j in range(m):
            idx = [slice(0, Lf, m)] * 4
            idx[mu] = slice(j, Lf, m)
            W[(mu,) + tuple(idx)] = R
    off = np.indices((Lf,) * 4) % m != 0
    ld = [1 + sum(off[n] for n in range(4) if n != mu) for mu in range(4)]          # cell dimension of each link
    pd = {(mu, nu): 2 + sum(off[r] for r in range(4) if r not in (mu, nu))          # cell dimension of each plaquette
          for mu in range(4) for nu in range(4) if mu != nu}
    info = {}
    for k in (2, 3, 4):
        masks = [ld[mu] == k for mu in range(4)]
        up_m = {key: (v == k) for key, v in pd.items()}
        dn_m = {(mu, nu): sh(pd[(mu, nu)] == k, nu, -1) for (mu, nu) in pd}
        for it in range(maxit):
            newW = W.copy()
            maxZ = 0.0
            for mu in range(4):
                mk = masks[mu]
                if not mk.any():
                    continue
                A = np.zeros((int(mk.sum()), NC, NC), complex)
                for nu in range(4):
                    if nu == mu:
                        continue
                    up = (sh(W[nu], mu) @ dag(sh(W[mu], nu)) @ dag(W[nu]))[mk]
                    dn = (dag(sh(sh(W[nu], mu), nu, -1)) @ dag(sh(W[mu], nu, -1)) @ sh(W[nu], nu, -1))[mk]
                    A += up * up_m[(mu, nu)][mk][:, None, None] + dn * dn_m[(mu, nu)][mk][:, None, None]
                Wm = W[mu][mk]
                Z = proj_ta(Wm @ A)
                maxZ = max(maxZ, float(np.abs(Z).max()))
                newW[mu][mk] = expm_ah(-tau * Z) @ Wm
            W = newW
            if maxZ < tol:
                break
        info[k] = dict(iterations=it + 1, max_force=maxZ)
    return W, info


def holonomy_error(W, Uc, m):
    L = Uc.shape[1]
    err = 0.0
    for mu in range(4):
        P = np.broadcast_to(np.eye(NC, dtype=complex), (L,) * 4 + (NC, NC)).copy()
        for j in range(m):
            idx = [slice(0, L * m, m)] * 4
            idx[mu] = slice(j, L * m, m)
            P = P @ W[(mu,) + tuple(idx)]
        err = max(err, float(np.abs(P - Uc[mu]).max()))
    return err


def clover(W, mu, nu):
    P1 = W[mu] @ sh(W[nu], mu) @ dag(sh(W[mu], nu)) @ dag(W[nu])
    Wmm = sh(W[mu], mu, -1)
    P2 = W[nu] @ dag(sh(sh(W[mu], nu), mu, -1)) @ dag(sh(W[nu], mu, -1)) @ Wmm
    P3 = dag(Wmm) @ dag(sh(sh(W[nu], mu, -1), nu, -1)) @ sh(sh(W[mu], mu, -1), nu, -1) @ sh(W[nu], nu, -1)
    P4 = dag(sh(W[nu], nu, -1)) @ sh(W[mu], nu, -1) @ sh(sh(W[nu], mu), nu, -1) @ dag(W[mu])
    return P1 + P2 + P3 + P4


def field_strength(W, mu, nu):
    Q = clover(W, mu, nu)
    F = (Q - dag(Q)) / 8
    d = F.shape[-1]
    return F - (np.trace(F, axis1=-2, axis2=-1) / d)[..., None, None] * np.eye(d)


def top_charge(W):
    F = {(m, n): field_strength(W, m, n) for m in range(4) for n in range(m + 1, 4)}
    t = lambda a, b: np.real(np.trace(F[a] @ F[b], axis1=-2, axis2=-1)).sum()
    return float(-(t((0, 1), (2, 3)) - t((0, 2), (1, 3)) + t((0, 3), (1, 2))) / (4 * np.pi ** 2))


def fine_plaquette_traces(W):
    return np.stack([np.trace(plaq(W, mu, nu), axis1=-2, axis2=-1) for mu in range(4) for nu in range(mu + 1, 4)])


# ---------------------------------------------------------------- configurations
def flux_config(L, n12=1, n34=1):
    """SU(5) field with U(1) fluxes along H = diag(1,-1,0,0,0): instanton number tr(H^2) n12 n34 = 2."""
    H = np.diag([1.0, -1.0, 0, 0, 0])
    x = np.indices((L,) * 4)
    A = np.zeros((4,) + (L,) * 4)
    A[0] = np.where(x[0] == L - 1, -2 * np.pi * n12 * x[1] / L, 0.0)
    A[1] = 2 * np.pi * n12 * x[0] / L ** 2
    A[2] = np.where(x[2] == L - 1, -2 * np.pi * n34 * x[3] / L, 0.0)
    A[3] = 2 * np.pi * n34 * x[2] / L ** 2
    return np.exp(1j * A[..., None] * np.diag(H)) [..., None] * np.eye(NC)


# ---------------------------------------------------------------- fermions (section 4)
s1 = np.array([[0, 1], [1, 0]], complex)
s2 = np.array([[0, -1j], [1j, 0]], complex)
s3 = np.array([[1, 0], [0, -1]], complex)
I2 = np.eye(2, dtype=complex)
Z2 = np.zeros((2, 2), complex)
GAM = [np.block([[Z2, -1j * s], [1j * s, Z2]]) for s in (s1, s2, s3)] + [np.block([[Z2, I2], [I2, Z2]])]
for a in range(4):
    for b in range(4):
        assert np.allclose(GAM[a] @ GAM[b] + GAM[b] @ GAM[a], 2 * (a == b) * np.eye(4))
EPLUS = [1j * s1, 1j * s2, 1j * s3, I2]      # lower-left blocks: D21 = sum_mu EPLUS[mu] D_mu


def rep_links(W, rep):
    if rep == "5bar":
        return np.conj(W)
    pairs = [(i, j) for i in range(NC) for j in range(i + 1, NC)]
    I = np.array([p[0] for p in pairs])
    J = np.array([p[1] for p in pairs])
    return (W[..., I[:, None], I[None, :]] * W[..., J[:, None], J[None, :]]
            - W[..., I[:, None], J[None, :]] * W[..., J[:, None], I[None, :]])


def _assemble(blocks, V, nb):
    rows, cols, vals = [], [], []
    ar = np.arange(nb)
    for rs, cs, B in blocks:
        rows.append(np.broadcast_to(rs[:, None, None] * nb + ar[None, :, None], B.shape).ravel())
        cols.append(np.broadcast_to(cs[:, None, None] * nb + ar[None, None, :], B.shape).ravel())
        vals.append(B.ravel())
    return sp.csr_matrix((np.concatenate(vals), (np.concatenate(rows), np.concatenate(cols))), shape=(V * nb, V * nb))


def laplace_like(WR, chir):
    """D^dag D on one chirality, discretised as Laplacian - (1/2) sum [g_mu,g_nu] F_mu_nu (no doublers)."""
    d = WR.shape[-1]
    Lf = WR.shape[1]
    V = Lf ** 4
    nb = 2 * d
    S = np.arange(V).reshape((Lf,) * 4)
    x = S.ravel()
    diag = np.broadcast_to(8 * np.eye(nb, dtype=complex), (V, nb, nb)).copy()
    for mu in range(4):
        for nu in range(mu + 1, 4):
            G = GAM[mu] @ GAM[nu] - GAM[nu] @ GAM[mu]
            s = G[:2, :2] if chir == 0 else G[2:, 2:]
            F = field_strength(WR, mu, nu).reshape(V, d, d)
            diag -= 0.5 * np.einsum("ab,xij->xaibj", s, F).reshape(V, nb, nb)
    blocks = [(x, x, diag)]
    for mu in range(4):
        xp = sh(S, mu).ravel()
        B = -np.einsum("ab,xij->xaibj", I2, WR[mu].reshape(V, d, d)).reshape(V, nb, nb)
        blocks += [(x, xp, B), (xp, x, dag(B))]
    H = _assemble(blocks, V, nb)
    assert abs(H - H.conj().T).max() < 1e-10
    return H


def naive_weyl(WR):
    d = WR.shape[-1]
    Lf = WR.shape[1]
    V = Lf ** 4
    nb = 2 * d
    S = np.arange(V).reshape((Lf,) * 4)
    x = S.ravel()
    blocks = []
    for mu in range(4):
        xp = sh(S, mu).ravel()
        Wm = WR[mu].reshape(V, d, d)
        blocks += [(x, xp, 0.5 * np.einsum("ab,xij->xaibj", EPLUS[mu], Wm).reshape(V, nb, nb)),
                   (xp, x, -0.5 * np.einsum("ab,xij->xaibj", EPLUS[mu], dag(Wm)).reshape(V, nb, nb))]
    return _assemble(blocks, V, nb)


def lowest(H, k):
    if not isinstance(H, sla.LinearOperator):
        H = sla.aslinearoperator(H)
    vals = sla.eigsh(H, k=k, which="SA", tol=1e-7, ncv=min(H.shape[0] - 1, max(3 * k, 80)),
                     return_eigenvectors=False)
    return np.sort(vals)


def normal_op(D, adjoint_first=True):
    Dh = D.conj().T.tocsr()
    if adjoint_first:
        mv = lambda v: Dh @ (D @ v)
    else:
        mv = lambda v: D @ (Dh @ v)
    return sla.LinearOperator(D.shape, matvec=mv, dtype=complex)
