include("../games/bigfish.jl")

mutable struct Key
    left::Bool
    right::Bool
    down::Bool
    up::Bool
    
    function Key()

        left = false
        right = false
        down = false
        up = false

        new(
            left,
            right,
            down,
            up,
        )
    end
end

function set_action(abstract_game::AbstractGame, key::Key)

    game = get_game(abstract_game)

    key_action = 4

    if key.left && !key.right && key.down && !key.up
        key_action = 0
    end
    if key.left && !key.right && !key.down && !key.up
        key_action = 1
    end
    if key.left && !key.right && !key.down && key.up
        key_action = 2
    end
    if !key.left && !key.right && key.down && !key.up
        key_action = 3
    end
    if !key.left && !key.right && !key.down && key.up
        key_action = 5
    end
    if !key.left && key.right && key.down && !key.up
        key_action = 6
    end
    if !key.left && key.right && !key.down && !key.up
        key_action = 7
    end
    if !key.left && key.right && !key.down && key.up
        key_action = 8
    end

    game.action = key_action
    return nothing
end