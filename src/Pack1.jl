"""
Fast pack/unpack with extensible byte order support.
License: MIT
Author: thautwamr (twshere@outlook.com)
"""
module Pack1

export pack, unpack

@static if !isdefined(Base, :fieldtypes)
    Base.@pure function fieldtypes(@nospecialize(t))
        xs = Any[]
        fs = fieldnames(t)
        for i in 1:length(fs)
            push!(xs, fieldtype(t, fs[i]))
        end
        return Tuple(xs)
    end
end

abstract type AbstractByteOrder end

struct NetworkByteOrder <: AbstractByteOrder end
struct HostByteOrder <: AbstractByteOrder end

@inline to_targetbits(::NetworkByteOrder, primval) = hton(primval)
@inline from_targetbits(::NetworkByteOrder, primval) = ntoh(primval)

@inline to_targetbits(::HostByteOrder, primval) = primval
@inline from_targetbits(::HostByteOrder, primval) = primval

"""
    pack(data)::Vector{UInt8}

Pack the data into a byte stream. The data must be an instance of a value type, otherwise an error will be thrown.

About value type: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/value-types
""" @inline function pack(data, bo::AbstractByteOrder=HostByteOrder())
    isbits(data) || error("Only bits data can be packed (value-only serialization)")
    buffer = IOBuffer()
    _pack!(bo, buffer, data)
    return take!(buffer)
end

"""
    unpack(输出类型, buffer::Vector{UInt8})::输出类型

Unpack a byte stream into an instance of the specified type. The output type must be a value type, otherwise an error will be thrown.

About value type: https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/builtin-types/value-types
""" @inline function unpack(::Type{S}, buffer::Vector{UInt8}, bo::AbstractByteOrder=HostByteOrder()) where {S}
    isbitstype(S) || error("Only bits data can be unpacked (value-only serialization)")
    GC.@preserve buffer begin
        return _unpack(bo, S, buffer, 0)
    end
end

@inline @generated function _pack!(bo::AbstractByteOrder, buffer::IOBuffer, data::S) where {S}
    size_intptr_t = sizeof(Ptr{Cvoid})
    if isprimitivetype(S)
        N = sizeof(S)
        quote
            write(buffer, to_targetbits(bo, data))
        end
    else
        metafields = fieldnames(S)
        ex = Expr(:block)
        for metafield in metafields
            push!(ex.args, :(_pack!(bo, buffer, data.$metafield)))
        end
        ex
    end
end

@inline @generated function _unpack(bo::AbstractByteOrder, ::Type{S}, buffer::Vector{UInt8}, offset::Int) where {S}
    size_intptr_t = sizeof(Ptr{Cvoid})
    if isprimitivetype(S)
        N = sizeof(S)
        quote
            if offset + $N > length(buffer)
                error("Buffer is too short when unpacking $S")
            end
            ptr = pointer(buffer)
            return from_targetbits(bo, unsafe_load(reinterpret(Ptr{$S}, ptr + offset))::$S)
        end
    else
        metafieldtypes = fieldtypes(S)
        ex = Expr(:new, S)
        offset_inc = 0
        for ft in metafieldtypes
            push!(ex.args, :(_unpack(bo, $ft, buffer, offset + $offset_inc)))
            offset_inc += sizeof(ft)
        end
        ex
    end
end

end # module Pack1
