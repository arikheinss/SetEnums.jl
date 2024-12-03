using SetEnums, Test
using SetEnums:enumType, AbstractSetEnum



# @macroexpand(@setenum Test A B C D) |> println
@testset "SetEnums" begin
    @setenum TestEnum32::UInt32 A B C D
    @test enumType(TestEnum32) == UInt32
    s = A | B
    @test s isa EnumSet{UInt32, TestEnum32}
    @test A in s
    @test B in s
    @test !(C in s)
    @test !(D in s)
    @test (A | B) | D === A | (B | D)
    
    @test C in toggle(C, s)
    @test !(B in toggle(B, s))
    @test toggle(C, s) === (A | B | C)
    @test !(B in delete(B, s))
    @test s === delete(C, s)


    @setenum TestEnum8 X1 X2 X3 X4
    @test enumType(TestEnum8) == UInt8


    @eval @setenum TestEnum128 $((Symbol("U$i") for i in 1:98)...)
    @test isdefined(@__MODULE__, :U98) && U98 isa TestEnum128
    @test enumType(TestEnum128) == UInt128

    
    @eval @setenum TestEnumBig $((Symbol("B$i") for i in 1:177)...)
    @test isdefined(@__MODULE__, :TestEnumBig) && enumType(TestEnumBig) == BigInt
    s = B23 | B44 | B98 | B111
    @test s isa EnumSet{BigInt, TestEnumBig}
    @test B23 in s
    @test B44 in s
    @test !(B45 in s)

    @test B77 in toggle(B77, s)
    @test !(B23 in toggle(B23, s))
    @test toggle(B44, s) == (B23 | B98 | B111)
    @test !(B44 in delete(B44, s))
    @test s == delete(B1, s)
    @test s == toggle(B2, toggle(B2, s))
    @test s == toggle(B23, toggle(B23, s))
end

