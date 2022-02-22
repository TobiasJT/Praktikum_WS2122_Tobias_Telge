include("../tools/play.jl")

big_fish = BigFish()

width = RES_W * ENLARGEMENT
height = RES_H * ENLARGEMENT
number_iterations = 5000

# Set the random seeds
rand_seed = 0
game_level_seed_gen = RandGen()
seed(game_level_seed_gen, rand_seed)
seed(big_fish.basic_game.game.level_seed_rand_gen, randint(game_level_seed_gen))
big_fish.basic_game.game.level_seed_low = 0
big_fish.basic_game.game.level_seed_high = typemax(UInt32)

# Options

# Game will only use assets from a single theme
#big_fish.basic_game.game.options.restrict_themes = true

# Game will use monochromatic rectangles instead of human designed assets. Best used with option restrict_themes set to true.
#big_fish.basic_game.game.options.use_monochrome_assets = true

# Games will use pure black background
#big_fish.basic_game.game.options.use_backgrounds = false

# Reaching the end of a level does not end the episode, and the seed for the new level is derived from the current level seed
#big_fish.basic_game.game.options.use_sequential_levels = true

# Game will be easier
#big_fish.basic_game.game.options.distribution_mode = EasyMode

# No effect in bigfish
# Determines whether observations are centered on the agent or display the full level
#big_fish.basic_game.game.options.center_agent = true

game_init(big_fish)
reset(big_fish)

first_iteration = true

@play width height number_iterations begin

    if first_iteration
        observe(big_fish)
        global first_iteration = false
    else
        # The Framerate is 15 Hz
        sleep(1/15)

        set_action(big_fish, current_key)
        step(big_fish)
    end
end

println("Finished")