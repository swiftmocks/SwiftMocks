func foo() -> Int { 0 }

@_dynamicReplacement(for: foo)
func bar() -> Int { -1 }
