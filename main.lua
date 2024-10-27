local bit = require('bit')

-- No bit shift operator in LuaJIT; this'll do
local bit_masks = { 1, 2, 4, 8, 16, 32, 64, 128 }

--- @param path string
--- @param spr_transparency number?
--- @param map_transparency number?
local function love2d_tic(path, spr_transparency, map_transparency)
  local mode = nil
  --- @type string[]
  local sprites = {}
  --- @type number[][]
  local map = {}
  --- @type number[][]
  local palette = {}
  --- @type number[]
  local flags = {}

  for line in love.filesystem.lines(path) do
    --- @cast line string
    if line:match('^--%s') then
      if line == '-- <TILES>' then
        mode = 'tiles'
      elseif line == '-- <SPRITES>' then
        mode = 'sprites'
      elseif line == '-- <MAP>' then
        mode = 'map'
      elseif line == '-- <PALETTE>' then
        mode = 'palette'
      elseif line == '-- <FLAGS>' then
        mode = 'flags'
      elseif
        line == '-- </TILES>'
        or line == '-- </SPRITES>'
        or line == '-- </MAP>'
        or line == '-- </PALETTE>'
        or line == '-- </FLAGS>' then
        mode = nil
      elseif line:match('^-- %d%d%d:') then
        local index = tonumber(line:sub(4, 6), 10)
        local bytes = line:sub(8)

        if mode == 'tiles' then
          sprites[index] = bytes
        elseif mode == 'sprites' then
          sprites[index + 256] = bytes
        elseif mode == 'map' then
          map[index] = {}
          for i = 0, 239 do
            local offset = (i * 2) + 1
            local byte = bytes:sub(offset + 1, offset + 1) .. bytes:sub(offset, offset)
            table.insert(map[index], i, tonumber(byte, 16))
          end
        elseif mode == 'palette' then
          for i = 0, 15, 1 do
            local offset = (i * 6) + 1
            local r, g, b = love.math.colorFromBytes(
              tonumber(bytes:sub(offset, offset + 1), 16),
              tonumber(bytes:sub(offset + 2, offset + 3), 16),
              tonumber(bytes:sub(offset + 4, offset + 5), 16)
            )
            palette[i] = { r, g, b, 1 }
          end
        elseif mode == 'flags' then
          for i = 0, 511 do
            local offset = (i * 2) + 1
            local byte = bytes:sub(offset + 1, offset + 1) .. bytes:sub(offset, offset)
            table.insert(flags, i, tonumber(byte, 16))
          end
        end
      end
    end
  end

  local tile_image_data = love.image.newImageData(128, 256)
  tile_image_data:mapPixel(function(x, y)
    local sprite_x, sprite_y = math.floor(x / 8), math.floor(y / 8)
    local sprite_id = sprite_x + (sprite_y * 16)
    local is_map_tile = sprite_id < 256
    local bytes = sprites[sprite_id]
    local color = 0

    if bytes then
      local pixel_x = x % 8
      local pixel_y = y % 8
      local pixel_index = pixel_x + (pixel_y * 8) + 1
      local nibble = bytes:sub(pixel_index, pixel_index)
      color = tonumber(nibble, 16)
    end

    if (is_map_tile and color == map_transparency) or (not is_map_tile and color == spr_transparency) then
      return 0, 0, 0, 0
    end

    return unpack(palette[color])
  end)
  local tile_image = love.graphics.newImage(tile_image_data)

  --- @type table<string, love.Quad>
  local quad_cache = {}

  --- @param sprite_id number
  --- @param w number?
  --- @param h number?
  local function spr(sprite_id, w, h)
    local key = table.concat({ sprite_id, w, h })

    if not quad_cache[key] then
      local draw_x = (sprite_id % 16) * 8
      local draw_y = math.floor(sprite_id / 16) * 8
      local draw_w = (w or 1) * 8
      local draw_h = (h or 1) * 8

      quad_cache[key] = love.graphics.newQuad(draw_x, draw_y, draw_w, draw_h, 128, 256)
    end

    return quad_cache[key]
  end

  local function mget(x, y)
    if map[y] then
      return map[y][x] or 0
    end

    return 0
  end

  local function fget(sprite_id, flag)
    local mask = bit_masks[flag + 1]
    return bit.band(flags[sprite_id] or 0, mask) > 0
  end

  local function draw_map(x, y, w, h, sx, sy)
    for dx = x, w - 1 do
      for dy = y, h - 1 do
        local sprite_id = mget(dx, dy)
        local draw_x = sx + (dx * 8)
        local draw_y = sy + (dy * 8)
        love.graphics.draw(tile_image, spr(sprite_id), draw_x, draw_y)
      end
    end
  end

  return {
    tiles = tile_image,
    spr = spr,
    map = draw_map,
    mget = mget,
    fget = fget,
    palette = palette,
  }
end

return love2d_tic
