local bump = require 'bump'

padding = 30
-- ball_size = 15
speed = 100
paddle_speed = 500
keyboard_speed = 500
hud_height = 100
num_lives = 5
is_paused = false
viewport_x = 0
viewport_y = 0
brick_color = {174, 115, 210}
ai_flag_color = {217, 65, 65}
player_color = {255, 211, 59}

flag_size = 10
flag_offset = 20

-- other controls: 'mouse', 'controller'
players = {
  { position = 'bottom', x = padding, y = padding + 200, controls = 'wasd' },
  { position = 'top', x = padding, y = padding, controls = 'arrow_keys' }
}

bricks = {}
num_h_bricks = 20
num_w_bricks = 50
brick_height = 60
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

  for i, player in ipairs(players) do
    player.item_type = 'paddle'
    player.score = 0
    player.lives = num_lives

    player.height = 60
    player.width = 50
    player.dx = 0
    player.dy = 0

    world:add(player, player.x, player.y, player.width, player.height)
  end

  -- add flags
  ai_flag = {item_type = 'ai_flag', brick_x = math.random(num_w_bricks), brick_y = math.random(num_h_bricks)}
  ai_flag.x = ai_flag.brick_x * brick_width + flag_offset
  ai_flag.y = ai_flag.brick_y * brick_height + flag_offset
  ai_flag.width = flag_size
  ai_flag.height = flag_size
  world:add(ai_flag, ai_flag.x, ai_flag.y, ai_flag.width, ai_flag.height)

  player_flag = {item_type = 'player_flag', brick_x = math.random(num_w_bricks), brick_y = math.random(num_h_bricks)}
  player_flag.x = player_flag.brick_x * brick_width + flag_offset
  player_flag.y = player_flag.brick_y * brick_height + flag_offset
  player_flag.width = flag_size
  player_flag.height = flag_size
  world:add(player_flag, player_flag.x, player_flag.y, player_flag.width, player_flag.height)  

  -- add bricks
  local num_bricks = num_h_bricks * num_w_bricks
  for i = 1, num_bricks do
    local ix = i - 1 -- b/c Lua is 1-based
    local brick_y = math.floor(ix / num_w_bricks)
    local brick_x = ix % num_w_bricks
    local is_edge = brick_x == 0 or brick_y == 0 or brick_x == (num_w_bricks - 1) or brick_y == (num_h_bricks - 1)
    
    if not is_edge and math.random() > 0.6 and (brick_x ~= ai_flag.brick_x or brick_y ~= ai_flag.brick_y) then
      local x, y = getBrickXY(i)
      bricks[i] = {item_type = 'brick', brick_type = brick, ix = i, x = x, y = y, width = brick_width, height = brick_height}
      local brick = bricks[i]
      world:add(brick, brick.x, brick.y, brick.width, brick.height)
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
      else
        player.dx = 0
      end

      if love.keyboard.isDown('up') then
        player.dy = -keyboard_speed
      elseif love.keyboard.isDown('down') then
        player.dy = keyboard_speed
      else
        player.dy = 0
      end
    elseif player.controls == 'wasd' then
      if love.keyboard.isDown('a') then
        player.dx = -keyboard_speed
      elseif love.keyboard.isDown('d') then
        player.dx = keyboard_speed
      else
        player.dx = 0
      end
      
      if love.keyboard.isDown('w') then
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

    actual_x, actual_y, cols, len = world:move(player, goal_x, goal_y)
    player.x = actual_x
    player.y = actual_y

    -- determine if player got AI flag
    if #cols > 0 then
      if cols[1].other.item_type == 'ai_flag' then
        is_paused = true
        love.window.showMessageBox("You Won!", "Congratulations, you won the game!")
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


  -- if both players are pushing up against grid edges in opposite directions
  -- check if there are solid bricks between them; if there are, squish them all
  if isPushing(players[1], 'x') and isPushing(players[2], 'x') and players[1].dx ~= players[2].dx then
    for i, brick_y1 in ipairs(getGridYs(players[1])) do
      for i2, brick_y2 in ipairs(getGridYs(players[1])) do
        if brick_y1 == brick_y2 then
          local brick_x1 = getGridX(player[1])
          local brick_x2 = getGridX(player[2])

          -- the ...BricksBetween() functions are inclusive of the edges
          -- but we don't want to be, so we increment/decrement
          if (player[1].dx > 0) then
            brick_x1 = brick_x1 + 1
            brick_x2 = brick_x2 - 1
          else
            brick_x1 = brick_x1 - 1
            brick_x2 = brick_x2 + 1
          end

          if solidBricksBetween(brick_x1, brick_y1, brick_x2, brick_y2) then
            destroyBricksBetween(brick_x1, brick_y1, brick_x2, brick_y2)
          end
        end
      end
    end
  end

  if isPushing(players[1], 'y') and isPushing(players[2], 'y') and players[1].dy ~= players[2].dy then
    for i, brick_x1 in ipairs(getGridXs(players[1])) do
      for i2, brick_x2 in ipairs(getGridXs(players[1])) do
        if brick_x1 == brick_x2 then
          local brick_y1 = getGridY(player[1])
          local brick_y2 = getGridY(player[2])

          -- the ...BricksBetween() functions are inclusive of the edges
          -- but we don't want to be, so we increment/decrement
          if (player[1].dy > 0) then
            brick_y1 = brick_y1 + 1
            brick_y2 = brick_y2 - 1
          else
            brick_y1 = brick_y1 - 1
            brick_y2 = brick_y2 + 1
          end

          if solidBricksBetween(brick_x1, brick_y1, brick_x2, brick_y2) then
            destroyBricksBetween(brick_x1, brick_y1, brick_x2, brick_y2)
          end
        end
      end
    end
  end
end

-- if player is pushing up against a grid edge (& presumably a brick)
function isPushing(player, dimension)
  if dimension == 'x' then
    return (player.dx < 0 and (player.x % brick_width) == 0) or (player.dx > 0 and ((player.x + player.width) % brick_width == 0))
  else if dimension == 'y' then
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

function solidBricksBetween(grid_x1, grid_y1, grid_x2, grid_y2)
  local step_x, step_y
  if grid_x2 > grid_x1 then
    step_x = 1
  else
    step_x = -1
  end
  if grid_y2 > grid_y1 then
    step_y = 1
  else
    step_y = -1
  end

  for x = grid_x1, grid_x2, step_x do
    for y = grid_y1, grid_y2, step_y do
      if getBrick(x, y) == 0 then
        return false
      end
    end
  end
  return true
end

function destroyBricksBetween(grid_x1, grid_y1, grid_x2, grid_y2)
  local step_x, step_y
  if grid_x2 > grid_x1 then
    step_x = 1
  else
    step_x = -1
  end
  if grid_y2 > grid_y1 then
    step_y = 1
  else
    step_y = -1
  end

  for x = grid_x1, grid_x2, step_x do
    for y = grid_y1, grid_y2, step_y do
      bricks[getBrickIndex(x, y)] = 0
    end
  end
end

function love.draw()
  -- draw players
  love.graphics.setColor(player_color)
  for i, player in ipairs(players) do
    love.graphics.rectangle("fill", player.x - viewport_x, player.y - viewport_y, player.width, player.height, 10)
    love.graphics.rectangle("line", player.x - viewport_x, player.y - viewport_y, player.width, player.height, 10)
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
  love.graphics.setColor(ai_flag_color)
  -- love.graphics.rectangle("fill", ball.x - viewport_x, ball.y - viewport_y, ball_size, ball_size)
  love.graphics.rectangle("fill", ai_flag.x - viewport_x, ai_flag.y - viewport_y, ai_flag.width, ai_flag.height, 5)
  love.graphics.setColor(player_color)
  love.graphics.rectangle("fill", player_flag.x - viewport_x, player_flag.y - viewport_y, player_flag.width, player_flag.height, 5)

  -- print lives/stats in HUD
  love.graphics.setColor(player_color)
  love.graphics.print(players[1].lives .. ' / ' .. players[1].score, padding, screen_height + 5)
  if players[2] then
    love.graphics.print(players[2].lives .. ' / ' .. players[2].score, screen_width - padding - 150, screen_height + 5)
  end
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