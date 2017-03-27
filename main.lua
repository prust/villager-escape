local bump = require 'bump'

padding = 30
ball_size = 15
speed = 100
paddle_speed = 500
keyboard_speed = 500
hud_height = 100
num_lives = 5
is_paused = false
players = {
  { position = 'bottom', size = 0.2, controls = 'wasd' } --,
  -- { position = 'right', size = 0.1, controls = 'arrow_keys' },
  -- { position = 'left inner', size = 0.15, controls = 'mouse' },
  -- { position = 'right inner', size = 0.15, controls = 'controller' }
}

bricks = {
  0, 0, 0, 1, 1, 1, 0, 0, 0,
  0, 0, 0, 1, 1, 1, 0, 0, 0,
  0, 1, 1, 1, 1, 1, 1, 1, 0,
  0, 0, 0, 1, 1, 1, 0, 0, 0,
  0, 0, 0, 1, 1, 1, 0, 0, 0,
}
num_h_bricks = 9
brick_height = 20
brick_width = 75
brick_spacing = 3
bricks_left_margin = 300
bricks_top_margin = 300

function getBrickXY(ix)
  ix = ix - 1 -- b/c Lua is 1-based
  local y = math.floor(ix / num_h_bricks)
  local x = ix % num_h_bricks
  return bricks_left_margin + x * (brick_width + brick_spacing), bricks_top_margin + y * (brick_height + brick_spacing)
end

local ballBumpFilter = function(item, other)
  return 'bounce'
end

function love.load()
  love.graphics.setBackgroundColor(255, 244, 204)
  love.graphics.setColor(174, 115, 210)
  love.window.setFullscreen(true)
  width, height = love.graphics.getDimensions()
  height = height - hud_height
  world = bump.newWorld()

  love.mouse.setY(height / 2)
  love.mouse.setX(width / 2)
  love.mouse.setVisible(false)

  love.graphics.setFont(love.graphics.newFont(64))

  left_player = nil
  right_player = nil
  bottom_player = nil
  for i, player in ipairs(players) do
    player.item_type = 'paddle'
    player.score = 0
    player.lives = num_lives

    if player.position == 'left' then
      player.orientation = 'vertical'
      left_player = player
      player.x = padding
    elseif player.position == 'right' then
      player.orientation = 'vertical'
      right_player = player
      player.x = width - padding - 10 -- paddle_width
    elseif player.position == 'left inner' then
      player.orientation = 'vertical'
      player.x = padding * 2
    elseif player.position == 'right inner' then
      player.orientation = 'vertical'
      player.x = width - (padding +10) * 2
    elseif player.position == 'bottom' then
      player.orientation = 'horizontal'
      bottom_player = player
      player.y = height - padding - 10 -- paddle_height
    end

    if player.orientation == 'vertical' then
      player.y = height / 2
      player.width = 10
      player.height = player.size * height
    elseif player.orientation == 'horizontal' then
      player.x = width / 2
      player.height = 10
      player.width = player.size * width
    end
    player.dx = 0
    player.dy = 0

    world:add(player, player.x, player.y, player.width, player.height)
  end

  -- add bricks
  for i, brick in ipairs(bricks) do
    if brick ~= 0 then
      local x, y = getBrickXY(i)
      bricks[i] = {item_type = 'brick', brick_type = brick, ix = i, x = x, y = y, width = brick_width, height = brick_height}
      brick = bricks[i]
      world:add(brick, brick.x, brick.y, brick.width, brick.height)
    end
  end

  -- add invisible walls
  local top_wall = {x = 0, y = 0}
  world:add(top_wall, 0,0, width, 1)

  -- in the absence of players, add invisible walls
  if not right_player then
    local right_wall = { x = width, y = 0 }
    world:add(right_wall, width,0, 1, height)
  end

  if not left_player then
    local left_wall = { x = 0, y = 0 }
    world:add(left_wall, 0,0, 1,height)
  end

  if not bottom_player then
    local bottom_wall = {x = 0, y = height}
    world:add(bottom_wall, 0,height, width, 1)
  end

  ball = {
    x = width/2,
    y = height/2
  }
  if bottom_player then
    ball.dx = 2 * speed
    ball.dy = -5 * speed
  else
    ball.dx = -5 * speed
    ball.dy = 2 * speed
  end
  world:add(ball, ball.x, ball.y, ball_size, ball_size)  

  local joysticks = love.joystick.getJoysticks()
  joystick_1 = joysticks[1]
  joystick_2 = joysticks[2]
end

function love.update(dt)
  if is_paused then
    return
  end

  -- move ball
  local goal_x = ball.x + dt * ball.dx
  local goal_y = ball.y + dt * ball.dy
  local actualX, actualY, cols, len = world:move(ball, goal_x, goal_y, ballBumpFilter)
  ball.x = actualX
  ball.y = actualY

  if #cols > 0 then
    -- remove bricks that get hit
    if cols[1].other.item_type == 'brick' then
      local brick = cols[1].other
      world:remove(brick)
      bricks[brick.ix] = 0
    end

    -- change ball direction if it bounces on anything
    local norm = cols[1].normal
    if norm.x == 1 or norm.x == -1 then
      ball.dx = -ball.dx
    end
    if norm.y == 1 or norm.y == -1 then
      ball.dy = -ball.dy
    end

      -- the paddle's vertical speed affects the ball's vert speed
      if cols[1].other.item_type == 'paddle' then
        local paddle = cols[1].other
        if paddle.orientation == 'vertical' then
          ball.dy = clamp(ball.dy + paddle.dy, -6 * speed, 6 * speed)
        else
          ball.dx = clamp(ball.dx + paddle.dx, -6 * speed, 6 * speed)
        end
      end
  end

  -- if someone misses the ball, start over
  if ball.x < 0 and left_player then
    left_player.lives = left_player.lives - 1
    if left_player.lives == 0 then
      is_paused = true
    else
      ball.x = width / 2
      ball.dy = 2 * speed
    end
  elseif ball.x > width and right_player then
    right_player.lives = right_player.lives - 1
    if right_player.lives == 0 then
      is_paused = true
    else
      ball.x = width / 2
      ball.dy = 2 * speed
    end
  elseif ball.y > height and bottom_player then
    bottom_player.lives = bottom_player.lives - 1
    if bottom_player.lives == 0 then
      is_paused = true
    else
      ball.y = height / 2
      ball.dx = 2 * speed
    end
  end
  world:update(ball, ball.x, ball.y)

  -- move players
  for i, player in ipairs(players) do
    local min = 0
    local max

    local prop, dprop
    if player.orientation == 'vertical' then
      prop = 'y'
      dprop = 'dy'
      method = 'getY'
      axis = 'lefty'
      max = height - player.height
      neg_arrow = 'up'
      pos_arrow = 'down'
      neg_wasd = 'w'
      pos_wasd = 's'
    elseif player.orientation == 'horizontal' then
      prop = 'x'
      dprop = 'dx'
      method = 'getX'
      axis = 'leftx'
      max = width - player.width
      neg_arrow = 'left'
      pos_arrow = 'right'
      neg_wasd = 'a'
      pos_wasd = 'd'
    end

    if player.controls == 'controller' and joystick_1 then
      player[dprop] = paddle_speed * joystick_1:getGamepadAxis(axis)
    elseif player.controls == 'controller_2' and joystick_2 then
      player[dprop] = paddle_speed * joystick_2:getGamepadAxis(axis)
    elseif player.controls == 'arrow_keys' then
      if love.keyboard.isDown(neg_arrow) then
        player[dprop] = -keyboard_speed
      elseif love.keyboard.isDown(pos_arrow) then
        player[dprop] = keyboard_speed
      else
        player[dprop] = 0
      end
    elseif player.controls == 'wasd' then
      if love.keyboard.isDown(neg_wasd) then
        player[dprop] = -keyboard_speed
      elseif love.keyboard.isDown(pos_wasd) then
        player[dprop] = keyboard_speed
      else
        player[dprop] = 0
      end
    elseif player.controls == 'mouse' then
      player[dprop] = (love.mouse[method]() - player[prop]) / dt
    else
      print('Warning: controls "' .. player.controls .. '" not valid or input device not connected')
    end

    local goal = player[prop] + player[dprop] * dt
    goal = clamp(goal, min, max)

    local actual
    if player.orientation == 'vertical' then
      actualX, actualY, cols, len = world:move(player, player.x, goal)
      actual = actualY
    elseif player.orientation == 'horizontal' then
      actualX, actualY, cols, len = world:move(player, goal, player.y)
      actual = actualX
    end
    player[prop] = actual

    -- not sure if this is necessary, but it seems like a healthy precaution
    if clamp(actual, min, max) ~= actual then
      player[prop] = clamp(actual, min, max)
      world:update(player, player.x, player.y)
    end
  end
end

function love.draw()
  for i, player in ipairs(players) do
    love.graphics.rectangle("fill", player.x, player.y, player.width, player.height)
  end
  for i, brick in ipairs(bricks) do
    if brick ~= 0 then
      local x, y = getBrickXY(i)
      love.graphics.rectangle("fill", brick.x, brick.y, brick.width, brick.height)
    end
  end
  love.graphics.rectangle("fill", ball.x, ball.y, ball_size, ball_size)
  love.graphics.print(players[1].lives, padding, height + 5)
  if players[2] then
    love.graphics.print(players[2].lives, width - padding - 50, height + 5)
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