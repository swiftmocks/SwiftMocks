// This source file is part of SwiftInternals open source project.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// Copyright © 2019-2020, Sergiy Drapiko
// Copyright © 2020, SwiftMocks project contributors

#ifdef __x86_64__

.set L_bytesPerTrampolineSlot,      (L_trampolineEnd - _SwiftInternals$trampoline) / NUMBER_OF_TRAMPOLINE_SLOTS

.const

.global _SwiftInternals$numberOfTrampolineSlots
_SwiftInternals$numberOfTrampolineSlots:
    .quad   NUMBER_OF_TRAMPOLINE_SLOTS      # 64-bit

.global _SwiftInternals$bytesPerTrampolineSlot
_SwiftInternals$bytesPerTrampolineSlot:
    .quad   L_bytesPerTrampolineSlot        # 64-bit

.data

.global _SwiftInternals$trampolineDispatcher
_SwiftInternals$trampolineDispatcher:
    .quad   0                               # 64-bit

.text

.global _SwiftInternals$trampoline
_SwiftInternals$trampoline:
.rept NUMBER_OF_TRAMPOLINE_SLOTS
    call L_trampoline_dispatcher
    nop
    nop
    nop
.endr
L_trampolineEnd:

.if L_bytesPerTrampolineSlot != 8
    .error "L_assumes_8_bytes assumes it's 8!"
.endif

.global _SwiftInternals$trampolineDispatcher2
_SwiftInternals$trampolineDispatcher2:

L_trampoline_dispatcher:
    pop     %r11                            # restore stack as it was before trampoline, keeping the address of the trampoline in the scratch register

    push    %rbp
    mov     %rsp, %rbp

    sub     $8, %rsp                        # save XMMs and GPRs
    movq    %xmm7, (%rsp)
    sub     $8, %rsp
    movq    %xmm6, (%rsp)
    sub     $8, %rsp
    movq    %xmm5, (%rsp)
    sub     $8, %rsp
    movq    %xmm4, (%rsp)
    sub     $8, %rsp
    movq    %xmm3, (%rsp)
    sub     $8, %rsp
    movq    %xmm2, (%rsp)
    sub     $8, %rsp
    movq    %xmm1, (%rsp)
    sub     $8, %rsp
    movq    %xmm0, (%rsp)

    pushq   %r13                            # swiftself
    pushq   %r12                            # nest parameter (currently unused)
    pushq   %r10
    pushq   %r9
    pushq   %r8
    pushq   %rcx
    pushq   %rdx
    pushq   %rsi
    pushq   %rdi
    pushq   %rax                            # sret

    mov     _SwiftInternals$trampoline@GOTPCREL(%rip), %r10
    sub     %r10, %r11                      # offset into trampoline

L_assumes_8_bytes:
    shrq    $3, %r11                        # index = offset idiv 8

    movq    %r11, %rdi                      # param: index
    movq    %rsp, %rsi                      # param: rsp

    movq    _SwiftInternals$trampolineDispatcher@GOTPCREL(%rip), %r10
    callq   *(%r10)

    mov     %rax, %r11                      # save the result for a bit later

    popq    %rax                            # restore all registers
    popq    %rdi
    popq    %rsi
    popq    %rdx
    popq    %rcx
    popq    %r8
    popq    %r9
    popq    %r10
    popq    %r12
    popq    %r13

    movq    (%rsp), %xmm0
    addq    $8, %rsp
    movq    (%rsp), %xmm1
    addq    $8, %rsp
    movq    (%rsp), %xmm2
    addq    $8, %rsp
    movq    (%rsp), %xmm3
    addq    $8, %rsp
    movq    (%rsp), %xmm4
    addq    $8, %rsp
    movq    (%rsp), %xmm5
    addq    $8, %rsp
    movq    (%rsp), %xmm6
    addq    $8, %rsp
    movq    (%rsp), %xmm7
    addq    $8, %rsp

    leave

    cmp     $0, %r11                        # if return value of the trampoline handler (which was saved in %r11) is not 0, it is the address of the original function to tailcall
    jne      L_tailcall

    ret                                     # otherwise return; %rax and other restored registers contain the values that the handler has set up as returns for the handled functions

L_tailcall:
    jmpq    *%r11

#endif
