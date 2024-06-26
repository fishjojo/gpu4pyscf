template <int NROOTS, int GSIZE> __global__
void GINTfill_int3c2e_ip1ip2_kernel(GINTEnvVars envs, ERITensor eri, BasisProdOffsets offsets)
{
    int ntasks_ij = offsets.ntasks_ij;
    int ntasks_kl = offsets.ntasks_kl;
    int task_ij = blockIdx.x * blockDim.x + threadIdx.x;
    int task_kl = blockIdx.y * blockDim.y + threadIdx.y;

    if (task_ij >= ntasks_ij || task_kl >= ntasks_kl) {
        return;
    }
    double norm = envs.fac;
    int bas_ij = offsets.bas_ij + task_ij;
    int bas_kl = offsets.bas_kl + task_kl;
    int nprim_ij = envs.nprim_ij;
    int nprim_kl = envs.nprim_kl;
    int prim_ij = offsets.primitive_ij + task_ij * nprim_ij;
    int prim_kl = offsets.primitive_kl + task_kl * nprim_kl;
    int *bas_pair2bra = c_bpcache.bas_pair2bra;
    int *bas_pair2ket = c_bpcache.bas_pair2ket;
    int ish = bas_pair2bra[bas_ij];
    int jsh = bas_pair2ket[bas_ij];
    int ksh = bas_pair2bra[bas_kl];
    int lsh = bas_pair2ket[bas_kl];

    double g0[4*GSIZE];
    double *g1 = g0 + GSIZE;
    double *g2 = g1 + GSIZE;
    double *g3 = g2 + GSIZE;
    double* __restrict__ exp_bra = c_bpcache.a1;
    int ij, kl;
    int as_ish, as_jsh, as_ksh, as_lsh;
    if (envs.ibase) {
        as_ish = ish;
        as_jsh = jsh;
    } else {
        as_ish = jsh;
        as_jsh = ish;
    }
    if (envs.kbase) {
        as_ksh = ksh;
        as_lsh = lsh;
    } else {
        as_ksh = lsh;
        as_lsh = ksh;
    }
    for (ij = prim_ij; ij < prim_ij+nprim_ij; ++ij) {
        for (kl = prim_kl; kl < prim_kl+nprim_kl; ++kl) {
            GINTg0_2e_2d4d<NROOTS>(envs, g0, norm, as_ish, as_jsh, as_ksh, as_lsh, ij, kl);

            double ai2 = -2.0*exp_bra[ij];
            double ak2 = -2.0*exp_bra[kl];
            GINTnabla1k_2e<NROOTS>(envs, g1, g0, ak2, envs.i_l+1, envs.j_l, envs.k_l);
            GINTnabla1i_2e<NROOTS>(envs, g2, g0, ai2, envs.i_l,   envs.j_l, envs.k_l);
            GINTnabla1i_2e<NROOTS>(envs, g3, g1, ai2, envs.i_l,   envs.j_l, envs.k_l);
            GINTwrite_int3c2e_ipip_direct<NROOTS>(envs, eri, g0, g1, g2, g3, ish, jsh, ksh);
    } }
}
