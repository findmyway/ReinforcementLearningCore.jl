export MultiContinuousSpace
using Distributions: Uniform
using Random: AbstractRNG

struct MultiContinuousSpace{T<:AbstractArray} <: AbstractSpace
    low::T
    high::T
    function MultiContinuousSpace(low::T, high::T) where {T<:AbstractArray}
        size(low) == size(high) || throw(ArgumentError("$(size(low)) != $(size(high)), size must match"))
        all(map((l, h) -> l <= h, low, high)) || throw(ArgumentError("each element of $low must be ≤ than $high"))
        new{T}(low, high)
    end
end

MultiContinuousSpace(low, high) = MultiContinuousSpace(promote(low, high)...)

Base.eltype(::MultiContinuousSpace{T}) where {T} = T
Base.in(xs, s::MultiContinuousSpace)= size(xs) == element_size(s) && all(map((l, x, h) -> l <= x <= h, s.low, xs, s.high))
Base.rand(rng::AbstractRNG, s::MultiContinuousSpace{T}) where {T} = map((l, h) -> convert(eltype(T), rand(rng, Uniform(l, h))), s.low, s.high)

Base.length(s::MultiContinuousSpace) = error("MultiContinuousSpace is uncountable")
element_size(s::MultiContinuousSpace) = size(s.low)
element_length(s::MultiContinuousSpace) = length(s.low)