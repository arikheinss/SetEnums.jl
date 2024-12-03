module SetEnums


import Base: instances, Integer, empty, in, &, |
import Base.Enums: Enum, namemap

export @setenum, toggle, delete, EnumSet 

abstract type AbstractSetEnum{T} <: Enum{T} end
Integer(x::AbstractSetEnum) = getfield(x,1) #assuming each SetEnum is a simple wrapper around a primitive Integer 


enumType(::AbstractSetEnum{T}) where {T} = T
enumType(::Type{<:AbstractSetEnum{T}}) where {T} = T

"""
A type representing a set of SetEnums. The parameter `T` indicates which setenum is wrapped, the parameter `W` which type is wrapped
for the stored information. Can be created either by combining multiple instances of a SetEnum (like `A | B | C`), or via `Base.empty`.

Since these are simple wrapper around primitive immutable integers, inplace-mutating like `push!` won't work on them. Instead, use the 
operator  `|` or the exported functions `set`, `delete`, `toggle` to create new ones.

Use `Base.in` or `Base.iterate` to inspect them.
"""
struct EnumSet{W,T<:AbstractSetEnum{W}} <: AbstractSet{T}
    set::W
end
wrapped(s::EnumSet) = s.set
wrapped(s::AbstractSetEnum) = s.id

enumType(::EnumSet{T}) where {T} = T
enumType(::Type{<:EnumSet{T}}) where {T} = T

EnumSet(::Type{T}) where {T<:AbstractSetEnum} = EnumSet{enumType(T),T}
var"|"(a::T, b::T) where {T<:AbstractSetEnum} = EnumSet{enumType(T),T}(a.id | b.id)
var"|"(a::T, b::EnumSet{W,T}) where {W,T<:AbstractSetEnum{W}} = EnumSet{W,T}(a.id | b.set)
var"|"(b::EnumSet{W,T}, a::T) where {W,T<:AbstractSetEnum{W}} = EnumSet{W,T}(a.id | b.set)


empty(::Type{ES}) where {W,ES<:EnumSet{W}} = ES(zero(W))
empty(::T) where {W,T<:AbstractSetEnum{W}} = empty(EnumSet{W,T})

in(inst::T, es::EnumSet{W,T}) where {W,T<:AbstractSetEnum{W}} = (inst.id & es.set) > 0

"""
```toggle(instance, es::EnumSet)```

Removes `instance` from `es` if it is contained within it, adds it otherwise. 

(add/remove in an immutable sense, i.e. returns a new `EnumSet` with/without the given instance
"""
toggle(inst::T, es::EnumSet{W,T}) where {W,T<:AbstractSetEnum{W}} = EnumSet{W,T}(inst.id ⊻ es.set)

"""
```delete(instance, es::EnumSet)```

Returns a new `EnumSet` that contains the same elements as `es`, but without `instance`.
"""
delete(inst::T, es::EnumSet{W,T}) where {W,T<:AbstractSetEnum{W}} = EnumSet{W,T}(es.set & (inst.id ⊻ es.set))



"""
    ```@setenum EnumName::Type inst1 inst2 ...```
    ```@setenum EnumName inst1 inst2 ...```

Creates a new SetEnum.

Similarly to `@enum`, defines a new Type `EnumName` with Hierarchy `EnumName <: AbstractSetEnum{Type} <: Enum{Type}`, and a new constant of
this type for every `inst` given. The main difference is that the given instances all have exactly one bit set, i.e. they do 
not count up linearly (0,1,2,3,...) but exponentially (2^0, 2^1, 2^2, ...). Thus the number of instances for this enum cannot 
exceed the number of bits of the representing `Type`.

The advantage of this is that one can now represent sets of this enum as primitive Integer values, where one of the instances is considered
in the set if it's corresponding bit is set in the set-integer. These primitive enum sets can be efficiently stored, and constructed and manipulated 
through low level bit operations.



Possible values for the type parameter `Type` are any of the `UInt`-family or `BigInt`.
If `Type` is not given, it defaults to the smallest `UInt` capable of representing all given Instances,
or `BigInt` if more than 128 instances are given.

## Examples


julia>@setenum AnimalTraits::UInt8 Smart Pretty Flies Strong Stinky Loud
"""
macro setenum end

macro setenum(name::Symbol, instances::Symbol...)

    Inttype = if length(instances) > 128
        BigInt
    elseif length(instances) > 64
        UInt128
    elseif length(instances) > 32
        UInt64
    elseif length(instances) > 16
        UInt32
    elseif length(instances) > 8
        UInt16
    else
        UInt8
    end

    return :(@setenum $(esc(name))::$Inttype $(esc.(instances)...))
end

macro setenum(name::Expr, instanceNames...)
    name.head == Symbol("::") || throw("name was not <name>::<type> -- $name")
    enum_name = esc(name.args[1])
    enum_type = Core.eval(__module__, name.args[2])
    if length(instanceNames) == 1 && instanceNames[1] isa Expr && instanceNames[1].head === :block
        instanceNames = instanceNames[1].args
    end
    if enum_type in (UInt8, UInt16, UInt32, UInt64, UInt128)
        length(instanceNames) > sizeof(enum_type)*8 && throw(ArgumentError("The number of instances for a SetEnum must not exceed the width of the representing type! Type width: $enum_type, $(8*sizeof(enum_type)), but number instances: $(length(instanceNames))"))
    elseif enum_type ≠ BigInt
        throw("Unsupported type for setenum! Supported types are: (UInt8, UInt16, UInt32, UInt64, UInt128, BigInt)")
    end

    oneVal = one(enum_type)
    instanceValues = Tuple(oneVal << i for i in 0:length(instanceNames)-1)
    retExpr = quote
        struct $enum_name <: AbstractSetEnum{$enum_type}
            id::$enum_type
        end
        $((:(const $(esc(id)) = $enum_name($(val)))
           for (id, val) in zip(instanceNames, instanceValues))...)

        Base.typemin(::Type{$enum_name}) = $enum_name($(instanceValues[1]))
        Base.typemax(::Type{$enum_name}) = $enum_name($(instanceValues[end]))
        Base.instances(::Type{$enum_name}) = $instanceValues
        Base.Enums.namemap(::Type{$enum_name}) = Dict($( (val => sym for (val, sym) in zip(instanceValues, instanceNames))...))
        $enum_name

    end
    retExpr.head = :toplevel
    return retExpr
end


Base.length(s::EnumSet) = count_ones(s.set)
function Base.iterate(s::EnumSet{W, T}) where {W,T}
    first = T(one(W))
    if isodd(s.set) 
        return (first, (first, s.set))
    else
        return Base.iterate(s, (first, s.set))
    end
end

function Base.iterate(::EnumSet{W, T}, (v, set)) where {W,T}
    cset = set
    cval = v.id
    while cset > 0
        cset = cset >> 1
        cval = cval << 1
        if isodd(cset)

            return T(cval), (T(cval), cset)
        end
    end
    return nothing
end

Base.bitstring(s::Union{AbstractSetEnum,EnumSet}) = bitstring(wrapped(s))
end # module SetEnums
