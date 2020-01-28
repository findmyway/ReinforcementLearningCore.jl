import Base: run

run(agent::AbstractAgent, env::AbstractEnv, stop_condition, hook::AbstractHook=EmptyHook()) = run(DynamicStyle(agent), agent, env, stop_condition, hook)

function run(::Sequential, agent::AbstractAgent, env::AbstractEnv, stop_condition, hook::AbstractHook)

    reset!(env)
    obs = observe(env)
    hook(PRE_EPISODE_STAGE, agent, env, obs)
    action = agent(PRE_EPISODE_STAGE, obs)
    hook(PRE_ACT_STAGE, agent, env, obs, action)

    while true
        obs = action |> env |> observe
        hook(POST_ACT_STAGE, agent, env, action, obs)

        if get_terminal(obs)
            agent(POST_EPISODE_STAGE, obs)  # let the agent see the last observation
            hook(POST_EPISODE_STAGE, agent, env, obs)

            stop_condition(agent, env, obs) && break

            reset!(env)
            obs = observe(env)
            hook(PRE_EPISODE_STAGE, agent, env, obs)
            action = agent(PRE_EPISODE_STAGE, obs)
            hook(PRE_ACT_STAGE, agent, env, obs, action)
        else
            stop_condition(agent, env, obs) && break
            action = agent(PRE_ACT_STAGE, obs)
            hook(PRE_ACT_STAGE, agent, env, obs, action)
        end
    end
end
