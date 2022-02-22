const ENLARGEMENT = 10

struct Image
    data::Any
    width::Int
    height::Int
    is_mirrored::Bool
    
    function Image(_data = nothing, _is_mirrored = false)

        data = _data
        if !isnothing(data)
            width = data.width
            height = data.height
        else
            width = 0
            height = 0
        end
        is_mirrored = _is_mirrored

        new(
            data,
            width,
            height,
            is_mirrored,
        )
    end
end

function mirror(image::Image)
    
    return Image(image.data, !image.is_mirrored)
end

function show(image::Image, rectangle)

    rectangle = rectangle * ENLARGEMENT
    left_top = rectangle[2]
    w = rectangle[3].x - left_top.x
    h = rectangle[1].y - left_top.y

    # Show rectangle in which image is placed
    #setcolor("black")
    #rect(left_top, w, h, :stroke)
    
    if image.is_mirrored
        right_top = Point(left_top.x + w, left_top.y)
        translate(right_top)
        scale(-1 * w / image.width, h / image.height)
    else
        translate(left_top)
        scale(w / image.width, h / image.height)
    end
    
    placeimage(image.data, Point(0, 0))
    origin(Point(0, 0))
    return nothing
end