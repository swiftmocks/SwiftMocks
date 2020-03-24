struct GenericSignature {}
struct SILFunctionType {
	struct ExtInfo {}
}
enum SILCoroutineKind { case foo }
enum ParameterConvention { case bar}
struct SILParameterInfo {}
typealias SILYieldInfo = SILParameterInfo
struct SILResultInfo {}
struct ProtocolConformanceRef {}


enum TypeFactory {

	func getSILFunctionType(genericSig: GenericSignature?,
																 extInfo: SILFunctionType.ExtInfo,
																 coroutineKind: SILCoroutineKind,
																 calleeConvention: ParameterConvention,
																 params: [SILParameterInfo],
																 yields: [SILYieldInfo],
																 normalResults: [SILResultInfo],
																 errorResult: SILResultInfo?,
																 witnessMethodConformance: ProtocolConformanceRef?
	) -> SILFunctionType { fatalError() }

}
