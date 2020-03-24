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

// Reserves space in .data for runtime ProtocolConformanceDescriptor instantiations

#ifdef __x86_64__

.const

.globl _SwiftInternals$dataSectionStorageSize
_SwiftInternals$dataSectionStorageSize:
.quad   DATA_SECTION_STORAGE_SIZE_KB * 1024

.data

.p2align 4
.globl _SwiftInternals$dataSectionStorage
_SwiftInternals$dataSectionStorage:
.rept DATA_SECTION_STORAGE_SIZE_KB * 1024
    .byte 0
.endr

#endif
