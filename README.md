# Pack1.jl

## Installation

```julia
julia> ]
pkg> add Pack1
```

## Introduction & Usage

A single file Julia libray using `pack(1)` alignment to pack value-typed instances into UInt8 arrays.

This is useful when sending data over the network or sharing data with other computer despite different endianness.

The motivation for this project was to teach [Julia-generated functions](https://docs.julialang.org/en/v1/manual/metaprogramming/#Generated-functions) to achieve high performance computations.

```julia
import Pack1

struct S
    x::Int32
    y::Int16
end

data = S(1, 2)

packed = Pack1.pack(data)
# 6-element Vector{UInt8}:
#  0x01
#  0x00
#  0x00
#  0x00
#  0x02
#  0x00

Pack1.unpack(S, packed)
# S(1, 2)

import Pack1: NetworkByteOrder
packed = Pack1.pack(data, NetworkByteOrder())
# 6-element Vector{UInt8}:
#  0x00
#  0x00
#  0x00
#  0x01
#  0x00
#  0x02
```

## LICENSE

MIT License is used for this project.