# love2d-tic

> Load [TIC-80](https://tic80.com/) spritesheets in [LÖVE](https://www.love2d.org/)

Sometimes you're learning a new game development engine, but you don't have the heart to learn a new standalone spriting tool at the same time.

This library parses a TIC-80 cart's spritesheet into a LÖVE `Image`.

Supports:

- Tiles and sprites
- Maps
- Palette
- Sprite flags
- Palette swaps/transparency, via shaders

Limitations:

- Can only parse a `.lua` cart
- Does not support alternate banks
- Only supports 4bpp sprites

Non-features:

- Does not import sound effects or music

## Usage

Loading and drawing sprites from a spritesheet:

```lua
-- This should be set first to enable pixel-perfect rendering
love.graphics.setDefaultFilter('nearest', 'nearest')

local love2d_tic = require('love2d-tic.main')
local tic = love2d_tic('path/to/game.lua')

-- Draw a single sprite
love.graphics.draw(tic.tiles, tic.spr(256), 0, 0)

-- Draw a map
-- map(map_x, map_y, map_w, map_h, screen_x?, screen_y)
tic.map(0, 0, 30, 17, 0, 0)
```

## API

### `love2d-tic.main`

#### love_2d_tic()

Loads a TIC-80 Lua file and produces a spritesheet for use in drawing operations, and a set of related utility functions.

Optionally, a `colorkey` can be specified, which renders all pixels of the given color ID transparent. If you need to use different colors for transparency for different sprites, you can alternatively create a shader to handle this; see `create_palette_swap_shader()` further down.

Arguments:

- `path: string?`
- `colorkey?: number`

### TIC-80 interface

The table returned by `love2d_tic()`:

#### tiles

A `love.Image` containing the cart's tiles and sprites. The image is 128x256; the tiles are on the top half, and the sprites are on the bottom half.

#### spr()

Returns a `love.Quad` that can be used with the spritesheet to draw an individual sprite. The Quad produced is cached and reused across frames to improve performance.

To draw a sprite that spans multiple tiles, pass `width` and `height` arguments.

Unlike the TIC-80's own `spr()` function, this one does not handle scaling and rotation; you can handle that in `love.graphics.draw()`.

Arguments:

- `sprite_id: number`
- `width: number?`
- `height: number?`

#### map()

Draws a map to the screen. Unlike `spr()`, this function does the actual drawing for you.

Arguments:

- `map_x: number`
- `map_y: number`
- `map_w: number`
- `map_h: number`
- `screen_x: number?`
- `screen_y: number?`

#### mget()

Returns the sprite ID at the given map coordinate. Remember, these are _map coordinates_ and not _screen coordinates_, so you may need to convert one to the other:

```lua
local map_x = math.floor(player_x / 8)
local map_y = math.floor(player_y / 8)

tic.mget(map_x, map_y)
```

Arguments:

- `map_x: number`
- `map_y: number`

#### fget()

Returns a boolean indicating if the given sprite has a flag set. Flags are numbered 0 to 7.

```lua
local map_x = math.floor(player_x / 8)
local map_y = math.floor(player_y / 8)

tic.fget(
  tic.mget(map_x, map_y),
  1
)
```

Arguments:

- `sprite_id: number`
- `flag: number`

#### palette

A table containing the cart's color palette, formatted as lists with red, green, blue, alpha, the way LÖVE formats it.

Note that the table is _0-indexed_ to fit how the TIC-80 identifies color. If you try to iterate through this list with `ipairs()`, the first color will be skipped.

```lua
palette = {
  { 0.75, 0.23, 0.23, 1 },
  { 0.23, 0.92, 0.03, 1 },
  -- ...and so on
}
```

### `love2d-tic.palette-swap`

#### create_palette_swap_shader()

Creates a shader that replaces one color with another. Use this to imitate the TIC-80's built-in palette swap feature.

```lua
local love2d_tic = require('love2d-tic.main')
local create_palette_swap_shader = require('love2d-tic.palette-swap')

local tic = love2d_tic('path/to/cart.lua')

local shader = create_palette_swap_shader(
  tic.palette[2],
  tic.palette[4]
)

love.graphics.setShader(shader)
love.graphics.draw(tic.tiles, tic.spr(256), 0, 0)
love.graphics.setShader()
```

You can use this same shader to make a specific color transparent:

```lua
local shader = create_palette_swap_shader(
  tic.palette[2],
  { 0, 0, 0, 0 }
)
```

Arguments:

- `target_color: table`
- `replacement_color: table`

## License

MIT &copy; [Geoff Kimball](https://geoffkimball.com)
