function adjust_rect(base_rect, adjusting_rect)

    base_x = base_rect[2].x
    base_y = base_rect[2].y
    base_w = base_rect[3].x - base_x
    base_h = base_rect[1].y - base_y

    adjusting_x = adjusting_rect[2].x
    adjusting_y = adjusting_rect[2].y
    adjusting_w = adjusting_rect[3].x - adjusting_x
    adjusting_h = adjusting_rect[1].y - adjusting_y

    rectangle = rect(Point(base_x + base_w * adjusting_x, base_y + base_h * adjusting_y), base_w * adjusting_w, base_h * adjusting_h, vertices = true)
    return rectangle
end