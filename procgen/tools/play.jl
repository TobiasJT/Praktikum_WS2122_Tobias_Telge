# Original file: https://github.com/JuliaGraphics/Luxor.jl/blob/master/src/play.jl
# Replaced whileloop with forloop in play macro to limit number of displayed frames to n 

using MiniFB

include("key.jl")

current_key = Key()

function keyboard(window, key, mod, isPressed)::Cvoid
    
    if key == MiniFB.KB_KEY_LEFT
        if Bool(isPressed)
            current_key.left = true
        else
            current_key.left = false
        end
    elseif key == MiniFB.KB_KEY_RIGHT
        if Bool(isPressed)
            current_key.right = true
        else
            current_key.right = false
        end
    elseif key == MiniFB.KB_KEY_DOWN
        if Bool(isPressed)
            current_key.down = true
        else
            current_key.down = false
        end
    elseif key == MiniFB.KB_KEY_UP
        if Bool(isPressed)
            current_key.up = true
        else
            current_key.up = false
        end
    end
    return nothing
end

macro play(w, h, n, body)
    quote
        window = mfb_open_ex("Visualization", $(esc(w)), $(esc(h)), MiniFB.WF_RESIZABLE)

        mfb_set_keyboard_callback(window, keyboard)

        buffer = zeros(UInt32, $(esc(w)), $(esc(h)))
        for i = 1:$(esc(n))
            Drawing($(esc(w)), $(esc(h)), :image)
            $(esc(body))
            m = permutedims(image_as_matrix!(buffer), (2, 1))
            finish()
            state = mfb_update(window, m)
            if state != MiniFB.STATE_OK
                break
            end
        end
        mfb_close(window)
    end
end