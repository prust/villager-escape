local bump = require 'bump'

padding = 30
paddle_speed = 500
keyboard_speed = 300
hud_height = 100
num_lives = 5
is_paused = false
viewport_x = 0
viewport_y = 0
brick_color = {151, 142, 156}
player_color = {242, 186, 136}
zombie_color = {59, 143, 77}
emerald_color = {45, 187, 58}
door_color = {152, 102, 15,}

flag_size = 10
flag_offset = 20

-- other controls: 'mouse', 'controller'
player = {controls = 'arrow_keys'}
players = { player }
wall = {}
zombie = {width = 40, height = 40, dx = keyboard_speed, dy = 0}
down = {type = "sign", dir = "down"}
down_left = {type = "sign", dir = "down-left"}
down_right = {type = "sign", dir = "down-right"}
up_left = {type = "sign", dir = "up-left"}
up_right = {type = "sign", dir = "up-right"}
emerald = {type = "collectible", width = 20, height = 30}
emeralds = {}
door = {type = "object", width = 50, height = 10}
doors = {}
door_is_open = false
skeleton = {}

local signFilter = function(item, other)
  if other.type == 'sign' then
    return 'cross'
  elseif other.type == 'collectible' then
    return 'cross'
  elseif other.type == 'object' then
    if door_is_open then
      return 'cross'
    else
      return 'slide'
    end
  else
    return 'slide'
  end
end

local Z = zombie
local W = wall
local P = player
local D = down
local DR = down_right
local DL = down_left
local UL = up_left
local UR = up_right
local E = emerald
local DO = door
local S = skeleton
bricks = {
  0, W, W, W, W, W, W, W, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  W, W, 0, 0, Z, 0, DR,W, W, 0, 0, 0, 0, 0, 0, 0, 0, 0,
  W, UR,0, W, W, W, 0, 0, W, 0, 0, 0, 0, 0, 0, 0, 0, 0, 
  W, 0, W, 0, 0, 0, W, 0, W, W, W, W, W, W, W, W, W, 0,
  W, E, W, 0, P, 0, 0, D, 0, 0, 0, 0, 0, 0, 0, 0, 0, W,
  W, 0, W, 0, 0, 0, W, 0, W, W, W, W, W, W, DO,W, W, 0,
  W, 0, 0, W, W, W, 0, DL,W, 0, 0, 0, W, 0, 0, W, W, W, 
  W, W, UL,0, 0, 0, 0, W, W, 0, 0, 0, 0, W, 0, 0, DO,0,
  0, W, W, W, W, W, W, W, 0, 0, 0, 0, W, 0, 0, W, W, W,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, W, 0, 0, W, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, W, E, W, 0, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, W, W, 0, W, W, 0,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, W, DR,S, 0, 0, DL,W,
  0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, W, W, W, W, W, 0
}
num_h_bricks = 14
num_w_bricks = #bricks / num_h_bricks

brick_height = 50
brick_width = 50
brick_spacing = 0
bricks_left_margin = 0
bricks_top_margin = 0
level_width = num_w_bricks * brick_width
level_height = num_h_bricks * brick_height

function getBrickXY(ix)
  ix = ix - 1 -- b/c Lua is 1-based
  local y = math.floor(ix / num_w_bricks)
  local x = ix % num_w_bricks
  return bricks_left_margin + x * (brick_width + brick_spacing), bricks_top_margin + y * (brick_height + brick_spacing)
end

function getBrick(grid_x, grid_y)
  return bricks[getBrickIndex(grid_x, grid_y)]
end

function getBrickIndex(grid_x, grid_y)
  local ix = grid_y * num_w_bricks + grid_x
  ix = ix + 1 -- b/c Lua is 1-based
  return ix
end

-- local ballBumpFilter = function(item, other)
--   return 'bounce'
-- end

function love.load()
  love.graphics.setBackgroundColor(40, 40, 40)
  love.window.setFullscreen(true)
  screen_width, screen_height = love.graphics.getDimensions()
  screen_height = screen_height - hud_height
  world = bump.newWorld()

  love.mouse.setY(screen_height / 2)
  love.mouse.setX(screen_width / 2)
  love.mouse.setVisible(false)

  love.graphics.setFont(love.graphics.newFont(64))

  -- add bricks
  local num_bricks = num_h_bricks * num_w_bricks
  for i = 1, num_bricks do
    local x, y = getBrickXY(i)
    if bricks[i] == wall then
      bricks[i] = {item_type = 'brick', brick_type = brick, ix = i, x = x, y = y, width = brick_width, height = brick_height}
      local brick = bricks[i]
      world:add(brick, brick.x, brick.y, brick.width, brick.height)
    elseif bricks[i] == player then
      player.x = x
      player.y = y
      player.score = 0
      player.lives = num_lives

      player.height = 40
      player.width = 40
      player.dx = 0
      player.dy = 0

      world:add(player, player.x, player.y, player.width, player.height)
      bricks[i] = 0
    elseif bricks[i] == zombie then
      zombie.x = x
      zombie.y = y
      world:add(zombie, zombie.x, zombie.y, zombie.width, zombie.height)
      bricks[i] = 0
    elseif bricks[i] ~= 0 and bricks[i].type == "sign" then
      local sign = {type = "sign", dir = bricks[i].dir}
      world:add(sign, x, y, brick_width, brick_height)
      bricks[i] = 0
    elseif bricks[i] ~= 0 and bricks[i].type == "collectible" then
      local new_emerald = {x = x + 15, y = y + 10, width = emerald.width, height = emerald.height, type="collectible", gem="emerald"}
      table.insert(emeralds, new_emerald)
      world:add(new_emerald, new_emerald.x, new_emerald.y, new_emerald.width, new_emerald.height)
      bricks[i] = 0
    elseif bricks[i] ~= 0 and bricks[i].type == "object" then
      local new_door = {x = x, y = y, width = door.width, height = door.height, type = door.type}
      table.insert(doors, new_door)
      world:add(new_door, new_door.x, new_door.y, new_door.width, new_door.height)
      bricks[i] = 0
    else
      bricks[i] = 0
    end
  end

  -- ball = {
  --   x = screen_width/2,
  --   y = screen_height/2
  -- }
  -- ball.dx = 0 -- -5 * speed
  -- ball.dy = 0 -- 2 * speed
  -- world:add(ball, ball.x, ball.y, ball_size, ball_size)  

  local joysticks = love.joystick.getJoysticks()
  joystick_1 = joysticks[1]
  joystick_2 = joysticks[2]
end

function love.update(dt)
  if is_paused then
    return
  end

  -- move ball
  -- local goal_x = ball.x + dt * ball.dx
  -- local goal_y = ball.y + dt * ball.dy
  -- local actualX, actualY, cols, len = world:move(ball, goal_x, goal_y, ballBumpFilter)
  -- ball.x = actualX
  -- ball.y = actualY

  -- if #cols > 0 then
  --   -- remove bricks that get hit
  --   if cols[1].other.item_type == 'brick' then
  --     local brick = cols[1].other
  --     world:remove(brick)
  --     bricks[brick.ix] = 0
  --   end

    -- change ball direction if it bounces on anything
    -- local norm = cols[1].normal
    -- if norm.x == 1 or norm.x == -1 then
    --   ball.dx = -ball.dx
    -- end
    -- if norm.y == 1 or norm.y == -1 then
    --   ball.dy = -ball.dy
    -- end
  -- end
  -- world:update(ball, ball.x, ball.y)

  -- move players
  for i, player in ipairs(players) do
    local min_x = 0
    local min_y = 0
    local max_x = level_width - player.width
    local max_y = level_height - player.height

    if player.controls == 'controller' and joystick_1 then
      player.dx = paddle_speed * joystick_1:getGamepadAxis('leftx')
      player.dy = paddle_speed * joystick_1:getGamepadAxis('lefty')
    elseif player.controls == 'controller_2' and joystick_2 then
      player.dx = paddle_speed * joystick_2:getGamepadAxis('leftx')
      player.dy = paddle_speed * joystick_2:getGamepadAxis('lefty')
    elseif player.controls == 'arrow_keys' then
      if love.keyboard.isDown('left') then
        player.dx = -keyboard_speed
      elseif love.keyboard.isDown('right') then
        player.dx = keyboard_speed
      elseif love.keyboard.isDown('a') then
        player.dx = -keyboard_speed
      elseif love.keyboard.isDown('d') then
        player.dx = keyboard_speed
      else
        player.dx = 0
      end

      if love.keyboard.isDown('up') then
        player.dy = -keyboard_speed
      elseif love.keyboard.isDown('down') then
        player.dy = keyboard_speed
      elseif love.keyboard.isDown('w') then
        player.dy = -keyboard_speed
      elseif love.keyboard.isDown('s') then
        player.dy = keyboard_speed
      else
        player.dy = 0
      end
    elseif player.controls == 'mouse' then
      player.dx = (love.mouse.getX() - player.x) / dt
      player.dy = (love.mouse.getY() - player.y) / dt
    else
      print('Warning: controls "' .. player.controls .. '" not valid or input device not connected')
    end

    local goal_x = clamp(player.x + player.dx * dt, min_x, max_x)
    local goal_y = clamp(player.y + player.dy * dt, min_y, max_y)

    -- if the player's pushing up against a grid edge (presumably against a block)
    if isPushing(player, 'x') then
      -- and the grid in the other dimension is between y and goal_y
      if math.floor(player.y / brick_height) ~= math.floor(goal_y/ brick_height) then
        -- then align to the grid edge
        local new_goal_y
        if goal_y > player.y then
          new_goal_y = math.floor(goal_y / brick_height) * brick_height
        else
          new_goal_y = math.ceil(goal_y / brick_height) * brick_height
        end

        if new_goal_y ~= player.y then
          goal_y = new_goal_y
        end
      end
    elseif isPushing(player, 'y') then
      -- and the grid in the other dimension is between x and goal_x
      if math.floor(player.x / brick_width) ~= math.floor(goal_x/ brick_width) then
        -- then align to the grid edge
        local new_goal_x
        if goal_x > player.x then
          new_goal_x = math.floor(goal_x / brick_width) * brick_width
        else
          new_goal_x = math.ceil(goal_x / brick_width) * brick_width
        end

        if new_goal_x ~= player.x then
          goal_x = new_goal_x
        end
      end
    end

    actual_x, actual_y, cols, len = world:move(player, goal_x, goal_y, signFilter)
    player.x = actual_x
    player.y = actual_y

    -- determine if player got AI flag
    for i, col in ipairs(cols) do
      if col.other.type == 'collectible' then
        remove(emeralds, col.other)
        door_is_open = true
        col.other.width = 10
        col.other.height = 50
      elseif col.other == zombie then
        death()
      end
    end

    -- not sure if this is necessary, but it seems like a healthy precaution
    if clamp(actual_x, min_x, max_x) ~= actual_x then
      player.x = clamp(actual_x, min_x, max_x)
      world:update(player, player.x, player.y)
    end
    if clamp(actual_y, min_y, max_y) ~= actual_y then
      player.y = clamp(actual_y, min_y, max_y)
      world:update(player, player.x, player.y)
    end

    -- move viewport if necessary
    if player.x > (viewport_x +  0.9 * screen_width) then
      viewport_x = viewport_x + 10
    elseif player.x < (viewport_x + 0.1 * screen_width) then
      viewport_x = viewport_x - 10
    end

    if player.y > (viewport_y + 0.9 * screen_height) then
      viewport_y = viewport_y + 10
    elseif player.y < (viewport_y + 0.1 * screen_height) then
      viewport_y = viewport_y - 10
    end
  end

  actual_x, actual_y, cols, len = world:move(zombie, zombie.x + zombie.dx * dt, zombie.y + zombie.dy * dt, signFilter)
  zombie.x = actual_x
  zombie.y = actual_y

  for i, col in ipairs(cols) do
    if col.other == player then
      death()
    elseif col.other.type == "sign" then
      if col.other.dir == "down" then
        zombie.dx = 0
        zombie.dy = keyboard_speed
      elseif col.other.dir == "up-right" then
        zombie.dx = keyboard_speed
        zombie.dy = -keyboard_speed
      elseif col.other.dir == "up-left" then
        zombie.dx = -keyboard_speed
        zombie.dy = -keyboard_speed
      elseif col.other.dir == "down-right" then
        zombie.dx = keyboard_speed
        zombie.dy = keyboard_speed
      elseif col.other.dir == "down-left" then
        zombie.dx = -keyboard_speed
        zombie.dy = keyboard_speed
      end
    end
  end
end

function remove(tbl, obj)
  for i, object in ipairs(tbl) do
    if object == obj then
      table.remove(tbl, i)
      return
    end
  end
end

function death()
  is_paused = true
  love.window.showMessageBox("You Died!", "Sorry buddy, you failed.")
end

-- if player is pushing up against a grid edge (& presumably a brick)
function isPushing(player, dimension)
  if dimension == 'x' then
    return (player.dx < 0 and (player.x % brick_width) == 0) or (player.dx > 0 and ((player.x + player.width) % brick_width == 0))
  elseif dimension == 'y' then
    return (player.dy < 0 and (player.y % brick_height) == 0) or (player.dy > 0 and ((player.y + player.height) % brick_height == 0))
  end
end

function getGridXs(player)
  local xs = {math.floor(player.x / brick_width)}

  -- subtract 1px b/c we're not inclusive on the right edge
  local right_brick_x = math.floor((player.x + player.width - 1) / brick_width)
  if right_brick_x ~= xs[1] then
    table.insert(xs, right_brick_x)
  end

  return xs
end

function getGridYs(player)
  local ys = {math.floor(player.y / brick_height)}

  -- subtract 1px b/c we're not inclusive on the bottom edge
  local bottom_brick_y = math.floor((player.y + player.height - 1) / brick_height)
  if bottom_brick_y ~= ys[1] then
    table.insert(ys, bottom_brick_y)
  end

  return ys
end

function getGridX(player)
  local xs = getGridXs(player)
  if #xs ~= 1 then
    love.errhand("Unexpected number of grid Xs: " .. #xs)
  end
  return xs[1]
end

function getGridY(player)
  local ys = getGridYs(player)
  if #ys ~= 1 then
    love.errhand("Unexpected number of grid Ys: " .. #ys)
  end
  return ys[1]
end

function love.draw()
  -- draw players
  love.graphics.setColor(player_color)
  for i, player in ipairs(players) do
    love.graphics.rectangle("fill", player.x - viewport_x, player.y - viewport_y, player.width, player.height, 10)
    love.graphics.rectangle("line", player.x - viewport_x, player.y - viewport_y, player.width, player.height, 10)
  end

  love.graphics.setColor(zombie_color)
  love.graphics.rectangle("fill", zombie.x - viewport_x, zombie.y - viewport_y, zombie.width, zombie.height, 10)
  love.graphics.rectangle("line", zombie.x - viewport_x, zombie.y - viewport_y, zombie.width, zombie.height, 10)

  -- draw collectibles
  love.graphics.setColor(emerald_color)
  for i, emerald in ipairs(emeralds) do
    love.graphics.rectangle("fill", emerald.x - viewport_x, emerald.y - viewport_y, emerald.width, emerald.height, 10)
    love.graphics.rectangle("line", emerald.x - viewport_x, emerald.y - viewport_y, emerald.width, emerald.height, 10)
    --love.graphics.polygon('fill', 100,100, 200, 100, 150, 200)
  end

  -- draw other objects
  love.graphics.setColor(door_color)
  for i, door in ipairs(doors) do
    if door_is_open then
      love.graphics.rectangle("fill", door.x - viewport_x, door.y - viewport_y, door.width, door.height)
    else
      love.graphics.rectangle("fill", door.x - viewport_x, door.y - viewport_y, door.width, door.height)
    end
  end

  -- draw bricks
  love.graphics.setColor(brick_color)
  for i, brick in ipairs(bricks) do
    if brick ~= 0 then
      local x, y = getBrickXY(i)
      love.graphics.rectangle("fill", brick.x - viewport_x, brick.y - viewport_y, brick.width, brick.height)
    end
  end

  -- draw bullets & flags

  -- print lives/stats in HUD
  love.graphics.setColor(player_color)
  love.graphics.print(#emeralds .. ' / 3', padding, screen_height + 5)
end

function love.keyreleased(key)
   if key == "escape" then
      love.event.quit()
   end
   if key == "space" then
      is_paused = not is_paused
   end
end

function clamp(val, min, max)
  if val < min then
    return min
  end
  if val > max then
    return max
  end
  return val
end