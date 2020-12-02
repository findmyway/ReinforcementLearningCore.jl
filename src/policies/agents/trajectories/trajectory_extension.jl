export NStepInserter, UniformBatchSampler

using Random

#####
# Inserters
#####

abstract type AbstractInserter end

Base.@kwdef struct NStepInserter <: AbstractInserter
    n::Int = 1
end

function Base.push!(
    t::CircularVectorSARTSATrajectory,
    𝕥::CircularArraySARTTrajectory,
    inserter::NStepInserter,
)
    N = length(𝕥)
    n = inserter.n
    for i in 1:(N-n+1)
        for k in SART
            push!(t[k], select_last_dim(𝕥[k], i))
        end
        push!(t[:next_state], select_last_dim(𝕥[:state], i+n))
        push!(t[:next_action], select_last_dim(𝕥[:action], i+n))
    end
end

#####
# Samplers
#####

abstract type AbstractSampler{traces} end

struct UniformBatchSampler{traces} <: AbstractSampler{traces}
    batch_size::Int
end

UniformBatchSampler(batch_size::Int) = UniformBatchSampler{SARTSA}(batch_size)

"""
    sample([rng=Random.GLOBAL_RNG], trajectory, sampler, [traces=Val(keys(trajectory))])

!!! note
    Here we return a copy instead of a view:
    1. Each sample is independent of the original `trajectory` so that `trajectory` can be updated async.
    2. [Copy is not always so bad](https://docs.julialang.org/en/v1/manual/performance-tips/#Copying-data-is-not-always-bad).
"""
function StatsBase.sample(t::AbstractTrajectory, sampler::AbstractSampler)
    sample(Random.GLOBAL_RNG, t, sampler)
end

function StatsBase.sample(rng::AbstractRNG, t::CircularVectorSARTSATrajectory, s::UniformBatchSampler{SARTSA})
    inds = rand(rng, 1:length(t), s.batch_size)
    NamedTuple{SARTSA}(Flux.batch(view(t[x], inds)) for x in SARTSA)
end

function StatsBase.sample(rng::AbstractRNG, t::CircularArraySARTTrajectory, s::UniformBatchSampler{SARTS})
    inds = rand(rng, 1:length(t), s.batch_size)
    NamedTuple{SARTS}((
        (convert(Array, consecutive_view(t[x], inds)) for x in SART)...,
        convert(Array,consecutive_view(t[:state], inds.+1))
    ))
end