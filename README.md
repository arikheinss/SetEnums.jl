# SetEnums
> [!WARNING]  
> This package is still under construction. 

This Package adds a new type of Enum for which Sets can be created that are efficient, primitive binary data. The core Idea behind this is as follows: If one has a finite amount of traits/entities that can occur together in groups, one might assign each of these entities with a specific bit of a sufficiently large primitive type, f.ex. an `UInt64`. A Set of these entities can then be represented as an instance of this primitive type, where all the bits corresponding to entities that are in the set are 'on', where all bits assigned to entities that are not in the Set are 'off'. Creation and inspection of these primitive sets can then be done via bitwise operations like `or` and `xor`. The main contribution of this package is to provide  convenient and high-level syntax for creating and working with these enum types.

## Important exports

The central exported functionality is the `@setenum` macro. It works similarly to the `enum` macro from `Base`.

```
@setenum ExampleEnum Inst1 Inst2 Inst3 Inst4
```

This will create a new type `ExampleEnum` with the following Hierarchy: `ExampleEnum <: AbstractSetEnum{UInt8} <: Enum{UInt8} <: Any`, as well as the constant values `Inst1` to `Inst4`. The main difference to a regular enum is that each of the instances will have exactly one bit of the underlying integer toggled on, so their numeric values does not increase linearly (1,2,3,4,...) but rather exponentially (1,2,4,8,...), and thus the number of instances cannot be greater than the size of the wrapped type.

These can be combined into Sets via the `|` operator. 
```
julia>s = Inst1 | Inst4
#Todo

julia>Inst1 in s
true

julia>Inst2 in s
false


```

