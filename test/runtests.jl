using Pack1
using Test

struct S
    a::Int16
    b::Int32
end

@testset "Pack1.jl" begin
    data = pack(S(1, 2), Pack1.NetworkByteOrder())
    @test data == [0x00, 0x01, 0x00, 0x00, 0x00, 0x02]
    @test unpack(S, data, Pack1.NetworkByteOrder()) == S(1, 2)

    if pack(Int32(1)) == [0x01, 0x00, 0x00, 0x00]
        data = pack(S(1, 2), Pack1.HostByteOrder())
        @test data == [0x01, 0x00, 0x02, 0x00, 0x00, 0x00]
        @test unpack(S, data, Pack1.HostByteOrder()) == S(1, 2)
    end
end
