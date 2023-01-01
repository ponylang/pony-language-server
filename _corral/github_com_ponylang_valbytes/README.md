# valbytes

Library for dealing with concatenated byte arrays as if it was a single byte array.

## Status

valbytes is beta-level software.

## Installation

* Install [corral](https://github.com/ponylang/corral)
* `corral add github.com/ponylang/valbytes.git --version 0.6.2`
* `corral fetch` to fetch your dependencies
* `use "valbytes"` to include this package
* `corral run -- ponyc` to compile your application

## API Documentation

[https://ponylang.github.io/valbytes](https://ponylang.github.io/valbytes)

## Example usage

```pony
var ba = ByteArrays
ba = ba + "foo" + " " + "bar"

ba.string(0, 3)        // "foo"
ba.take(3).string()    // "foo"
ba.drop(4).string()    // "bar"

for elem in ba.arrays().values() do
  env.out.print(elem)  // "foo", " ", "bar"
end
```
