## Forward prepare for coming breaking FFI change in ponyc

Added FFI declarations to all FFI calls in the library. The change has no impact on end users, but will future proof against a coming breaking change in FFI in the ponyc compiler. Users of this version of the library won't be impacted by the coming change.

