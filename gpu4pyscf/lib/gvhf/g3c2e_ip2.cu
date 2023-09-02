/* Copyright 2023 The GPU4PySCF Authors. All Rights Reserved.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
 

template <int NROOTS, int GSIZE> __global__
static void GINTint3c2e_ip2_jk_kernel(GINTEnvVars envs, JKMatrix jk, BasisProdOffsets offsets){
    return;
}


#if POLYFIT_ORDER_IP >= 2
template <> __global__
void GINTint3c2e_ip2_jk_kernel<2,GSIZE2_INT3C>(GINTEnvVars envs, JKMatrix jk, BasisProdOffsets offsets)
{
    int ntasks_ij = offsets.ntasks_ij;
    int ntasks_kl = offsets.ntasks_kl;
    int task_ij = blockIdx.x * blockDim.x + threadIdx.x;
    int task_kl = blockIdx.y * blockDim.y + threadIdx.y;
    bool active = true;
    if (task_ij >= ntasks_ij || task_kl >= ntasks_kl) {
        active = false;
        task_ij = 0;
        task_kl = 0;
    }

    int bas_ij = offsets.bas_ij + task_ij;
    int bas_kl = offsets.bas_kl + task_kl;
    double norm = envs.fac;
    double omega = envs.omega;
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
    double* __restrict__ exp = c_bpcache.a1;
    double uw[4];
    double g[2*GSIZE2_INT3C];
    double *f = g + GSIZE2_INT3C;
    
    double* __restrict__ a12 = c_bpcache.a12;
    double* __restrict__ x12 = c_bpcache.x12;
    double* __restrict__ y12 = c_bpcache.y12;
    double* __restrict__ z12 = c_bpcache.z12;

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
    
    double j3[GPU_CART_MAX * 3];
    double k3[GPU_CART_MAX * 3];
    for (int k = 0; k < GPU_CART_MAX * 3; k++){
        j3[k] = 0.0;
        k3[k] = 0.0;
    }
    if (active) {
        for (ij = prim_ij; ij < prim_ij+nprim_ij; ++ij) {
            for (kl = prim_kl; kl < prim_kl+nprim_kl; ++kl) {
                            
            double aij = a12[ij];
            double xij = x12[ij];
            double yij = y12[ij];
            double zij = z12[ij];
            double akl = a12[kl];
            double xkl = x12[kl];
            double ykl = y12[kl];
            double zkl = z12[kl];
            double xijxkl = xij - xkl;
            double yijykl = yij - ykl;
            double zijzkl = zij - zkl;
            double aijkl = aij + akl;
            double a1 = aij * akl;
            double a0 = a1 / aijkl;
            double theta = omega > 0.0 ? omega * omega / (omega * omega + a0) : 1.0; 
            a0 *= theta;
            double x = a0 * (xijxkl * xijxkl + yijykl * yijykl + zijzkl * zijzkl);
                GINTrys_root2(x, uw);
                GINTscale_u<2>(uw, theta);
                GINTg0_2e_2d4d<2>(envs, g, uw, norm, as_ish, as_jsh, as_ksh, as_lsh, ij, kl);
                
            double ak2 = -2.0*exp[kl];
            GINTnabla1k_2e<2>(envs, f, g, ak2, envs.i_l, envs.j_l, envs.k_l);
                GINTkernel_int3c2e_ip2_getjk_direct<2>(envs, jk, j3, k3, f, g, ish, jsh, ksh);
            } 
        }
    }
    
    write_int3c2e_ip2_jk(jk, j3, k3, ksh);
}
#endif 

#if POLYFIT_ORDER_IP >= 3
template <> __global__
void GINTint3c2e_ip2_jk_kernel<3,GSIZE3_INT3C>(GINTEnvVars envs, JKMatrix jk, BasisProdOffsets offsets)
{
    int ntasks_ij = offsets.ntasks_ij;
    int ntasks_kl = offsets.ntasks_kl;
    int task_ij = blockIdx.x * blockDim.x + threadIdx.x;
    int task_kl = blockIdx.y * blockDim.y + threadIdx.y;
    bool active = true;
    if (task_ij >= ntasks_ij || task_kl >= ntasks_kl) {
        active = false;
        task_ij = 0;
        task_kl = 0;
    }

    int bas_ij = offsets.bas_ij + task_ij;
    int bas_kl = offsets.bas_kl + task_kl;
    double norm = envs.fac;
    double omega = envs.omega;
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
    double* __restrict__ exp = c_bpcache.a1;
    double uw[6];
    double g[2*GSIZE3_INT3C];
    double *f = g + GSIZE3_INT3C;
    
    double* __restrict__ a12 = c_bpcache.a12;
    double* __restrict__ x12 = c_bpcache.x12;
    double* __restrict__ y12 = c_bpcache.y12;
    double* __restrict__ z12 = c_bpcache.z12;

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
    
    double j3[GPU_CART_MAX * 3];
    double k3[GPU_CART_MAX * 3];
    for (int k = 0; k < GPU_CART_MAX * 3; k++){
        j3[k] = 0.0;
        k3[k] = 0.0;
    }
    if (active) {
        for (ij = prim_ij; ij < prim_ij+nprim_ij; ++ij) {
            for (kl = prim_kl; kl < prim_kl+nprim_kl; ++kl) {
                            
            double aij = a12[ij];
            double xij = x12[ij];
            double yij = y12[ij];
            double zij = z12[ij];
            double akl = a12[kl];
            double xkl = x12[kl];
            double ykl = y12[kl];
            double zkl = z12[kl];
            double xijxkl = xij - xkl;
            double yijykl = yij - ykl;
            double zijzkl = zij - zkl;
            double aijkl = aij + akl;
            double a1 = aij * akl;
            double a0 = a1 / aijkl;
            double theta = omega > 0.0 ? omega * omega / (omega * omega + a0) : 1.0; 
            a0 *= theta;
            double x = a0 * (xijxkl * xijxkl + yijykl * yijykl + zijzkl * zijzkl);
                GINTrys_root3(x, uw);
                GINTscale_u<3>(uw, theta);
                GINTg0_2e_2d4d<3>(envs, g, uw, norm, as_ish, as_jsh, as_ksh, as_lsh, ij, kl);
                
            double ak2 = -2.0*exp[kl];
            GINTnabla1k_2e<3>(envs, f, g, ak2, envs.i_l, envs.j_l, envs.k_l);
                GINTkernel_int3c2e_ip2_getjk_direct<3>(envs, jk, j3, k3, f, g, ish, jsh, ksh);
            } 
        }
    }
    
    write_int3c2e_ip2_jk(jk, j3, k3, ksh);
}
#endif 

#if POLYFIT_ORDER_IP >= 4
template <> __global__
void GINTint3c2e_ip2_jk_kernel<4,GSIZE4_INT3C>(GINTEnvVars envs, JKMatrix jk, BasisProdOffsets offsets)
{
    int ntasks_ij = offsets.ntasks_ij;
    int ntasks_kl = offsets.ntasks_kl;
    int task_ij = blockIdx.x * blockDim.x + threadIdx.x;
    int task_kl = blockIdx.y * blockDim.y + threadIdx.y;
    bool active = true;
    if (task_ij >= ntasks_ij || task_kl >= ntasks_kl) {
        active = false;
        task_ij = 0;
        task_kl = 0;
    }

    int bas_ij = offsets.bas_ij + task_ij;
    int bas_kl = offsets.bas_kl + task_kl;
    double norm = envs.fac;
    double omega = envs.omega;
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
    double* __restrict__ exp = c_bpcache.a1;
    double uw[8];
    double g[2*GSIZE4_INT3C];
    double *f = g + GSIZE4_INT3C;
    
    double* __restrict__ a12 = c_bpcache.a12;
    double* __restrict__ x12 = c_bpcache.x12;
    double* __restrict__ y12 = c_bpcache.y12;
    double* __restrict__ z12 = c_bpcache.z12;

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
    
    double j3[GPU_CART_MAX * 3];
    double k3[GPU_CART_MAX * 3];
    for (int k = 0; k < GPU_CART_MAX * 3; k++){
        j3[k] = 0.0;
        k3[k] = 0.0;
    }
    if (active) {
        for (ij = prim_ij; ij < prim_ij+nprim_ij; ++ij) {
            for (kl = prim_kl; kl < prim_kl+nprim_kl; ++kl) {
                            
            double aij = a12[ij];
            double xij = x12[ij];
            double yij = y12[ij];
            double zij = z12[ij];
            double akl = a12[kl];
            double xkl = x12[kl];
            double ykl = y12[kl];
            double zkl = z12[kl];
            double xijxkl = xij - xkl;
            double yijykl = yij - ykl;
            double zijzkl = zij - zkl;
            double aijkl = aij + akl;
            double a1 = aij * akl;
            double a0 = a1 / aijkl;
            double theta = omega > 0.0 ? omega * omega / (omega * omega + a0) : 1.0; 
            a0 *= theta;
            double x = a0 * (xijxkl * xijxkl + yijykl * yijykl + zijzkl * zijzkl);
                GINTrys_root4(x, uw);
                GINTscale_u<4>(uw, theta);
                GINTg0_2e_2d4d<4>(envs, g, uw, norm, as_ish, as_jsh, as_ksh, as_lsh, ij, kl);
                
            double ak2 = -2.0*exp[kl];
            GINTnabla1k_2e<4>(envs, f, g, ak2, envs.i_l, envs.j_l, envs.k_l);
                GINTkernel_int3c2e_ip2_getjk_direct<4>(envs, jk, j3, k3, f, g, ish, jsh, ksh);
            } 
        }
    }
    
    write_int3c2e_ip2_jk(jk, j3, k3, ksh);
}
#endif 

#if POLYFIT_ORDER_IP >= 5
template <> __global__
void GINTint3c2e_ip2_jk_kernel<5,GSIZE5_INT3C>(GINTEnvVars envs, JKMatrix jk, BasisProdOffsets offsets)
{
    int ntasks_ij = offsets.ntasks_ij;
    int ntasks_kl = offsets.ntasks_kl;
    int task_ij = blockIdx.x * blockDim.x + threadIdx.x;
    int task_kl = blockIdx.y * blockDim.y + threadIdx.y;
    bool active = true;
    if (task_ij >= ntasks_ij || task_kl >= ntasks_kl) {
        active = false;
        task_ij = 0;
        task_kl = 0;
    }

    int bas_ij = offsets.bas_ij + task_ij;
    int bas_kl = offsets.bas_kl + task_kl;
    double norm = envs.fac;
    double omega = envs.omega;
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
    double* __restrict__ exp = c_bpcache.a1;
    double uw[10];
    double g[2*GSIZE5_INT3C];
    double *f = g + GSIZE5_INT3C;
    
    double* __restrict__ a12 = c_bpcache.a12;
    double* __restrict__ x12 = c_bpcache.x12;
    double* __restrict__ y12 = c_bpcache.y12;
    double* __restrict__ z12 = c_bpcache.z12;

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
    
    double j3[GPU_CART_MAX * 3];
    double k3[GPU_CART_MAX * 3];
    for (int k = 0; k < GPU_CART_MAX * 3; k++){
        j3[k] = 0.0;
        k3[k] = 0.0;
    }
    if (active) {
        for (ij = prim_ij; ij < prim_ij+nprim_ij; ++ij) {
            for (kl = prim_kl; kl < prim_kl+nprim_kl; ++kl) {
                            
            double aij = a12[ij];
            double xij = x12[ij];
            double yij = y12[ij];
            double zij = z12[ij];
            double akl = a12[kl];
            double xkl = x12[kl];
            double ykl = y12[kl];
            double zkl = z12[kl];
            double xijxkl = xij - xkl;
            double yijykl = yij - ykl;
            double zijzkl = zij - zkl;
            double aijkl = aij + akl;
            double a1 = aij * akl;
            double a0 = a1 / aijkl;
            double theta = omega > 0.0 ? omega * omega / (omega * omega + a0) : 1.0; 
            a0 *= theta;
            double x = a0 * (xijxkl * xijxkl + yijykl * yijykl + zijzkl * zijzkl);
                GINTrys_root5(x, uw);
                GINTscale_u<5>(uw, theta);
                GINTg0_2e_2d4d<5>(envs, g, uw, norm, as_ish, as_jsh, as_ksh, as_lsh, ij, kl);
                
            double ak2 = -2.0*exp[kl];
            GINTnabla1k_2e<5>(envs, f, g, ak2, envs.i_l, envs.j_l, envs.k_l);
                GINTkernel_int3c2e_ip2_getjk_direct<5>(envs, jk, j3, k3, f, g, ish, jsh, ksh);
            } 
        }
    }
    
    write_int3c2e_ip2_jk(jk, j3, k3, ksh);
}
#endif 

#if POLYFIT_ORDER_IP >= 6
template <> __global__
void GINTint3c2e_ip2_jk_kernel<6,GSIZE6_INT3C>(GINTEnvVars envs, JKMatrix jk, BasisProdOffsets offsets)
{
    int ntasks_ij = offsets.ntasks_ij;
    int ntasks_kl = offsets.ntasks_kl;
    int task_ij = blockIdx.x * blockDim.x + threadIdx.x;
    int task_kl = blockIdx.y * blockDim.y + threadIdx.y;
    bool active = true;
    if (task_ij >= ntasks_ij || task_kl >= ntasks_kl) {
        active = false;
        task_ij = 0;
        task_kl = 0;
    }

    int bas_ij = offsets.bas_ij + task_ij;
    int bas_kl = offsets.bas_kl + task_kl;
    double norm = envs.fac;
    double omega = envs.omega;
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
    double* __restrict__ exp = c_bpcache.a1;
    double uw[12];
    double g[2*GSIZE6_INT3C];
    double *f = g + GSIZE6_INT3C;
    
    double* __restrict__ a12 = c_bpcache.a12;
    double* __restrict__ x12 = c_bpcache.x12;
    double* __restrict__ y12 = c_bpcache.y12;
    double* __restrict__ z12 = c_bpcache.z12;

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
    
    double j3[GPU_CART_MAX * 3];
    double k3[GPU_CART_MAX * 3];
    for (int k = 0; k < GPU_CART_MAX * 3; k++){
        j3[k] = 0.0;
        k3[k] = 0.0;
    }
    if (active) {
        for (ij = prim_ij; ij < prim_ij+nprim_ij; ++ij) {
            for (kl = prim_kl; kl < prim_kl+nprim_kl; ++kl) {
                            
            double aij = a12[ij];
            double xij = x12[ij];
            double yij = y12[ij];
            double zij = z12[ij];
            double akl = a12[kl];
            double xkl = x12[kl];
            double ykl = y12[kl];
            double zkl = z12[kl];
            double xijxkl = xij - xkl;
            double yijykl = yij - ykl;
            double zijzkl = zij - zkl;
            double aijkl = aij + akl;
            double a1 = aij * akl;
            double a0 = a1 / aijkl;
            double theta = omega > 0.0 ? omega * omega / (omega * omega + a0) : 1.0; 
            a0 *= theta;
            double x = a0 * (xijxkl * xijxkl + yijykl * yijykl + zijzkl * zijzkl);
                GINTrys_root6(x, uw);
                GINTscale_u<6>(uw, theta);
                GINTg0_2e_2d4d<6>(envs, g, uw, norm, as_ish, as_jsh, as_ksh, as_lsh, ij, kl);
                
            double ak2 = -2.0*exp[kl];
            GINTnabla1k_2e<6>(envs, f, g, ak2, envs.i_l, envs.j_l, envs.k_l);
                GINTkernel_int3c2e_ip2_getjk_direct<6>(envs, jk, j3, k3, f, g, ish, jsh, ksh);
            } 
        }
    }
    
    write_int3c2e_ip2_jk(jk, j3, k3, ksh);
}
#endif 

#if POLYFIT_ORDER_IP >= 7
template <> __global__
void GINTint3c2e_ip2_jk_kernel<7,GSIZE7_INT3C>(GINTEnvVars envs, JKMatrix jk, BasisProdOffsets offsets)
{
    int ntasks_ij = offsets.ntasks_ij;
    int ntasks_kl = offsets.ntasks_kl;
    int task_ij = blockIdx.x * blockDim.x + threadIdx.x;
    int task_kl = blockIdx.y * blockDim.y + threadIdx.y;
    bool active = true;
    if (task_ij >= ntasks_ij || task_kl >= ntasks_kl) {
        active = false;
        task_ij = 0;
        task_kl = 0;
    }

    int bas_ij = offsets.bas_ij + task_ij;
    int bas_kl = offsets.bas_kl + task_kl;
    double norm = envs.fac;
    double omega = envs.omega;
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
    double* __restrict__ exp = c_bpcache.a1;
    double uw[14];
    double g[2*GSIZE7_INT3C];
    double *f = g + GSIZE7_INT3C;
    
    double* __restrict__ a12 = c_bpcache.a12;
    double* __restrict__ x12 = c_bpcache.x12;
    double* __restrict__ y12 = c_bpcache.y12;
    double* __restrict__ z12 = c_bpcache.z12;

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
    
    double j3[GPU_CART_MAX * 3];
    double k3[GPU_CART_MAX * 3];
    for (int k = 0; k < GPU_CART_MAX * 3; k++){
        j3[k] = 0.0;
        k3[k] = 0.0;
    }
    if (active) {
        for (ij = prim_ij; ij < prim_ij+nprim_ij; ++ij) {
            for (kl = prim_kl; kl < prim_kl+nprim_kl; ++kl) {
                            
            double aij = a12[ij];
            double xij = x12[ij];
            double yij = y12[ij];
            double zij = z12[ij];
            double akl = a12[kl];
            double xkl = x12[kl];
            double ykl = y12[kl];
            double zkl = z12[kl];
            double xijxkl = xij - xkl;
            double yijykl = yij - ykl;
            double zijzkl = zij - zkl;
            double aijkl = aij + akl;
            double a1 = aij * akl;
            double a0 = a1 / aijkl;
            double theta = omega > 0.0 ? omega * omega / (omega * omega + a0) : 1.0; 
            a0 *= theta;
            double x = a0 * (xijxkl * xijxkl + yijykl * yijykl + zijzkl * zijzkl);
                GINTrys_root7(x, uw);
                GINTscale_u<7>(uw, theta);
                GINTg0_2e_2d4d<7>(envs, g, uw, norm, as_ish, as_jsh, as_ksh, as_lsh, ij, kl);
                
            double ak2 = -2.0*exp[kl];
            GINTnabla1k_2e<7>(envs, f, g, ak2, envs.i_l, envs.j_l, envs.k_l);
                GINTkernel_int3c2e_ip2_getjk_direct<7>(envs, jk, j3, k3, f, g, ish, jsh, ksh);
            } 
        }
    }
    
    write_int3c2e_ip2_jk(jk, j3, k3, ksh);
}
#endif 

#if POLYFIT_ORDER_IP >= 8
template <> __global__
void GINTint3c2e_ip2_jk_kernel<8,GSIZE8_INT3C>(GINTEnvVars envs, JKMatrix jk, BasisProdOffsets offsets)
{
    int ntasks_ij = offsets.ntasks_ij;
    int ntasks_kl = offsets.ntasks_kl;
    int task_ij = blockIdx.x * blockDim.x + threadIdx.x;
    int task_kl = blockIdx.y * blockDim.y + threadIdx.y;
    bool active = true;
    if (task_ij >= ntasks_ij || task_kl >= ntasks_kl) {
        active = false;
        task_ij = 0;
        task_kl = 0;
    }

    int bas_ij = offsets.bas_ij + task_ij;
    int bas_kl = offsets.bas_kl + task_kl;
    double norm = envs.fac;
    double omega = envs.omega;
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
    double* __restrict__ exp = c_bpcache.a1;
    double uw[16];
    double g[2*GSIZE8_INT3C];
    double *f = g + GSIZE8_INT3C;
    
    double* __restrict__ a12 = c_bpcache.a12;
    double* __restrict__ x12 = c_bpcache.x12;
    double* __restrict__ y12 = c_bpcache.y12;
    double* __restrict__ z12 = c_bpcache.z12;

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
    
    double j3[GPU_CART_MAX * 3];
    double k3[GPU_CART_MAX * 3];
    for (int k = 0; k < GPU_CART_MAX * 3; k++){
        j3[k] = 0.0;
        k3[k] = 0.0;
    }
    if (active) {
        for (ij = prim_ij; ij < prim_ij+nprim_ij; ++ij) {
            for (kl = prim_kl; kl < prim_kl+nprim_kl; ++kl) {
                            
            double aij = a12[ij];
            double xij = x12[ij];
            double yij = y12[ij];
            double zij = z12[ij];
            double akl = a12[kl];
            double xkl = x12[kl];
            double ykl = y12[kl];
            double zkl = z12[kl];
            double xijxkl = xij - xkl;
            double yijykl = yij - ykl;
            double zijzkl = zij - zkl;
            double aijkl = aij + akl;
            double a1 = aij * akl;
            double a0 = a1 / aijkl;
            double theta = omega > 0.0 ? omega * omega / (omega * omega + a0) : 1.0; 
            a0 *= theta;
            double x = a0 * (xijxkl * xijxkl + yijykl * yijykl + zijzkl * zijzkl);
                GINTrys_root8(x, uw);
                GINTscale_u<8>(uw, theta);
                GINTg0_2e_2d4d<8>(envs, g, uw, norm, as_ish, as_jsh, as_ksh, as_lsh, ij, kl);
                
            double ak2 = -2.0*exp[kl];
            GINTnabla1k_2e<8>(envs, f, g, ak2, envs.i_l, envs.j_l, envs.k_l);
                GINTkernel_int3c2e_ip2_getjk_direct<8>(envs, jk, j3, k3, f, g, ish, jsh, ksh);
            } 
        }
    }
    
    write_int3c2e_ip2_jk(jk, j3, k3, ksh);
}
#endif 

#if POLYFIT_ORDER_IP >= 9
template <> __global__
void GINTint3c2e_ip2_jk_kernel<9,GSIZE9_INT3C>(GINTEnvVars envs, JKMatrix jk, BasisProdOffsets offsets)
{
    int ntasks_ij = offsets.ntasks_ij;
    int ntasks_kl = offsets.ntasks_kl;
    int task_ij = blockIdx.x * blockDim.x + threadIdx.x;
    int task_kl = blockIdx.y * blockDim.y + threadIdx.y;
    bool active = true;
    if (task_ij >= ntasks_ij || task_kl >= ntasks_kl) {
        active = false;
        task_ij = 0;
        task_kl = 0;
    }

    int bas_ij = offsets.bas_ij + task_ij;
    int bas_kl = offsets.bas_kl + task_kl;
    double norm = envs.fac;
    double omega = envs.omega;
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
    double* __restrict__ exp = c_bpcache.a1;
    double uw[18];
    double g[2*GSIZE9_INT3C];
    double *f = g + GSIZE9_INT3C;
    
    double* __restrict__ a12 = c_bpcache.a12;
    double* __restrict__ x12 = c_bpcache.x12;
    double* __restrict__ y12 = c_bpcache.y12;
    double* __restrict__ z12 = c_bpcache.z12;

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
    
    double j3[GPU_CART_MAX * 3];
    double k3[GPU_CART_MAX * 3];
    for (int k = 0; k < GPU_CART_MAX * 3; k++){
        j3[k] = 0.0;
        k3[k] = 0.0;
    }
    if (active) {
        for (ij = prim_ij; ij < prim_ij+nprim_ij; ++ij) {
            for (kl = prim_kl; kl < prim_kl+nprim_kl; ++kl) {
                            
            double aij = a12[ij];
            double xij = x12[ij];
            double yij = y12[ij];
            double zij = z12[ij];
            double akl = a12[kl];
            double xkl = x12[kl];
            double ykl = y12[kl];
            double zkl = z12[kl];
            double xijxkl = xij - xkl;
            double yijykl = yij - ykl;
            double zijzkl = zij - zkl;
            double aijkl = aij + akl;
            double a1 = aij * akl;
            double a0 = a1 / aijkl;
            double theta = omega > 0.0 ? omega * omega / (omega * omega + a0) : 1.0; 
            a0 *= theta;
            double x = a0 * (xijxkl * xijxkl + yijykl * yijykl + zijzkl * zijzkl);
                GINTrys_root9(x, uw);
                GINTscale_u<9>(uw, theta);
                GINTg0_2e_2d4d<9>(envs, g, uw, norm, as_ish, as_jsh, as_ksh, as_lsh, ij, kl);
                
            double ak2 = -2.0*exp[kl];
            GINTnabla1k_2e<9>(envs, f, g, ak2, envs.i_l, envs.j_l, envs.k_l);
                GINTkernel_int3c2e_ip2_getjk_direct<9>(envs, jk, j3, k3, f, g, ish, jsh, ksh);
            } 
        }
    }
    
    write_int3c2e_ip2_jk(jk, j3, k3, ksh);
}
#endif 
