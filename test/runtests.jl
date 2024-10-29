using SetEnums, Test
using SetEnums:enumType



# @macroexpand(@setenum Test A B C D) |> println
@setenum TestEnum::UInt32 A B C D
@testset "SetEnums" begin
    @test enumType(TestEnum) == UInt32
    s = A | B
    @test s isa EnumSet{UInt32, TestEnum}
    @test A in s
    @test B in s
    @test !(C in s)
    @test !(D in s)
    @test (A | B) | D === A | (B | C)

end



println(A)
display(A)
A | B |> println
(A | B) | C |> println
(A | C) |> println
println(empty(EnumSet{UInt32,TestEnum}))
println(empty(A))

@assert A in (A | C)
@assert !(B in (A | C))
@setenum AnimalTraits::UInt8 Smart Pretty Flies Strong Stinky Loud

struct Animal
    name::String
    traits::EnumSet(AnimalTraits)
end

bear = Animal("Bear", (Strong | Stinky | Smart))
parrot = Animal("Parrot", (Smart | Flies | Pretty | Loud))
crow = Animal("Crow", delete(Pretty, parrot.traits))
dog = Animal("Fido", (Smart | Pretty | Loud))
dirty_dog = Animal("dirty Fido", toggle(Stinky, dog.traits))
clean_dog = Animal("cleaned Fido", toggle(Stinky, dirty_dog.traits))
myanimals = [bear, parrot, crow, dog, dirty_dog,]

println("Flying animals")
join((a.name for a in myanimals if Flies in a.traits), ", ") |> println

println("Filthy animals")
join((a.name for a in myanimals if Stinky in a.traits), ", ") |> println


