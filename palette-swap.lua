local function create_palette_swap_shader(target_color, replacement_color)
  local code = ([[
    vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords) {
      vec4 pixel = Texel(texture, texture_coords);

      if (
        pixel.r == %s
        && pixel.g == %s
        && pixel.b == %s
      ) {
        return vec4(%f, %f, %f, 1.0);
      }

      return pixel;
    }
  ]]):format(
    target_color[1],
    target_color[2],
    target_color[3],
    replacement_color[1],
    replacement_color[2],
    replacement_color[3]
  )
  return love.graphics.newShader(code)
end

return create_palette_swap_shader
