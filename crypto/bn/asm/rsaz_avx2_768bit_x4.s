 ##############################################################################
 #                                                                            #
 # Copyright 2014 Intel Corporation                                           #
 #                                                                            #
 # Licensed under the Apache License, Version 2.0 (the "License");            #
 # you may not use this file except in compliance with the License.           #
 # You may obtain a copy of the License at                                    #
 #                                                                            #
 #    http://www.apache.org/licenses/LICENSE-2.0                              #
 #                                                                            #
 # Unless required by applicable law or agreed to in writing, software        #
 # distributed under the License is distributed on an "AS IS" BASIS,          #
 # WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
 # See the License for the specific language governing permissions and        #
 # limitations under the License.                                             #
 ##############################################################################
 #                                                                            #
 # Developers and authors:                                                    #
 # Shay Gueron (1, 2), and Vlad Krasnov (1)                                   #
 # (1) Intel Corporation, Israel Development Center                           #
 # (2) University of Haifa                                                    #
 # Reference:                                                                 #
 # S.Gueron and V.Krasnov, "Software Implementation of Modular Exponentiation,#
 #                         Using Advanced Vector Instructions Architectures"  #
 #                                                                            #
 ##############################################################################
.align 32
.LAndMask_768:
.type .LAndMask_768,@object
.quad 0x1fffffff,0x1fffffff,0x1fffffff,0x1fffffff
.size .LAndMask_768,.-.LAndMask_768
.Lperm1:
.type .Lperm1,@object
.long 0,2,4,6,1,1,1,1
.size .Lperm1,.-.Lperm1
.Lperm2:
.type .Lperm2,@object
.long 1,1,1,1,0,2,4,6
.size .Lperm2,.-.Lperm2
.LvalOne:
.type .LvalOne,@object
.long 1,1,1,1,1,1,1,1
.size .LvalOne,.-.LvalOne
.LstoreMask:
.type .LstoreMask,@object
.quad 0xffffffffffffffff,0xffffffffffffffff,0xffffffffffffffff,0
.size .LstoreMask,.-.LstoreMask

.Lperm3:
.type .Lperm3,@object
.long 0,0,1,1,2,2,3,3
.size .Lperm3,.-.Lperm3
.Lperm4:
.type .Lperm4,@object
.long 4,4,5,5,6,6,7,7
.size .Lperm4,.-.Lperm4

################################################################################
################################################################################
#void LOAD_TRANSPOSE_768(
.set rpx4, %rdi # uint64_t *rpx4,
.set b0, %rsi   # const uint64_t *b0,
.set b1, %rdx   # const uint64_t *b1,
.set b2, %rcx   # const uint64_t *b2,
.set b3, %r8    # const uint64_t *b3);

 .type LOAD_TRANSPOSE_768,@function
.globl LOAD_TRANSPOSE_768
.align 64
LOAD_TRANSPOSE_768:

.set X0, %ymm0
.set X1, %ymm1
.set X2, %ymm2
.set X3, %ymm3

.set X4, %ymm4
.set X5, %ymm5
.set X6, %ymm6
.set X7, %ymm7

.set T0, %ymm8
.set T1, %ymm9
.set T2, %ymm10
.set T3, %ymm11
.set T4, %ymm12
.set T5, %ymm13
.set T6, %ymm14
.set T7, %ymm15

    # Load the data
    vmovdqu 32*0(b0), X0
    vmovdqu 32*1(b0), X4
    vmovdqu 32*0(b1), X1
    vmovdqu 32*1(b1), X5
    vmovdqu 32*0(b2), X2
    vmovdqu 32*1(b2), X6
    vmovdqu 32*0(b3), X3
    vmovdqu 32*1(b3), X7
    # Transpose X and Y independently
    vpunpcklqdq X1, X0, T0 # T0 = [B2 A2 B0 A0]
    vpunpcklqdq X3, X2, T1 # T1 = [D2 C2 D0 C0]
    vpunpckhqdq X1, X0, T2 # T2 = [B3 A3 B1 A1]
    vpunpckhqdq X3, X2, T3 # T3 = [D3 C3 D1 C1]
    vpunpcklqdq X5, X4, T4
    vpunpcklqdq X7, X6, T5
    vpunpckhqdq X5, X4, T6
    vpunpckhqdq X7, X6, T7

    vperm2i128 $0x20, T1, T0, X0 # X0 = [D0 C0 B0 A0]
    vperm2i128 $0x20, T3, T2, X1 # X1 = [D1 C1 B1 A1]
    vperm2i128 $0x31, T1, T0, X2 # X2 = [D2 C2 B2 A2]
    vperm2i128 $0x31, T3, T2, X3 # X3 = [D3 C3 B3 A3]
    vperm2i128 $0x20, T5, T4, X4
    vperm2i128 $0x20, T7, T6, X5
    vperm2i128 $0x31, T5, T4, X6
    vperm2i128 $0x31, T7, T6, X7

    vpand .LAndMask_768(%rip), X0, T0
    vpsrlq $29, X0, X0
    vpand .LAndMask_768(%rip), X0, T1
    vpsrlq $29, X0, X0
    vpsllq $6, X1, T2
    vpxor X0, T2, T2
    vpand .LAndMask_768(%rip), T2, T2
    vpsrlq $23, X1, X1
    vpand .LAndMask_768(%rip), X1, T3
    vpsrlq $29, X1, X1
    vpsllq $12, X2, T4
    vpxor X1, T4, T4
    vpand .LAndMask_768(%rip), T4, T4
    vpsrlq $17, X2, X2
    vpand .LAndMask_768(%rip), X2, T5
    vpsrlq $29, X2, X2
    vpsllq $18, X3, T6
    vpxor X2, T6, T6
    vpand .LAndMask_768(%rip), T6, T6
    vpsrlq $11, X3, X3
    vpand .LAndMask_768(%rip), X3, T7

    vmovdqu T0, 32*0(rpx4)
    vmovdqu T1, 32*1(rpx4)
    vmovdqu T2, 32*2(rpx4)
    vmovdqu T3, 32*3(rpx4)
    vmovdqu T4, 32*4(rpx4)
    vmovdqu T5, 32*5(rpx4)
    vmovdqu T6, 32*6(rpx4)
    vmovdqu T7, 32*7(rpx4)

    vpsrlq $29, X3, X3
    vpsllq $24, X4, T0
    vpxor X3, T0, T0
    vpand .LAndMask_768(%rip), T0, T0
    vpsrlq $5, X4, X4
    vpand .LAndMask_768(%rip), X4, T1
    vpsrlq $29, X4, X4
    vpand .LAndMask_768(%rip), X4, T2
    vpsrlq $29, X4, X4
    vpsllq $1, X5, T3
    vpxor X4, T3, T3
    vpand .LAndMask_768(%rip), T3, T3
    vpsrlq $28, X5, X5
    vpand .LAndMask_768(%rip), X5, T4
    vpsrlq $29, X5, X5
    vpsllq $7, X6, T5
    vpxor X5, T5, T5
    vpand .LAndMask_768(%rip), T5, T5
    vpsrlq $22, X6, X6
    vpand .LAndMask_768(%rip), X6, T6
    vpsrlq $29, X6, X6
    vpsllq $13, X7, T7
    vpxor X6, T7, T7
    vpand .LAndMask_768(%rip), T7, T7

    vmovdqu T0, 32*8(rpx4)
    vmovdqu T1, 32*9(rpx4)
    vmovdqu T2, 32*10(rpx4)
    vmovdqu T3, 32*11(rpx4)
    vmovdqu T4, 32*12(rpx4)
    vmovdqu T5, 32*13(rpx4)
    vmovdqu T6, 32*14(rpx4)
    vmovdqu T7, 32*15(rpx4)

    vmovdqu 32*2(b0), X0
    vmovdqu 32*2(b1), X1
    vmovdqu 32*2(b2), X2
    vmovdqu 32*2(b3), X3

    vpunpcklqdq X1, X0, T0
    vpunpcklqdq X3, X2, T1
    vpunpckhqdq X1, X0, T2
    vpunpckhqdq X3, X2, T3
    vperm2i128 $0x20, T1, T0, X0
    vperm2i128 $0x20, T3, T2, X1
    vperm2i128 $0x31, T1, T0, X2
    vperm2i128 $0x31, T3, T2, X3

    vpsrlq $16, X7, X7
    vpand .LAndMask_768(%rip), X7, T0
    vpsrlq $29, X7, X7
    vpsllq $19, X0, T1
    vpxor X7, T1, T1
    vpand .LAndMask_768(%rip), T1, T1
    vpsrlq $10, X0, X0
    vpand .LAndMask_768(%rip), X0, T2
    vpsrlq $29, X0, X0
    vpsllq $25, X1, T3
    vpxor X0, T3, T3
    vpand .LAndMask_768(%rip), T3, T3
    vpsrlq $4, X1, X1
    vpand .LAndMask_768(%rip), X1, T4
    vpsrlq $29, X1, X1
    vpand .LAndMask_768(%rip), X1, T5
    vpsrlq $29, X1, X1
    vpsllq $2, X2, T6
    vpxor X1, T6, T6
    vpand .LAndMask_768(%rip), T6, T6
    vpsrlq $27, X2, X2
    vpand .LAndMask_768(%rip), X2, T7

    vmovdqu T0, 32*16(rpx4)
    vmovdqu T1, 32*17(rpx4)
    vmovdqu T2, 32*18(rpx4)
    vmovdqu T3, 32*19(rpx4)
    vmovdqu T4, 32*20(rpx4)
    vmovdqu T5, 32*21(rpx4)
    vmovdqu T6, 32*22(rpx4)
    vmovdqu T7, 32*23(rpx4)

    vpsrlq $29, X2, X2
    vpsllq $8, X3, T0
    vpxor X2, T0, T0
    vpand .LAndMask_768(%rip), T0, T0

    vpsrlq $21, X3, X3
    vpand .LAndMask_768(%rip), X3, T1

    vpsrlq $29, X3, X3
    vpand .LAndMask_768(%rip), X3, T2

    vmovdqu T0, 32*24(rpx4)
    vmovdqu T1, 32*25(rpx4)
    vmovdqu T2, 32*26(rpx4)
ret
.size LOAD_TRANSPOSE_768,.-LOAD_TRANSPOSE_768
################################################################################
################################################################################
#void TRANSPOSE_STORE_768(
.set inx4, %rdi # uint64_t *inx4,
.set o0, %rsi   # const uint64_t *o0,
.set o1, %rdx   # const uint64_t *o1,
.set o2, %rcx   # const uint64_t *o2,
.set o3, %r8    # const uint64_t *o3);

 .type TRANSPOSE_STORE_768,@function
.align 64
.globl TRANSPOSE_STORE_768
TRANSPOSE_STORE_768:

.set D0, %ymm0
.set D1, %ymm1
.set D2, %ymm2
.set D3, %ymm3
.set D4, %ymm4
.set D5, %ymm5
.set D6, %ymm6
.set D7, %ymm7
.set D8, %ymm8

.set T0, %ymm9
.set T1, %ymm10
.set T2, %ymm11
.set T3, %ymm12
.set D9, %ymm13

    vmovdqu 32*0(inx4), D0
    vmovdqu 32*1(inx4), D1
    vmovdqu 32*2(inx4), D2
    vmovdqu 32*3(inx4), D3
    vmovdqu 32*4(inx4), D4
    vmovdqu 32*5(inx4), D5
    vmovdqu 32*6(inx4), D6
    vmovdqu 32*7(inx4), D7
    vmovdqu 32*8(inx4), D8
    vmovdqu 32*9(inx4), D9

    vpsllq $29, D1, D1
    vpsllq $58, D2, T0
    vpaddq D1, D0, D0
    vpaddq T0, D0, D0

    vpsrlq $6, D2, D2
    vpsllq $23, D3, D3
    vpsllq $52, D4, T1
    vpaddq D2, D3, D3
    vpaddq D3, T1, D1

    vpsrlq $12, D4, D4
    vpsllq $17, D5, D5
    vpsllq $46, D6, T2
    vpaddq D4, D5, D5
    vpaddq D5, T2, D2

    vpsrlq $18, D6, D6
    vpsllq $11, D7, D7
    vpsllq $40, D8, T3
    vpaddq D6, D7, D7
    vpaddq D7, T3, D3

    vpunpcklqdq D1, D0, T0 # T0 = [B2 A2 B0 A0]
    vpunpcklqdq D3, D2, T1 # T1 = [D2 C2 D0 C0]
    vpunpckhqdq D1, D0, T2 # T2 = [B3 A3 B1 A1]
    vpunpckhqdq D3, D2, T3 # T3 = [D3 C3 D1 C1]

    vperm2i128 $0x20, T1, T0, D0 # X0 = [D0 C0 B0 A0]
    vperm2i128 $0x20, T3, T2, D1 # X1 = [D1 C1 B1 A1]
    vperm2i128 $0x31, T1, T0, D2 # X2 = [D2 C2 B2 A2]
    vperm2i128 $0x31, T3, T2, D3 # X3 = [D3 C3 B3 A3]

    vmovdqu D0, 32*0(o0)
    vmovdqu D1, 32*0(o1)
    vmovdqu D2, 32*0(o2)
    vmovdqu D3, 32*0(o3)

    vmovdqu 32*10(inx4), D0
    vmovdqu 32*11(inx4), D1
    vmovdqu 32*12(inx4), D2
    vmovdqu 32*13(inx4), D3
    vmovdqu 32*14(inx4), D4
    vmovdqu 32*15(inx4), D5
    vmovdqu 32*16(inx4), D6
    vmovdqu 32*17(inx4), D7

    vpsrlq $24, D8, D8
    vpsllq $5, D9, D9
    vpsllq $34, D0, D0
    vpsllq $63, D1, T0

    vpaddq D9, D8, D8
    vpaddq D0, T0, T0
    vpaddq T0, D8, D8

    vpsrlq $1, D1, D1
    vpsllq $28, D2, D2
    vpsllq $57, D3, D9
    vpaddq D1, D9, D9
    vpaddq D2, D9, D9

    vpsrlq $7, D3, D3
    vpsllq $22, D4, D4
    vpsllq $51, D5, D0
    vpaddq D3, D0, D0
    vpaddq D4, D0, D0

    vpsrlq $13, D5, D5
    vpsllq $16, D6, D6
    vpsllq $45, D7, D1
    vpaddq D5, D1, D1
    vpaddq D6, D1, D1

    vpunpcklqdq D9, D8, T0 # T0 = [B2 A2 B0 A0]
    vpunpcklqdq D1, D0, T1 # T1 = [D2 C2 D0 C0]
    vpunpckhqdq D9, D8, T2 # T2 = [B3 A3 B1 A1]
    vpunpckhqdq D1, D0, T3 # T3 = [D3 C3 D1 C1]

    vperm2i128 $0x20, T1, T0, D0 # X0 = [D0 C0 B0 A0]
    vperm2i128 $0x20, T3, T2, D1 # X1 = [D1 C1 B1 A1]
    vperm2i128 $0x31, T1, T0, D2 # X2 = [D2 C2 B2 A2]
    vperm2i128 $0x31, T3, T2, D3 # X3 = [D3 C3 B3 A3]

    vmovdqu D0, 32*1(o0)
    vmovdqu D1, 32*1(o1)
    vmovdqu D2, 32*1(o2)
    vmovdqu D3, 32*1(o3)

    vmovdqu 32*18(inx4), D8
    vmovdqu 32*19(inx4), D0
    vmovdqu 32*20(inx4), D1
    vmovdqu 32*21(inx4), D2
    vmovdqu 32*22(inx4), D3
    vmovdqu 32*23(inx4), D4
    vmovdqu 32*24(inx4), D5
    vmovdqu 32*25(inx4), D6

    vpsrlq $19, D7, D7
    vpsllq $10, D8, D8
    vpsllq $39, D0, T0
    vpxor D8, D7, D7
    vpxor T0, D7, D7

    vpsrlq $25, D0, D8
    vpsllq $4, D1, D1
    vpsllq $33, D2, D2
    vpsllq $62, D3, T0
    vpxor D1, D8, D8
    vpxor T0, D2, D2
    vpxor D2, D8, D8

    vmovdqu 32*26(inx4), D2

    vpsrlq $2, D3, D0
    vpsllq $27, D4, T0
    vpsllq $56, D5, T1
    vpxor T0, D0, D0
    vpxor T1, D0, D0

    vpsrlq $8, D5, D1
    vpsllq $21, D6, T0
    vpsllq $50, D2, T1
    vpxor T0, D1, D1
    vpxor T1, D1, D1

    vpunpcklqdq D8, D7, T0 # T0 = [B2 A2 B0 A0]
    vpunpcklqdq D1, D0, T1 # T1 = [D2 C2 D0 C0]
    vpunpckhqdq D8, D7, T2 # T2 = [B3 A3 B1 A1]
    vpunpckhqdq D1, D0, T3 # T3 = [D3 C3 D1 C1]

    vperm2i128 $0x20, T1, T0, D0 # X0 = [D0 C0 B0 A0]
    vperm2i128 $0x20, T3, T2, D1 # X1 = [D1 C1 B1 A1]
    vperm2i128 $0x31, T1, T0, D2 # X2 = [D2 C2 B2 A2]
    vperm2i128 $0x31, T3, T2, D3 # X3 = [D3 C3 B3 A3]

    vmovdqu D0, 32*2(o0)
    vmovdqu D1, 32*2(o1)
    vmovdqu D2, 32*2(o2)
    vmovdqu D3, 32*2(o3)

    ret
.size TRANSPOSE_STORE_768,.-TRANSPOSE_STORE_768
################################################################################
################################################################################
#void SELECT_768(
.set res, %rdi   # uint64_t *valx4,
.set in_t, %rsi  # const uint64_t *in_t,
.set idx, %rdx   # int idx,
.set limit, %rcx # int limit);

 .type SELECT_768,@function
.align 64
.globl SELECT_768
SELECT_768:
    push %rbp
    mov %rsp, %rbp
    sub $32, %rsp
    and $-32, %rsp

    vpxor %ymm14, %ymm14, %ymm14
    vmovdqa %ymm14, (%rsp)

    # Will store the result
    vpxor %ymm0, %ymm0, %ymm0
    vpxor %ymm1, %ymm1, %ymm1
    vpxor %ymm2, %ymm2, %ymm2
    vpxor %ymm3, %ymm3, %ymm3
    vpxor %ymm4, %ymm4, %ymm4
    vpxor %ymm5, %ymm5, %ymm5
    vpxor %ymm6, %ymm6, %ymm6
    vpxor %ymm7, %ymm7, %ymm7
    vpxor %ymm8, %ymm8, %ymm8
    vpxor %ymm9, %ymm9, %ymm9
    vpxor %ymm10, %ymm10, %ymm10
    vpxor %ymm11, %ymm11, %ymm11
    vpxor %ymm12, %ymm12, %ymm12
    vpxor %ymm13, %ymm13, %ymm13

1:
        vmovdqa (%rsp), %ymm14
        vpaddd .LvalOne(%rip), %ymm14, %ymm15
        vpcmpeqd (idx), %ymm14, %ymm14
        vmovdqa %ymm15, (%rsp)

        vpand 32*0(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm0, %ymm0
        vpand 32*1(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm1, %ymm1
        vpand 32*2(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm2, %ymm2
        vpand 32*3(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm3, %ymm3
        vpand 32*4(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm4, %ymm4
        vpand 32*5(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm5, %ymm5
        vpand 32*6(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm6, %ymm6
        vpand 32*7(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm7, %ymm7
        vpand 32*8(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm8, %ymm8
        vpand 32*9(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm9, %ymm9
        vpand 32*10(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm10, %ymm10
        vpand 32*11(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm11, %ymm11
        vpand 32*12(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm12, %ymm12
        vpand 32*13(in_t), %ymm14, %ymm15
        vpxor %ymm15, %ymm13, %ymm13

        lea 32*14(in_t), in_t

        dec limit
        jnz 1b

    vmovdqa .Lperm3(%rip), %ymm14
    vmovdqa .Lperm4(%rip), %ymm15

    vpermd %ymm0, %ymm14, %ymm14
    vpermd %ymm0, %ymm15, %ymm0
    vpand .LAndMask_768(%rip), %ymm14, %ymm14
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vmovdqa %ymm14, 32*0(res)
    vmovdqa %ymm0, 32*1(res)

    vmovdqa .Lperm3(%rip), %ymm14

    vpermd %ymm1, %ymm14, %ymm0
    vpermd %ymm1, %ymm15, %ymm1
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm1, %ymm1
    vmovdqa %ymm0, 32*2(res)
    vmovdqa %ymm1, 32*3(res)

    vpermd %ymm2, %ymm14, %ymm0
    vpermd %ymm2, %ymm15, %ymm2
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm2, %ymm2
    vmovdqa %ymm0, 32*4(res)
    vmovdqa %ymm2, 32*5(res)

    vpermd %ymm3, %ymm14, %ymm0
    vpermd %ymm3, %ymm15, %ymm3
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm3, %ymm3
    vmovdqa %ymm0, 32*6(res)
    vmovdqa %ymm3, 32*7(res)

    vpermd %ymm4, %ymm14, %ymm0
    vpermd %ymm4, %ymm15, %ymm4
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm4, %ymm4
    vmovdqa %ymm0, 32*8(res)
    vmovdqa %ymm4, 32*9(res)

    vpermd %ymm5, %ymm14, %ymm0
    vpermd %ymm5, %ymm15, %ymm5
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm5, %ymm5
    vmovdqa %ymm0, 32*10(res)
    vmovdqa %ymm5, 32*11(res)

    vpermd %ymm6, %ymm14, %ymm0
    vpermd %ymm6, %ymm15, %ymm6
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm6, %ymm6
    vmovdqa %ymm0, 32*12(res)
    vmovdqa %ymm6, 32*13(res)

    vpermd %ymm7, %ymm14, %ymm0
    vpermd %ymm7, %ymm15, %ymm7
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm7, %ymm7
    vmovdqa %ymm0, 32*14(res)
    vmovdqa %ymm7, 32*15(res)

    vpermd %ymm8, %ymm14, %ymm0
    vpermd %ymm8, %ymm15, %ymm8
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm8, %ymm8
    vmovdqa %ymm0, 32*16(res)
    vmovdqa %ymm8, 32*17(res)

    vpermd %ymm9, %ymm14, %ymm0
    vpermd %ymm9, %ymm15, %ymm9
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm9, %ymm9
    vmovdqa %ymm0, 32*18(res)
    vmovdqa %ymm9, 32*19(res)

    vpermd %ymm10, %ymm14, %ymm0
    vpermd %ymm10, %ymm15, %ymm10
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm10, %ymm10
    vmovdqa %ymm0, 32*20(res)
    vmovdqa %ymm10, 32*21(res)

    vpermd %ymm11, %ymm14, %ymm0
    vpermd %ymm11, %ymm15, %ymm11
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm11, %ymm11
    vmovdqa %ymm0, 32*22(res)
    vmovdqa %ymm11, 32*23(res)

    vpermd %ymm12, %ymm14, %ymm0
    vpermd %ymm12, %ymm15, %ymm12
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vpand .LAndMask_768(%rip), %ymm12, %ymm12
    vmovdqa %ymm0, 32*24(res)
    vmovdqa %ymm12, 32*25(res)

    vpermd %ymm13, %ymm14, %ymm0
    vpand .LAndMask_768(%rip), %ymm0, %ymm0
    vmovdqa %ymm0, 32*26(res)

    mov %rbp, %rsp
    pop %rbp

    ret

.size SELECT_768,.-SELECT_768
################################################################################
################################################################################
#void STORE_768(
.set table, %rdi # const uint64_t *table,
.set inx4, %rsi  # uint64_t *inx4,
.set idx, %rdx   # int idx;

 .type STORE_768,@function
.align 64
.globl STORE_768
STORE_768:

    mov $28*4*4, %rax # Each operand is 27 redundant words, each word occupies 4 bytes, 4 operands. We pad to 28 words.
    mulq idx
    add %rax, table

    vmovdqu .Lperm1(%rip), %ymm10
    vmovdqu .Lperm2(%rip), %ymm11

    vmovdqu 32*0(inx4), %ymm0
    vmovdqu 32*1(inx4), %ymm1
    vmovdqu 32*2(inx4), %ymm2
    vmovdqu 32*3(inx4), %ymm3
    vmovdqu 32*4(inx4), %ymm4
    vmovdqu 32*5(inx4), %ymm5
    vmovdqu 32*6(inx4), %ymm6
    vmovdqu 32*7(inx4), %ymm7
    vmovdqu 32*8(inx4), %ymm8
    vmovdqu 32*9(inx4), %ymm9

    vpermd %ymm0, %ymm10, %ymm0
    vpermd %ymm1, %ymm11, %ymm1
    vpermd %ymm2, %ymm10, %ymm2
    vpermd %ymm3, %ymm11, %ymm3
    vpermd %ymm4, %ymm10, %ymm4
    vpermd %ymm5, %ymm11, %ymm5
    vpermd %ymm6, %ymm10, %ymm6
    vpermd %ymm7, %ymm11, %ymm7
    vpermd %ymm8, %ymm10, %ymm8
    vpermd %ymm9, %ymm11, %ymm9

    vpblendd $0xf0, %ymm1, %ymm0, %ymm0
    vpblendd $0xf0, %ymm3, %ymm2, %ymm1
    vpblendd $0xf0, %ymm5, %ymm4, %ymm2
    vpblendd $0xf0, %ymm7, %ymm6, %ymm3
    vpblendd $0xf0, %ymm9, %ymm8, %ymm4

    vmovdqu %ymm0, 32*0(table)
    vmovdqu %ymm1, 32*1(table)
    vmovdqu %ymm2, 32*2(table)
    vmovdqu %ymm3, 32*3(table)
    vmovdqu %ymm4, 32*4(table)

    vmovdqu 32*10(inx4), %ymm0
    vmovdqu 32*11(inx4), %ymm1
    vmovdqu 32*12(inx4), %ymm2
    vmovdqu 32*13(inx4), %ymm3
    vmovdqu 32*14(inx4), %ymm4
    vmovdqu 32*15(inx4), %ymm5
    vmovdqu 32*16(inx4), %ymm6
    vmovdqu 32*17(inx4), %ymm7

    vpermd %ymm0, %ymm10, %ymm0
    vpermd %ymm1, %ymm11, %ymm1
    vpermd %ymm2, %ymm10, %ymm2
    vpermd %ymm3, %ymm11, %ymm3
    vpermd %ymm4, %ymm10, %ymm4
    vpermd %ymm5, %ymm11, %ymm5
    vpermd %ymm6, %ymm10, %ymm6
    vpermd %ymm7, %ymm11, %ymm7

    vpblendd $0xf0, %ymm1, %ymm0, %ymm0
    vpblendd $0xf0, %ymm3, %ymm2, %ymm1
    vpblendd $0xf0, %ymm5, %ymm4, %ymm2
    vpblendd $0xf0, %ymm7, %ymm6, %ymm3

    vmovdqu %ymm0, 32*5(table)
    vmovdqu %ymm1, 32*6(table)
    vmovdqu %ymm2, 32*7(table)
    vmovdqu %ymm3, 32*8(table)

    vmovdqu 32*18(inx4), %ymm0
    vmovdqu 32*19(inx4), %ymm1
    vmovdqu 32*20(inx4), %ymm2
    vmovdqu 32*21(inx4), %ymm3
    vmovdqu 32*22(inx4), %ymm4
    vmovdqu 32*23(inx4), %ymm5
    vmovdqu 32*24(inx4), %ymm6
    vmovdqu 32*25(inx4), %ymm7
    vmovdqu 32*26(inx4), %ymm8

    vpermd %ymm0, %ymm10, %ymm0
    vpermd %ymm1, %ymm11, %ymm1
    vpermd %ymm2, %ymm10, %ymm2
    vpermd %ymm3, %ymm11, %ymm3
    vpermd %ymm4, %ymm10, %ymm4
    vpermd %ymm5, %ymm11, %ymm5
    vpermd %ymm6, %ymm10, %ymm6
    vpermd %ymm7, %ymm11, %ymm7
    vpermd %ymm8, %ymm10, %ymm8
    vpxor %ymm9, %ymm9, %ymm9

    vpblendd $0xf0, %ymm1, %ymm0, %ymm0
    vpblendd $0xf0, %ymm3, %ymm2, %ymm1
    vpblendd $0xf0, %ymm5, %ymm4, %ymm2
    vpblendd $0xf0, %ymm7, %ymm6, %ymm3
    vpblendd $0xf0, %ymm9, %ymm8, %ymm4

    vmovdqu %ymm0, 32*9(table)
    vmovdqu %ymm1, 32*10(table)
    vmovdqu %ymm2, 32*11(table)
    vmovdqu %ymm3, 32*12(table)
    vmovdqu %ymm4, 32*13(table)
    ret

.size STORE_768,.-STORE_768
################################################################################
################################################################################
#void AMM_WW_768_x4(
.set rpx4, %rdi # uint64_t *rpx4,
.set apx4, %rsi # const uint64_t *apx4,
.set bpx4, %rdx # const uint64_t *bpx4,
.set npx4, %rcx # const uint64_t *npx4,
.set k0x4, %r8  # const uint64_t *k0x4);

 .type AMM_WW_768_x4,@function
.globl AMM_WW_768_x4
.align 64
AMM_WW_768_x4:

# Macro for multiply-accumulate
.macro vpimac Src1, Src2, Dst
    vpmuludq \Src1, \Src2, T0
    vpaddq T0, \Dst, \Dst
.endm

.macro itr0 i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13
    vmovdqu 32*\i(bpx4), B0

    vpimac 32*0(apx4), B0, \a0
    vpimac 32*1(apx4), B0, \a1
    vpimac 32*2(apx4), B0, \a2
    vpimac 32*3(apx4), B0, \a3
    vpimac 32*4(apx4), B0, \a4
    vpimac 32*5(apx4), B0, \a5
    vpimac 32*6(apx4), B0, \a6
    vpimac 32*7(apx4), B0, \a7
    vpimac 32*8(apx4), B0, \a8
    vpimac 32*9(apx4), B0, \a9
    vpimac 32*10(apx4), B0, \a10
    vpimac 32*11(apx4), B0, \a11
    vpimac 32*12(apx4), B0, \a12
    vpmuludq 32*13(apx4), B0, \a13
        
    vpmuludq (k0x4), \a0, B0
    vpand .LAndMask_768(%rip), B0, B0
    vmovdqa B0, 32*\i(%rsp)

    vpimac 32*0(npx4), B0, \a0
    vpimac 32*1(npx4), B0, \a1
    vpimac 32*2(npx4), B0, \a2
    vpimac 32*3(npx4), B0, \a3
    vpimac 32*4(npx4), B0, \a4
    vpimac 32*5(npx4), B0, \a5
    vpimac 32*6(npx4), B0, \a6
    vpimac 32*7(npx4), B0, \a7
    vpimac 32*8(npx4), B0, \a8
    vpimac 32*9(npx4), B0, \a9
    vpimac 32*10(npx4), B0, \a10
    vpimac 32*11(npx4), B0, \a11
    vpimac 32*12(npx4), B0, \a12
    vpimac 32*13(npx4), B0, \a13

    vpsrlq $29, \a0, \a0
    vpaddq \a0, \a1, \a1
.endm

.macro itr1 i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12,a13
    vmovdqu 32*\i(bpx4), B0

    vpimac 32*0(apx4), B0, \a0
    vpimac 32*1(apx4), B0, \a1
    vpimac 32*2(apx4), B0, \a2
    vpimac 32*3(apx4), B0, \a3
    vpimac 32*4(apx4), B0, \a4
    vpimac 32*5(apx4), B0, \a5
    vpimac 32*6(apx4), B0, \a6
    vpimac 32*7(apx4), B0, \a7
    vpimac 32*8(apx4), B0, \a8
    vpimac 32*9(apx4), B0, \a9
    vpimac 32*10(apx4), B0, \a10
    vpimac 32*11(apx4), B0, \a11
    vpimac 32*12(apx4), B0, \a12
    vpimac 32*13(apx4), B0, \a13

    vpmuludq (k0x4), \a0, B0
    vpand .LAndMask_768(%rip), B0, B0
    vmovdqa B0, 32*\i(%rsp)

    vpimac 32*0(npx4), B0, \a0
    vpimac 32*1(npx4), B0, \a1
    vpimac 32*2(npx4), B0, \a2
    vpimac 32*3(npx4), B0, \a3
    vpimac 32*4(npx4), B0, \a4
    vpimac 32*5(npx4), B0, \a5
    vpimac 32*6(npx4), B0, \a6
    vpimac 32*7(npx4), B0, \a7
    vpimac 32*8(npx4), B0, \a8
    vpimac 32*9(npx4), B0, \a9
    vpimac 32*10(npx4), B0, \a10
    vpimac 32*11(npx4), B0, \a11
    vpimac 32*12(npx4), B0, \a12
    vpimac 32*13(npx4), B0, \a13

    vpsrlq $29, \a0, \a0
    vpaddq \a0, \a1, \a1
.endm

.macro missing0 i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12
    vmovdqu 32*\i(bpx4), B0
    vpimac 32*14(apx4), B0, \a0
    vpimac 32*15(apx4), B0, \a1
    vpimac 32*16(apx4), B0, \a2
    vpimac 32*17(apx4), B0, \a3
    vpimac 32*18(apx4), B0, \a4
    vpimac 32*19(apx4), B0, \a5
    vpimac 32*20(apx4), B0, \a6
    vpimac 32*21(apx4), B0, \a7
    vpimac 32*22(apx4), B0, \a8
    vpimac 32*23(apx4), B0, \a9
    vpimac 32*24(apx4), B0, \a10
    vpimac 32*25(apx4), B0, \a11
    vpimac 32*26(apx4), B0, \a12

    vmovdqu 32*\i(%rsp), B0
    vpimac 32*14(npx4), B0, \a0
    vpimac 32*15(npx4), B0, \a1
    vpimac 32*16(npx4), B0, \a2
    vpimac 32*17(npx4), B0, \a3
    vpimac 32*18(npx4), B0, \a4
    vpimac 32*19(npx4), B0, \a5
    vpimac 32*20(npx4), B0, \a6
    vpimac 32*21(npx4), B0, \a7
    vpimac 32*22(npx4), B0, \a8
    vpimac 32*23(npx4), B0, \a9
    vpimac 32*24(npx4), B0, \a10
    vpimac 32*25(npx4), B0, \a11
    vpimac 32*26(npx4), B0, \a12
.endm

.macro missing3 i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11,a12
    vmovdqu 32*\i(bpx4), B0
    vpimac 32*14(apx4), B0, \a0
    vpimac 32*15(apx4), B0, \a1
    vpimac 32*16(apx4), B0, \a2
    vpimac 32*17(apx4), B0, \a3
    vpimac 32*18(apx4), B0, \a4
    vpimac 32*19(apx4), B0, \a5
    vpimac 32*20(apx4), B0, \a6
    vpimac 32*21(apx4), B0, \a7
    vpimac 32*22(apx4), B0, \a8
    vpimac 32*23(apx4), B0, \a9
    vpimac 32*24(apx4), B0, \a10
    vpimac 32*25(apx4), B0, \a11
    vpmuludq 32*26(apx4), B0, \a12

    vmovdqu 32*\i(%rsp), B0
    vpimac 32*14(npx4), B0, \a0
    vpimac 32*15(npx4), B0, \a1
    vpimac 32*16(npx4), B0, \a2
    vpimac 32*17(npx4), B0, \a3
    vpimac 32*18(npx4), B0, \a4
    vpimac 32*19(npx4), B0, \a5
    vpimac 32*20(npx4), B0, \a6
    vpimac 32*21(npx4), B0, \a7
    vpimac 32*22(npx4), B0, \a8
    vpimac 32*23(npx4), B0, \a9
    vpimac 32*24(npx4), B0, \a10
    vpimac 32*25(npx4), B0, \a11
    vpimac 32*26(npx4), B0, \a12
.endm

.macro fix_store i,a0,a1
    vpand .LAndMask_768(%rip), \a0, T0
    vmovdqu T0, 32*\i(rpx4)
    vpsrlq $29, \a0, \a0
    vpaddq \a0, \a1, \a1
.endm

.set B0, %ymm0
.set T0, %ymm3

.set ACC0, %ymm4
.set ACC1, %ymm5
.set ACC2, %ymm6
.set ACC3, %ymm7
.set ACC4, %ymm8
.set ACC5, %ymm9
.set ACC6, %ymm10
.set ACC7, %ymm11
.set ACC8, %ymm12
.set ACC9, %ymm13
.set ACC10, %ymm14
.set ACC11, %ymm15
.set ACC12, %ymm1
.set ACC13, %ymm2

    lea (%rsp), %rax
    sub $27*32, %rsp
    and $-32, %rsp

    # itr 0
    vmovdqu 32*0(bpx4), B0

    vpmuludq 32*0(apx4), B0, ACC0
    vpmuludq 32*1(apx4), B0, ACC1
    vpmuludq 32*2(apx4), B0, ACC2
    vpmuludq 32*3(apx4), B0, ACC3
    vpmuludq 32*4(apx4), B0, ACC4
    vpmuludq 32*5(apx4), B0, ACC5
    vpmuludq 32*6(apx4), B0, ACC6
    vpmuludq 32*7(apx4), B0, ACC7
    vpmuludq 32*8(apx4), B0, ACC8
    vpmuludq 32*9(apx4), B0, ACC9
    vpmuludq 32*10(apx4), B0, ACC10
    vpmuludq 32*11(apx4), B0, ACC11
    vpmuludq 32*12(apx4), B0, ACC12
    vpmuludq 32*13(apx4), B0, ACC13

    vpmuludq (k0x4), ACC0, B0
    vpand .LAndMask_768(%rip), B0, B0
    vmovdqa B0, 32*0(%rsp)

    vpimac 32*0(npx4), B0, ACC0
    vpimac 32*1(npx4), B0, ACC1
    vpimac 32*2(npx4), B0, ACC2
    vpimac 32*3(npx4), B0, ACC3
    vpimac 32*4(npx4), B0, ACC4
    vpimac 32*5(npx4), B0, ACC5
    vpimac 32*6(npx4), B0, ACC6
    vpimac 32*7(npx4), B0, ACC7
    vpimac 32*8(npx4), B0, ACC8
    vpimac 32*9(npx4), B0, ACC9
    vpimac 32*10(npx4), B0, ACC10
    vpimac 32*11(npx4), B0, ACC11
    vpimac 32*12(npx4), B0, ACC12
    vpimac 32*13(npx4), B0, ACC13

    vpsrlq $29, ACC0, ACC0
    vpaddq ACC0, ACC1, ACC1

    itr0 1,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0
    itr0 2,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1
    itr0 3,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2
    itr0 4,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3
    itr0 5,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4
    itr0 6,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5
    itr0 7,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6
    itr0 8,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7
    itr0 9,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8
    itr0 10,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9
    itr0 11,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10
    itr0 12,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11
    itr0 13,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12

    missing0 0,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12
    itr0 14,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13
    missing0 1,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13
    itr0 15,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0
    missing0 2,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0
    itr0 16,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1
    missing0 3,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1
    itr0 17,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2
    missing0 4,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2
    itr0 18,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3
    missing0 5,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3
    itr0 19,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4
    missing0 6,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4
    itr0 20,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5
    missing0 7,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5
    itr0 21,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6
    missing0 8,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6
    itr0 22,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7
    missing0 9,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7
    itr0 23,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8
    missing0 10,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8
    itr0 24,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9
    missing0 11,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9
    itr0 25,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10
    missing0 12,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10
    itr0 26,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11
    missing0 13,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11

    fix_store 0, ACC13, ACC0
    missing3 14,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12
    fix_store 1, ACC0, ACC1
    missing3 15,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13
    fix_store 2, ACC1, ACC2
    missing3 16,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0
    fix_store 3, ACC2, ACC3
    missing3 17,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1
    fix_store 4, ACC3, ACC4
    missing3 18,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2
    fix_store 5, ACC4, ACC5
    missing3 19,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3
    fix_store 6, ACC5, ACC6
    missing3 20,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4
    fix_store 7, ACC6, ACC7
    missing3 21,ACC7,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5
    fix_store 8, ACC7, ACC8
    missing3 22,ACC8,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6
    fix_store 9, ACC8, ACC9
    missing3 23,ACC9,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7
    fix_store 10, ACC9, ACC10
    missing3 24,ACC10,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8
    fix_store 11, ACC10, ACC11
    missing3 25,ACC11,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9
    fix_store 12, ACC11, ACC12
    missing3 26,ACC12,ACC13,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10
    fix_store 13, ACC12, ACC13
    fix_store 14, ACC13, ACC0
    fix_store 15, ACC0, ACC1
    fix_store 16, ACC1, ACC2
    fix_store 17, ACC2, ACC3
    fix_store 18, ACC3, ACC4
    fix_store 19, ACC4, ACC5
    fix_store 20, ACC5, ACC6
    fix_store 21, ACC6, ACC7
    fix_store 22, ACC7, ACC8
    fix_store 23, ACC8, ACC9
    fix_store 24, ACC9, ACC10
    vpand .LAndMask_768(%rip), ACC10, T0
    vmovdqu T0, 32*25(rpx4)
    vpsrlq $29, ACC10, ACC10
    vmovdqu ACC10, 32*26(rpx4)
1:
    mov %rax, %rsp
    ret
.size AMM_WW_768_x4,.-AMM_WW_768_x4
################################################################################
################################################################################
#void AMS_WW_768_x4(
.set rpx4, %rdi # uint64_t *rpx4,
.set apx4, %rsi # const uint64_t *apx4,
.set npx4, %rdx # const uint64_t *npx4,
.set k0x4, %rcx # const uint64_t *k0x4
.set times, %r8 # int repeat);

 .type AMS_WW_768_x4,@function
.globl AMS_WW_768_x4
.align 64
AMS_WW_768_x4:

    mov %r8, %r9
    mov %rcx, %r8
    mov %rdx, %rcx
    mov %rsi, %rdx
    call AMM_WW_768_x4
    dec %r9

    mov %rdi, %rsi
    mov %rdi, %rdx

    test %r9, %r9
    jz bail_sqr

loop_sqr:
    call AMM_WW_768_x4
    dec %r9
    jnz loop_sqr

bail_sqr:
    ret
.macro red0 i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11
    vpmuludq K0, \a0, Y0
    vpand .LAndMask_768(%rip), Y0, Y0
    vmovdqa Y0, 32*\i(%rsp)

    vpimac 32*0(npx4), Y0, \a0
    vpimac 32*1(npx4), Y0, \a1
    vpimac 32*2(npx4), Y0, \a2
    vpimac 32*3(npx4), Y0, \a3
    vpimac 32*4(npx4), Y0, \a4
    vpimac 32*5(npx4), Y0, \a5
    vpimac 32*6(npx4), Y0, \a6
    vpimac 32*7(npx4), Y0, \a7
    vpimac 32*8(npx4), Y0, \a8
    vpimac 32*9(npx4), Y0, \a9
    vpimac 32*10(npx4), Y0, \a10
    vpimac 32*11(npx4), Y0, \a11

    vpsrlq $29, \a0, \a0
    vpaddq \a0, \a1, \a1
.endm
.macro red1 i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11
    vpmuludq K0, \a0, Y0
    vpand .LAndMask_768(%rip), Y0, Y0
    vmovdqa Y0, 32*\i(%rsp)

    vpimac 32*0(npx4), Y0, \a0
    vpimac 32*1(npx4), Y0, \a1
    vpimac 32*2(npx4), Y0, \a2
    vpimac 32*3(npx4), Y0, \a3
    vpimac 32*4(npx4), Y0, \a4
    vpimac 32*5(npx4), Y0, \a5
    vpimac 32*6(npx4), Y0, \a6
    vpimac 32*7(npx4), Y0, \a7
    vpimac 32*8(npx4), Y0, \a8
    vpimac 32*9(npx4), Y0, \a9
    vpimac 32*10(npx4), Y0, \a10
    vpmuludq 32*11(npx4), Y0, \a11

    vpsrlq $29, \a0, \a0
    vpaddq \a0, \a1, \a1
.endm

.macro missing1 i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11
    vmovdqu 32*\i(apx4), B0
    vpsllq $1, B0, B0
    vpimac 32*12(apx4), B0, \a0
    vpimac 32*13(apx4), B0, \a1
    vpimac 32*14(apx4), B0, \a2
    vpimac 32*15(apx4), B0, \a3
    vpimac 32*16(apx4), B0, \a4
    vpimac 32*17(apx4), B0, \a5
    vpimac 32*18(apx4), B0, \a6
    vpimac 32*19(apx4), B0, \a7
    vpimac 32*20(apx4), B0, \a8
    vpimac 32*21(apx4), B0, \a9
    vpimac 32*22(apx4), B0, \a10
    vpmuludq 32*23(apx4), B0, \a11

    vmovdqu 32*\i(%rsp), Y0
    vpimac 32*12(npx4), Y0, \a0
    vpimac 32*13(npx4), Y0, \a1
    vpimac 32*14(npx4), Y0, \a2
    vpimac 32*15(npx4), Y0, \a3
    vpimac 32*16(npx4), Y0, \a4
    vpimac 32*17(npx4), Y0, \a5
    vpimac 32*18(npx4), Y0, \a6
    vpimac 32*19(npx4), Y0, \a7
    vpimac 32*20(npx4), Y0, \a8
    vpimac 32*21(npx4), Y0, \a9
    vpimac 32*22(npx4), Y0, \a10
    vpimac 32*23(npx4), Y0, \a11
.endm

.macro missing2 i,a0,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10,a11
    vmovdqu 32*\i(%rsp), Y0
    vpimac 32*12(npx4), Y0, \a0
    vpimac 32*13(npx4), Y0, \a1
    vpimac 32*14(npx4), Y0, \a2
    vpimac 32*15(npx4), Y0, \a3
    vpimac 32*16(npx4), Y0, \a4
    vpimac 32*17(npx4), Y0, \a5
    vpimac 32*18(npx4), Y0, \a6
    vpimac 32*19(npx4), Y0, \a7
    vpimac 32*20(npx4), Y0, \a8
    vpimac 32*21(npx4), Y0, \a9
    vpimac 32*22(npx4), Y0, \a10
    vpimac 32*23(npx4), Y0, \a11
.endm

.set B0, %ymm0
.set K0, %ymm1
.set Y0, %ymm2
.set T0, %ymm3

.set ACC0, %ymm4
.set ACC1, %ymm5
.set ACC2, %ymm6
.set ACC3, %ymm7
.set ACC4, %ymm8
.set ACC5, %ymm9
.set ACC6, %ymm10
.set ACC7, %ymm11
.set ACC8, %ymm12
.set ACC9, %ymm13
.set ACC10, %ymm14
.set ACC11, %ymm15

    lea (%rsp), %rax
    sub $36*32, %rsp
    and $-32, %rsp

    vmovdqu (k0x4), K0

1:
    vmovdqu 32*0(apx4), B0
    vpmuludq B0, B0, ACC0
    vpsllq $1, B0, B0
    vpmuludq 32*1(apx4), B0, ACC1
    vpmuludq 32*2(apx4), B0, ACC2
    vpmuludq 32*3(apx4), B0, ACC3
    vpmuludq 32*4(apx4), B0, ACC4
    vpmuludq 32*5(apx4), B0, ACC5
    vpmuludq 32*6(apx4), B0, ACC6
    vpmuludq 32*7(apx4), B0, ACC7
    vpmuludq 32*8(apx4), B0, ACC8
    vpmuludq 32*9(apx4), B0, ACC9
    vpmuludq 32*10(apx4), B0, ACC10
    vpmuludq 32*11(apx4), B0, ACC11
    red0 0,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11

    vmovdqu 32*1(apx4), B0
    vpimac B0, B0, ACC2
    vpsllq $1, B0, B0
    vpimac 32*2(apx4), B0, ACC3
    vpimac 32*3(apx4), B0, ACC4
    vpimac 32*4(apx4), B0, ACC5
    vpimac 32*5(apx4), B0, ACC6
    vpimac 32*6(apx4), B0, ACC7
    vpimac 32*7(apx4), B0, ACC8
    vpimac 32*8(apx4), B0, ACC9
    vpimac 32*9(apx4), B0, ACC10
    vpimac 32*10(apx4), B0, ACC11
    vpmuludq 32*11(apx4), B0, ACC0
    red0 1,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0

    vmovdqu 32*2(apx4), B0
    vpimac B0, B0, ACC4
    vpsllq $1, B0, B0
    vpimac 32*3(apx4), B0, ACC5
    vpimac 32*4(apx4), B0, ACC6
    vpimac 32*5(apx4), B0, ACC7
    vpimac 32*6(apx4), B0, ACC8
    vpimac 32*7(apx4), B0, ACC9
    vpimac 32*8(apx4), B0, ACC10
    vpimac 32*9(apx4), B0, ACC11
    vpimac 32*10(apx4), B0, ACC0
    vpmuludq 32*11(apx4), B0, ACC1
    red0 2,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1


    vmovdqu 32*3(apx4), B0
    vpimac B0, B0, ACC6
    vpsllq $1, B0, B0
    vpimac 32*4(apx4), B0, ACC7
    vpimac 32*5(apx4), B0, ACC8
    vpimac 32*6(apx4), B0, ACC9
    vpimac 32*7(apx4), B0, ACC10
    vpimac 32*8(apx4), B0, ACC11
    vpimac 32*9(apx4), B0, ACC0
    vpimac 32*10(apx4), B0, ACC1
    vpmuludq 32*11(apx4), B0, ACC2
    red0 3,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2

    vmovdqu 32*4(apx4), B0
    vpimac B0, B0, ACC8
    vpsllq $1, B0, B0
    vpimac 32*5(apx4), B0, ACC9
    vpimac 32*6(apx4), B0, ACC10
    vpimac 32*7(apx4), B0, ACC11
    vpimac 32*8(apx4), B0, ACC0
    vpimac 32*9(apx4), B0, ACC1
    vpimac 32*10(apx4), B0, ACC2
    vpmuludq 32*11(apx4), B0, ACC3
    red0 4,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3

    vmovdqu 32*5(apx4), B0
    vpimac B0, B0, ACC10
    vpsllq $1, B0, B0
    vpimac 32*6(apx4), B0, ACC11
    vpimac 32*7(apx4), B0, ACC0
    vpimac 32*8(apx4), B0, ACC1
    vpimac 32*9(apx4), B0, ACC2
    vpimac 32*10(apx4), B0, ACC3
    vpmuludq 32*11(apx4), B0, ACC4
    red0 5,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4

    vmovdqu 32*6(apx4), B0
    vpimac B0, B0, ACC0
    vpsllq $1, B0, B0
    vpimac 32*7(apx4), B0, ACC1
    vpimac 32*8(apx4), B0, ACC2
    vpimac 32*9(apx4), B0, ACC3
    vpimac 32*10(apx4), B0, ACC4
    vpmuludq 32*11(apx4), B0, ACC5
    red0 6,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5

    vmovdqu 32*7(apx4), B0
    vpimac B0, B0, ACC2
    vpsllq $1, B0, B0
    vpimac 32*8(apx4), B0, ACC3
    vpimac 32*9(apx4), B0, ACC4
    vpimac 32*10(apx4), B0, ACC5
    vpmuludq 32*11(apx4), B0, ACC6
    red0 7,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6

    vmovdqu 32*8(apx4), B0
    vpimac B0, B0, ACC4
    vpsllq $1, B0, B0
    vpimac 32*9(apx4), B0, ACC5
    vpimac 32*10(apx4), B0, ACC6
    vpmuludq 32*11(apx4), B0, ACC7
    red0 8,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7

    vmovdqu 32*9(apx4), B0
    vpimac B0, B0, ACC6
    vpsllq $1, B0, B0
    vpimac 32*10(apx4), B0, ACC7
    vpmuludq 32*11(apx4), B0, ACC8
    red0 9,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8

    vmovdqu 32*10(apx4), B0
    vpimac B0, B0, ACC8
    vpsllq $1, B0, B0
    vpmuludq 32*11(apx4), B0, ACC9
    red0 10,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9

    vmovdqu 32*11(apx4), B0
    vpmuludq B0, B0, ACC10
    red0 11,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10

    missing1 0,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11
    red0 12,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11
    missing1 1,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0
    red0 13,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0
    missing1 2,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1
    red0 14,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1
    missing1 3,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2
    red0 15,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2
    missing1 4,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3
    red0 16,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3
    missing1 5,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4
    red0 17,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4
    missing1 6,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5
    red0 18,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5
    missing1 7,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6
    red0 19,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6
    missing1 8,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7
    red0 20,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7
    missing1 9,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8
    red0 21,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8
    missing1 10,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9
    red0 22,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9
    missing1 11,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10
    red0 23,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10

    vmovdqu 32*12(apx4), B0
    vpimac B0, B0, ACC0
    vpsllq $1, B0, B0
    vpimac 32*13(apx4), B0, ACC1
    vpimac 32*14(apx4), B0, ACC2
    vpimac 32*15(apx4), B0, ACC3
    vpimac 32*16(apx4), B0, ACC4
    vpimac 32*17(apx4), B0, ACC5
    vpimac 32*18(apx4), B0, ACC6
    vpimac 32*19(apx4), B0, ACC7
    vpimac 32*20(apx4), B0, ACC8
    vpimac 32*21(apx4), B0, ACC9
    vpimac 32*22(apx4), B0, ACC10
    vpmuludq 32*23(apx4), B0, ACC11
    missing2 12,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11
    fix_store 0, ACC0, ACC1

    vmovdqu 32*13(apx4), B0
    vpimac B0, B0, ACC2
    vpsllq $1, B0, B0
    vpimac 32*14(apx4), B0, ACC3
    vpimac 32*15(apx4), B0, ACC4
    vpimac 32*16(apx4), B0, ACC5
    vpimac 32*17(apx4), B0, ACC6
    vpimac 32*18(apx4), B0, ACC7
    vpimac 32*19(apx4), B0, ACC8
    vpimac 32*20(apx4), B0, ACC9
    vpimac 32*21(apx4), B0, ACC10
    vpimac 32*22(apx4), B0, ACC11
    vpmuludq 32*23(apx4), B0, ACC0
    missing2 13,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0
    fix_store 1, ACC1, ACC2

    vmovdqu 32*14(apx4), B0
    vpimac B0, B0, ACC4
    vpsllq $1, B0, B0
    vpimac 32*15(apx4), B0, ACC5
    vpimac 32*16(apx4), B0, ACC6
    vpimac 32*17(apx4), B0, ACC7
    vpimac 32*18(apx4), B0, ACC8
    vpimac 32*19(apx4), B0, ACC9
    vpimac 32*20(apx4), B0, ACC10
    vpimac 32*21(apx4), B0, ACC11
    vpimac 32*22(apx4), B0, ACC0
    vpmuludq 32*23(apx4), B0, ACC1
    missing2 14,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1
    fix_store 2, ACC2, ACC3

    vmovdqu 32*15(apx4), B0
    vpimac B0, B0, ACC6
    vpsllq $1, B0, B0
    vpimac 32*16(apx4), B0, ACC7
    vpimac 32*17(apx4), B0, ACC8
    vpimac 32*18(apx4), B0, ACC9
    vpimac 32*19(apx4), B0, ACC10
    vpimac 32*20(apx4), B0, ACC11
    vpimac 32*21(apx4), B0, ACC0
    vpimac 32*22(apx4), B0, ACC1
    vpmuludq 32*23(apx4), B0, ACC2
    missing2 15,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2
    fix_store 3, ACC3, ACC4

    vmovdqu 32*16(apx4), B0
    vpimac B0, B0, ACC8
    vpsllq $1, B0, B0
    vpimac 32*17(apx4), B0, ACC9
    vpimac 32*18(apx4), B0, ACC10
    vpimac 32*19(apx4), B0, ACC11
    vpimac 32*20(apx4), B0, ACC0
    vpimac 32*21(apx4), B0, ACC1
    vpimac 32*22(apx4), B0, ACC2
    vpmuludq 32*23(apx4), B0, ACC3
    missing2 16,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3
    fix_store 4, ACC4, ACC5

    vmovdqu 32*17(apx4), B0
    vpimac B0, B0, ACC10
    vpsllq $1, B0, B0
    vpimac 32*18(apx4), B0, ACC11
    vpimac 32*19(apx4), B0, ACC0
    vpimac 32*20(apx4), B0, ACC1
    vpimac 32*21(apx4), B0, ACC2
    vpimac 32*22(apx4), B0, ACC3
    vpmuludq 32*23(apx4), B0, ACC4
    missing2 17,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4
    fix_store 5, ACC5, ACC6

    vmovdqu 32*18(apx4), B0
    vpimac B0, B0, ACC0
    vpsllq $1, B0, B0
    vpimac 32*19(apx4), B0, ACC1
    vpimac 32*20(apx4), B0, ACC2
    vpimac 32*21(apx4), B0, ACC3
    vpimac 32*22(apx4), B0, ACC4
    vpmuludq 32*23(apx4), B0, ACC5
    missing2 18,ACC6,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5
    fix_store 6, ACC6, ACC7

    vmovdqu 32*19(apx4), B0
    vpimac B0, B0, ACC2
    vpsllq $1, B0, B0
    vpimac 32*20(apx4), B0, ACC3
    vpimac 32*21(apx4), B0, ACC4
    vpimac 32*22(apx4), B0, ACC5
    vpmuludq 32*23(apx4), B0, ACC6
    missing2 19,ACC7,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6
    fix_store 7, ACC7, ACC8

    vmovdqu 32*20(apx4), B0
    vpimac B0, B0, ACC4
    vpsllq $1, B0, B0
    vpimac 32*21(apx4), B0, ACC5
    vpimac 32*22(apx4), B0, ACC6
    vpmuludq 32*23(apx4), B0, ACC7
    missing2 20,ACC8,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7
    fix_store 8, ACC8, ACC9

    vmovdqu 32*21(apx4), B0
    vpimac B0, B0, ACC6
    vpsllq $1, B0, B0
    vpimac 32*22(apx4), B0, ACC7
    vpmuludq 32*23(apx4), B0, ACC8
    missing2 21,ACC9,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8
    fix_store 9, ACC9, ACC10

    vmovdqu 32*22(apx4), B0
    vpimac B0, B0, ACC8
    vpsllq $1, B0, B0
    vpmuludq 32*23(apx4), B0, ACC9
    missing2 22,ACC10,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9
    fix_store 10,ACC10, ACC11

    vmovdqu 32*23(apx4), B0
    vpmuludq B0, B0, ACC10
    missing2 23,ACC11,ACC0,ACC1,ACC2,ACC3,ACC4,ACC5,ACC6,ACC7,ACC8,ACC9,ACC10
    fix_store 11,ACC11, ACC0

    fix_store 12, ACC0, ACC1
    fix_store 13, ACC1, ACC2
    fix_store 14, ACC2, ACC3
    fix_store 15, ACC3, ACC4
    fix_store 16, ACC4, ACC5
    fix_store 17, ACC5, ACC6
    fix_store 18, ACC6, ACC7
    fix_store 19, ACC7, ACC8
    fix_store 20, ACC8, ACC9
    fix_store 21, ACC9, ACC10
    vpand .LAndMask_768(%rip), ACC10, T0
    vmovdqu T0, 32*22(rpx4)
    vpsrlq $29, ACC10, ACC11
    vmovdqu ACC11, 32*23(rpx4)

    mov rpx4, apx4
    dec times
    jnz 1b

    mov %rax, %rsp
    ret
.size AMS_WW_768_x4,.-AMS_WW_768_x4
