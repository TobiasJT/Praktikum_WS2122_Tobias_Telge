using Luxor

include("randgen.jl")

const RES_W = 64
const RES_H = 64

@enum DistributionMode begin
    EasyMode = 0
    HardMode = 1
    ExtremeMode = 2
    MemoryMode = 10
end

mutable struct StepData
    reward::Float32
    done::Bool
    level_complete::Bool

    function StepData()

        reward = 0.0
        done = false
        level_complete = false

        new(
            reward,
            done,
            level_complete,
        )
    end
end

mutable struct GameOptions
    use_monochrome_assets::Bool
    restrict_themes::Bool
    use_backgrounds::Bool
    center_agent::Bool
    distribution_mode::DistributionMode
    use_sequential_levels::Bool

    function GameOptions()

        use_monochrome_assets = false
        restrict_themes = false
        use_backgrounds = true
        center_agent = false
        distribution_mode = HardMode
        use_sequential_levels = false

        new(
            use_monochrome_assets,
            restrict_themes,
            use_backgrounds,
            center_agent,
            distribution_mode,
            use_sequential_levels,
        )
    end
end

abstract type AbstractGame end

mutable struct Game <: AbstractGame
    game_name::String

    options::GameOptions

    grid_step::Bool
    level_seed_low::Int
    level_seed_high::Int

    level_seed_rand_gen::RandGen
    rand_gen::RandGen

    step_data::StepData
    action::Int

    timeout::Int

    current_level_seed::Int
    prev_level_seed::Int
    episodes_remaining::Int
    episode_done::Bool

    last_reward_timer::Int
    last_reward::Float32
    default_action::Int

    fixed_asset_seed::Int

    cur_time::Int

    reset_count::Int
    total_reward::Float32

    function Game(name::String)

        game_name = name

        options = GameOptions()

        grid_step = false
        level_seed_low = 0
        level_seed_high = 1

        level_seed_rand_gen = RandGen()
        rand_gen = RandGen()

        step_data = StepData()
        step_data.reward = 0.0
        step_data.done = true
        step_data.level_complete = false
        action = 0

        timeout = 1000

        current_level_seed = 0
        prev_level_seed = 0
        episodes_remaining = 0
        episode_done = false
    
        last_reward_timer = 0
        last_reward = -1.0
        default_action = 0

        fixed_asset_seed = 0

        cur_time = 0

        reset_count = 0
        total_reward = 0.0

        new(
            game_name,
            options,
            grid_step,
            level_seed_low,
            level_seed_high,
            level_seed_rand_gen,
            rand_gen,
            step_data,
            action,
            timeout,
            current_level_seed,
            prev_level_seed,
            episodes_remaining,
            episode_done,
            last_reward_timer,
            last_reward,
            default_action,
            fixed_asset_seed,
            cur_time,
            reset_count,
            total_reward,
        )
    end
end

function get_game(abstract_game::AbstractGame)

    return abstract_game
end

function render_to_buf(abstract_game::AbstractGame, w::Int, h::Int)

    rectangle = rect(Point(0, 0), w, h)
    game_draw(abstract_game, rectangle)
    return nothing
end

function reset(abstract_game::AbstractGame)

    game = get_game(abstract_game)

    game.reset_count += 1

    if game.episodes_remaining == 0
        if game.options.use_sequential_levels && game.step_data.level_complete
            game.current_level_seed = game.current_level_seed + 997
        else
            game.current_level_seed = randint(game.level_seed_rand_gen, game.level_seed_low, game.level_seed_high)
        end

        game.episodes_remaining = 1
    else
        game.step_data.reward = 0
        game.step_data.done = false
        game.step_data.level_complete = false
    end

    seed(game.rand_gen, game.current_level_seed)
    game_reset(abstract_game)

    game.cur_time = 0
    game.total_reward = 0
    game.episodes_remaining -= 1
    game.action = game.default_action
    return nothing
end

function step(abstract_game::AbstractGame)

    game = get_game(abstract_game)
    
    game.cur_time += 1
    will_force_reset = false

    if game.action == -1
        game.action = game.default_action
        will_force_reset = true
    end

    game.step_data.reward = 0
    game.step_data.done = false
    game.step_data.level_complete = false
    game_step(abstract_game)

    game.step_data.done = game.step_data.done || will_force_reset || (game.cur_time >= game.timeout)
    game.total_reward += game.step_data.reward

    if game.step_data.reward != 0
        game.last_reward_timer = 10
        game.last_reward = game.step_data.reward
    end

    game.prev_level_seed = game.current_level_seed

    if game.step_data.done
        reset(abstract_game)
    end

    if game.options.use_sequential_levels && game.step_data.level_complete
        game.step_data.done = false
    end

    game.episode_done = game.step_data.done

    observe(abstract_game)
    return nothing
end

function observe(abstract_game::AbstractGame)

    render_to_buf(abstract_game, RES_W, RES_H)
    return nothing
end

function game_init(abstract_game::AbstractGame)

    return nothing
end

function game_reset(abstract_game::AbstractGame)

    return nothing
end

function game_step(abstract_game::AbstractGame)

    return nothing
end

function game_draw(abstract_game::AbstractGame, rectangle)

    return nothing
end