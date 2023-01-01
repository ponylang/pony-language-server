use "json"

type LSPInteger is I64
type LSPUinteger is U64
type LSPDecimal is F64
type LSPNumber is (LSPInteger | LSPUinteger | LSPDecimal)
type LSPObject is JsonObject
type LSPArray is JsonArray
type LSPAny is (None | Bool | LSPInteger | LSPUinteger | LSPDecimal | String | LSPObject | LSPArray)
type ProgressToken is (LSPInteger | String)
