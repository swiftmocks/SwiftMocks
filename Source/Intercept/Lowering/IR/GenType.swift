// This source file is part of SwiftMocks open source project.
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

import Foundation

extension IRTypeConverter {
    func getExemplarType(_ contextTy: AType) -> AType {
        // non-generic code only
        return contextTy
    }
}

extension IRTypeConverter {
    var emptyTypeInfo: TypeInfo {
        EmptyTypeInfo()
    }

    func convertType(_ ty: AType) -> TypeInfo {
        switch ty.kind {
        case .existentialMetatype:
            return convertExistentialMetatypeType(ty as! ExistentialMetatypeType)
        case .metatype:
            return convertMetatypeType(ty as! MetatypeType)
        case .module:
            return convertModuleType(ty as! ModuleType)
        case .dynamicSelf:
            // DynamicSelf has the same representation as its superclass type.
            let dynamicSelf = ty as! DynamicSelfType
            let nominal = dynamicSelf.selfType as! NominalType
            return convertAnyNominalType(nominal, ())
        case .builtinNativeObject:
            return nativeObjectTypeInfo
        case .builtinUnknownObject:
            return nativeObjectTypeInfo
        case .builtinBridgeObject:
            return nativeObjectTypeInfo
        case .builtinUnsafeValueBuffer:
            return createImmovable(type: igm.fixedBufferTy, size: igm.fixedBufferSize, alignment: igm.fixedBufferAlignment)
        case .builtinRawPointer:
            return rawPointerTypeInfo
        case .builtinIntegerLiteral:
            return integerLiteralTypeInfo
        case .builtinFloat,
             .builtinInteger,
             .builtinVector:
            var (llvmTy, size, align) = IRTypeConverter.convertPrimitiveBuiltin(module: igm, type: ty)
            align = igm.cappedAlignment(align: align)
            return createPrimitive(type: llvmTy, size: size, alignment: align)
        case .primaryArchetype,
             .openedArchetype,
             .nestedArchetype,
             .opaqueTypeArchetype:
            return convertArchetypeType(ty as! ArchetypeType)
        case .class,
             .enum,
             .struct:
            return convertAnyNominalType(ty, () /* cast<NominalType>(ty)->getDecl() */)
        case .boundGenericClass,
             .boundGenericEnum,
             .boundGenericStruct:
            return convertAnyNominalType(ty, () /* cast<BoundGenericType>(ty)->getDecl() */)
        case .inOut:
            return convertInOutType(ty as! InOutType)
        case .tuple:
            return convertTupleType(ty as! TupleType)
        case .function,
             .genericFunction:
            LoweringError.unreachable("AST FunctionTypes should be lowered by SILGen");
        case .silFunction:
            return convertFunctionType(ty as! SILFunctionType)
        case .protocol:
            return convertProtocolType(ty as! ProtocolType)
        case .protocolComposition:
            return convertProtocolCompositionType(ty as! ProtocolCompositionType)
        case .genericTypeParam,
             .dependentMember:
            LoweringError.unreachable("can't convert dependent type")
        case .weakStorage:
            return convertWeakStorageType(ty as! WeakStorageType)
        case .unownedStorage:
            return convertUnownedStorageType(ty as! UnownedStorageType)
        case .unmanagedStorage:
            return convertUnmanagedStorageType(ty as! UnmanagedStorageType)
        case .silBlockStorage:
            return convertBlockStorageType(ty as! SILBlockStorageType)
        case .silBox:
            return convertBoxType(ty as! SILBoxType)
        case .silToken:
            LoweringError.unreachable("should not be asking for representation of a SILToken")
        default:
            LoweringError.unreachable("\(#function) invoked for unexpected type kind: \(ty.kind)")
        }
    }

    private func convertModuleType(_ type: ModuleType) -> TypeInfo {
        EmptyTypeInfo(.i8)
    }

    private func convertMetatypeType(_ type: MetatypeType) -> TypeInfo {
        guard let representation = type.representation else {
            preconditionFailure("metatype should have been assigned a representation by SIL")
        }

        return getMetatypeTypeInfo(representation: representation)
    }

    func getMetatypeTypeInfo(representation: MetatypeRepresentation) -> TypeInfo {
        switch representation {
        case .thin:
            // Thin metatypes are empty.
            return emptyTypeInfo
        case .thick:
            // Thick metatypes are represented with a metadata pointer.
            return getTypeMetadataPtrTypeInfo()
        case .objc:
            // ObjC metatypes are represented with an objc_class pointer.
            LoweringError.notImplemented("Objective-C interop")
        }
    }

    func getRawPointerTypeInfo() -> LoadableTypeInfo {
        RawPointerTypeInfo(storage: igm.int8PtrTy, size: igm.pointerSize, alignment: igm.pointerAlignment)
    }

    func getIntegerLiteralTypeInfo() -> LoadableTypeInfo {
        let ty = igm.integerLiteralTy
        return IntegerLiteralTypeInfo(storage: ty, size: igm.pointerSize * 2, alignment: igm.pointerAlignment)
    }

    private func getTypeMetadataPtrTypeInfo() -> TypeInfo {
        createUnmanagedStorageType()
    }

    private func convertAnyNominalType(_ type: AType, _: Void /* cast<NominalType>(ty)->getDecl() */) -> TypeInfo {
        switch type {
        case let type as ClassType:
            return convertClassType(type)
        case let type as StructType:
            return convertStructType(type.typeInfoHelper)
        case let type as EnumType:
            return convertEnumType(type.typeInfoHelper)
        case let type as BoundGenericClassType:
            return convertClassType(type)
        case let type as BoundGenericStructType:
            return convertStructType(type.typeInfoHelper)
        case let type as BoundGenericEnumType:
            return convertEnumType(type.typeInfoHelper)
        default:
            LoweringError.unreachable("bad nominal type")
        }
    }
    private func convertInOutType(_ type: InOutType) -> TypeInfo {
        // we should never be here, but nevertheless
        createPrimitive(type: .pointer, size: igm.pointerSize, alignment: igm.pointerAlignment)
    }

    /// Constructs a fixed-size type info
    private func createImmovable(type: LLVMType, size: Int, alignment: Int) -> ImmovableTypeInfo {
        ImmovableTypeInfo(storage: type, size: size, alignment: alignment)
    }

    private func createPrimitive(type: LLVMType, size: Int, alignment: Int) -> TypeInfo {
        PrimitiveTypeInfo(storage: type, size: size, alignment: alignment)
    }

    static func convertPrimitiveBuiltin(module: IRGenModule, type ty: AType) -> (type: LLVMType, size: Int, alignment: Int) {
        switch ty {
        case let ty as BuiltinFloatType:
            switch ty.fpKind {
            case .IEEE16:
                LoweringError.notImplemented("IEEE16")
            case .IEEE32:
                return (.float, 4, 4)
            case .IEEE64:
                return (.double, 8, 8)
            case .IEEE80:
                LoweringError.notImplemented("IEEE80")
            case .IEEE128:
                LoweringError.notImplemented("IEEE128")
            case .PPC128:
                LoweringError.notImplemented("PPC128")
            }
        case let ty as BuiltinIntegerType:
            switch ty.sizeInBits {
            case 1:
                return (.i1, 1, 1)
            case 8:
                return (.i8, 1, 1)
            case 16:
                return (.i16, 2, 2)
            case 32:
                return (.i32, 4, 4)
            case 64:
                return (.i64, 8, 8)
            default:
                LoweringError.notImplemented("LLVM i\(ty.sizeInBits)")
            }
        case is BuiltinVectorType:
            LoweringError.notImplemented("LLVM native vectors")
        default:
            LoweringError.unreachable("bad builtin type")
        }
    }
}

private class EmptyTypeInfo: LoadableTypeInfo {
    init(_ type: LLVMType = .void) {
        super.init(storage: type, size: 0, alignment: 1)
    }

    override var explosionSize: Int {
        0
    }

    override func addToAggLowering(igm: IRGenModule, lowering: inout SwiftAggLowering, offset: Int) {
        // nothing to do
    }
}

private class PrimitiveTypeInfo: PODSingleScalarTypeInfo {}

private class IntegerLiteralTypeInfo: ScalarTypeInfo {}

private class RawPointerTypeInfo: PODSingleScalarTypeInfo {}

/// A TypeInfo implementation for address-only types which can never be copied.
private class ImmovableTypeInfo: IndirectTypeInfo {}
