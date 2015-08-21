/*****************************************************************************
*                                                                            *
* Copyright 2014 Intel Corporation                                           *
*                                                                            *
* Licensed under the Apache License, Version 2.0 (the "License");            *
* you may not use this file except in compliance with the License.           *
* You may obtain a copy of the License at                                    *
*                                                                            *
*    http://www.apache.org/licenses/LICENSE-2.0                              *
*                                                                            *
* Unless required by applicable law or agreed to in writing, software        *
* distributed under the License is distributed on an "AS IS" BASIS,          *
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   *
* See the License for the specific language governing permissions and        *
* limitations under the License.                                             *
******************************************************************************
* Developers and authors:                                                    *
* Shay Gueron (1, 2), and Vlad Krasnov (1)                                   *
* (1) Intel Corporation, Israel Development Center, Haifa, Israel            *
* (2) University of Haifa, Israel                                            *
*****************************************************************************/

#include "rsaz_exp.h"
#include "bn_lcl.h"
#include <string.h>

void LOAD_TRANSPOSE_512(BN_ULONG *rpx4, const BN_ULONG *b0, const BN_ULONG *b1,
                        const BN_ULONG *b2, const BN_ULONG *b3);
void TRANSPOSE_STORE_512(BN_ULONG *inx4, const BN_ULONG *o0,
                         const BN_ULONG *o1, const BN_ULONG *o2,
                         const BN_ULONG *o3);
void AMM_WW_512_x4(BN_ULONG *rpx4, const BN_ULONG *apx4, const BN_ULONG *bpx4,
                   const BN_ULONG *npx4, const BN_ULONG *k0x4);
void AMS_WW_512_x4(BN_ULONG *rpx4, const BN_ULONG *apx4, const BN_ULONG *npx4,
                   const BN_ULONG *k0x4, int repeat);
void STORE_512(void *in_t, const void *inx4, int index);
void SELECT_512(void *valx4, const void *in_t, int *index, int limit);

void LOAD_TRANSPOSE_683(BN_ULONG *rpx4, const BN_ULONG *b0, const BN_ULONG *b1,
                        const BN_ULONG *b2, const BN_ULONG *b3);
void TRANSPOSE_STORE_683(BN_ULONG *inx4, const BN_ULONG *o0,
                         const BN_ULONG *o1, const BN_ULONG *o2,
                         const BN_ULONG *o3);
void AMM_WW_683_x4(BN_ULONG *rpx4, const BN_ULONG *apx4, const BN_ULONG *bpx4,
                   const BN_ULONG *npx4,const BN_ULONG *k0x4);
void AMS_WW_683_x4(BN_ULONG *rpx4, const BN_ULONG *apx4, const BN_ULONG *npx4,
                   const BN_ULONG *k0x4, int repeat);
void STORE_683(void *in_t, const void *inx4, int index);
void SELECT_683(void *valx4, const void *in_t, int *index, int limit);

void LOAD_TRANSPOSE_768(BN_ULONG *rpx4, const BN_ULONG *b0, const BN_ULONG *b1,
                        const BN_ULONG *b2, const BN_ULONG *b3);
void TRANSPOSE_STORE_768(BN_ULONG *inx4, const BN_ULONG *o0,
                         const BN_ULONG *o1, const BN_ULONG *o2,
                         const BN_ULONG *o3);
void AMM_WW_768_x4(BN_ULONG *rpx4, const BN_ULONG *apx4, const BN_ULONG *bpx4,
                   const BN_ULONG *npx4,const BN_ULONG *k0x4);
void AMS_WW_768_x4(BN_ULONG *rpx4, const BN_ULONG *apx4, const BN_ULONG *npx4,
                   const BN_ULONG *k0x4, int repeat);
void STORE_768(void *in_t, const void *inx4, int index);
void SELECT_768(void *valx4, const void *in_t, int *index, int limit);



#if defined(__GNUC__)
# define ALIGN64 __attribute__((aligned(64)))
#elif defined(_MSC_VER)
# define ALIGN64 __declspec(align(64))
#else
# define ALIGN64
#endif

#if defined(__GNUC__)
# define ALIGN4096 __attribute__((aligned(4096)))
#elif defined(_MSC_VER)
# define ALIGN4096 __declspec(align(4096))
#else
# define ALIGN4096
#endif

ALIGN64 static const BN_ULONG one[28*4] =
    {1,1,1,1,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0,
     0,0,0,0};

ALIGN64 static const BN_ULONG two40[18*4] =
    {0,0,0,0,
    1<<11,1<<11,1<<11,1<<11,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0};

ALIGN64 static const BN_ULONG two680[24*4] =
    {0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    1<<13,1<<13,1<<13,1<<13};

ALIGN64 static const BN_ULONG two60[27*4] =
    {0,0,0,0,
    0,0,0,0,
    1<<2,1<<2,1<<2,1<<2,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0,
    0,0,0,0};

/* Performs 4 modular exponentiations of 512 or 683 bit simultaneously */
void RSAZ_mod_exp_avx2_x4(BIGNUM *r0, BIGNUM *e0, BIGNUM *p0, BN_MONT_CTX *c0,
                          BIGNUM *r1, BIGNUM *e1, BIGNUM *p1, BN_MONT_CTX *c1,
                          BIGNUM *r2, BIGNUM *e2, BIGNUM *p2, BN_MONT_CTX *c2,
                          BIGNUM *r3, BIGNUM *e3, BIGNUM *p3, BN_MONT_CTX *c3,
                          BN_ULONG bits)
{
    BN_ULONG k0 = c0->n0[0];
    BN_ULONG k1 = c1->n0[0];
    BN_ULONG k2 = c2->n0[0];
    BN_ULONG k3 = c3->n0[0];
    BN_ULONG exponent_bits = bits, mod_bits = bits;

    ALIGN64 BN_ULONG m[28*4] = {0};
    ALIGN64 BN_ULONG mod_mul_result[28*4] = {0};
    ALIGN64 BN_ULONG temp[28*4] = {0};
    ALIGN64 BN_ULONG R2[28*4] = {0};
    ALIGN64 BN_ULONG a_tag[28*4] = {0};
    ALIGN64 BN_ULONG base[28*4] = {0};
    ALIGN64 BN_ULONG k[4] =
             {k0 & 0x1fffffff,k1 & 0x1fffffff,k2 & 0x1fffffff,k3 & 0x1fffffff};
    ALIGN64 int wval[8];

    int window_size;
    int operand_words;
    int i;

    __attribute__ ((aligned(4096))) BN_ULONG table_s[28*32] = {0};

    void(*LOAD_TRANSPOSE)(BN_ULONG *rpx4, const BN_ULONG *b0,
                   const BN_ULONG *b1, const BN_ULONG *b2, const BN_ULONG *b3);
    void(*TRANSPOSE_STORE)(BN_ULONG *inx4, const BN_ULONG *o0,
                   const BN_ULONG *o1, const BN_ULONG *o2, const BN_ULONG *o3);
    void(*AMM)(BN_ULONG *rpx4, const BN_ULONG *apx4, const BN_ULONG *bpx4,
               const BN_ULONG *npx4, const BN_ULONG *k0x4);
    void(*AMS)(BN_ULONG *rpx4, const BN_ULONG *apx4, const BN_ULONG *npx4,
               const BN_ULONG *k0x4, int repeat);
    void(*SELECT)(void *valx4, const void *in_t, int *index, int limit);
    void(*STORE)(void *in_t, const void *inx4, int index);

    if(mod_bits <= 513) {
        AMM = AMM_WW_512_x4;
        AMS = AMS_WW_512_x4;
        TRANSPOSE_STORE = TRANSPOSE_STORE_512;
        LOAD_TRANSPOSE  = LOAD_TRANSPOSE_512;
        STORE = STORE_512;
        SELECT = SELECT_512;

        window_size = 4;
        operand_words = 18;

        LOAD_TRANSPOSE(m, p0->d, p1->d, p2->d, p3->d);
        LOAD_TRANSPOSE(base, r0->d, r1->d, r2->d, r3->d);
        LOAD_TRANSPOSE(R2, c0->RR.d, c1->RR.d, c2->RR.d, c3->RR.d);

        AMM(R2, R2, R2, m, k);
        AMM(R2, R2, two40, m, k);
    } else if(mod_bits <= 696) {
        AMM = AMM_WW_683_x4;
        AMS = AMS_WW_683_x4;
        TRANSPOSE_STORE = TRANSPOSE_STORE_683;
        LOAD_TRANSPOSE  = LOAD_TRANSPOSE_683;
        STORE = STORE_683;
        SELECT = SELECT_683;

        window_size = 4;
        operand_words = 24;

        LOAD_TRANSPOSE(m, p0->d, p1->d, p2->d, p3->d);
        LOAD_TRANSPOSE(base, r0->d, r1->d, r2->d, r3->d);
        LOAD_TRANSPOSE(R2, c0->RR.d, c1->RR.d, c2->RR.d, c3->RR.d);

        AMM(R2, R2, two680, m, k);
    } else if(mod_bits <= 768) {
        AMM = AMM_WW_768_x4;
        AMS = AMS_WW_768_x4;
        TRANSPOSE_STORE = TRANSPOSE_STORE_768;
        LOAD_TRANSPOSE  = LOAD_TRANSPOSE_768;
        STORE = STORE_768;
        SELECT = SELECT_768;

        window_size = 4;
        operand_words = 28;

        LOAD_TRANSPOSE(m, p0->d, p1->d, p2->d, p3->d);
        LOAD_TRANSPOSE(base, r0->d, r1->d, r2->d, r3->d);
        LOAD_TRANSPOSE(R2, c0->RR.d, c1->RR.d, c2->RR.d, c3->RR.d);

        AMM(R2, R2, R2, m, k);
        AMM(R2, R2, two60, m, k);
    } else {
        return;
    }

    // table[0]
    AMM(mod_mul_result, R2, one, m, k);
    STORE(table_s, mod_mul_result, 0);
    // table[1]
    AMM(a_tag, R2, base, m, k);
    STORE(table_s, a_tag, 1);

    if(window_size>=1) {
        memcpy(mod_mul_result, a_tag, 4*operand_words*sizeof(BN_ULONG));
        for(i=2; i<(1<<window_size); i++) {
            AMM(mod_mul_result, mod_mul_result, a_tag, m, k);
            STORE(table_s, mod_mul_result, i);
        }
    }
    // load first window
    unsigned char *p_str0 = (unsigned char*)e0->d;
    unsigned char *p_str1 = (unsigned char*)e1->d;
    unsigned char *p_str2 = (unsigned char*)e2->d;
    unsigned char *p_str3 = (unsigned char*)e3->d;
    int index = exponent_bits - window_size;
    int mask = (1<<window_size) - 1;
    int wvalue0;
    int wvalue1;
    int wvalue2;
    int wvalue3;
    if(index>0) {
        wvalue0 = *((unsigned short*)&p_str0[index/8]);
        wvalue0 = (wvalue0>> (index%8)) & mask;
        wval[0] = wval[4] = wvalue0;
        wvalue1 = *((unsigned short*)&p_str1[index/8]);
        wvalue1 = (wvalue1>> (index%8)) & mask;
        wval[1] = wval[5] = wvalue1;
        wvalue2 = *((unsigned short*)&p_str2[index/8]);
        wvalue2 = (wvalue2>> (index%8)) & mask;
        wval[2] = wval[6] = wvalue2;
        wvalue3 = *((unsigned short*)&p_str3[index/8]);
        wvalue3 = (wvalue3>> (index%8)) & mask;
        wval[3] = wval[7] = wvalue3;
    } else {
        wvalue0 = p_str0[0] & mask;
        wval[0] = wval[4] = wvalue0;
        wvalue1 = p_str1[0] & mask;
        wval[1] = wval[5] = wvalue1;
        wvalue2 = p_str2[0] & mask;
        wval[2] = wval[6] = wvalue2;
        wvalue3 = p_str3[0] & mask;
        wval[3] = wval[7] = wvalue3;
    }

    index-=window_size;

    SELECT(mod_mul_result, table_s, wval, 1<<window_size);

    while(index >= 0) {
        AMS(mod_mul_result, mod_mul_result, m, k, window_size);

        wvalue0 = *((unsigned short*)&p_str0[index/8]);
        wvalue0 = (wvalue0>> (index%8)) & mask;
        wval[0] = wval[4] = wvalue0;
        wvalue1 = *((unsigned short*)&p_str1[index/8]);
        wvalue1 = (wvalue1>> (index%8)) & mask;
        wval[1] = wval[5] = wvalue1;
        wvalue2 = *((unsigned short*)&p_str2[index/8]);
        wvalue2 = (wvalue2>> (index%8)) & mask;
        wval[2] = wval[6] = wvalue2;
        wvalue3 = *((unsigned short*)&p_str3[index/8]);
        wvalue3 = (wvalue3>> (index%8)) & mask;
        wval[3] = wval[7] = wvalue3;

        index-=window_size;
        SELECT(temp, table_s, wval, 1<<window_size);
        AMM(mod_mul_result, mod_mul_result, temp, m, k);
    }
    if(index > -window_size) {
        int last_window_mask = (1<<(exponent_bits%window_size)) - 1;
        AMS(mod_mul_result, mod_mul_result, m, k, window_size+index);

        wvalue0 = p_str0[0] & last_window_mask;
        wval[0] = wval[4] = wvalue0;
        wvalue1 = p_str1[0] & last_window_mask;
        wval[1] = wval[5] = wvalue1;
        wvalue2 = p_str2[0] & last_window_mask;
        wval[2] = wval[6] = wvalue2;
        wvalue3 = p_str3[0] & last_window_mask;
        wval[3] = wval[7] = wvalue3;

        SELECT(temp, table_s, wval, 1<<window_size);
        AMM(mod_mul_result, mod_mul_result, temp, m, k);
    }
    AMM(mod_mul_result, mod_mul_result, one, m, k);
    TRANSPOSE_STORE(mod_mul_result, r0->d, r1->d, r2->d, r3->d);
    r0->top = (bits + 63) / 64;
    r1->top = (bits + 63) / 64;
    r2->top = (bits + 63) / 64;
    r3->top = (bits + 63) / 64;
    r0->neg = 0;
    r1->neg = 0;
    r2->neg = 0;
    r3->neg = 0;
    bn_correct_top(r0);
    bn_correct_top(r1);
    bn_correct_top(r2);
    bn_correct_top(r3);
}

