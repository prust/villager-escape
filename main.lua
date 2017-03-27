local bump = require 'bump'

padding = 30
ball_size = 15
speed = 100
paddle_speed = 500
keyboard_speed = 500
hud_height = 100
players = {
  { position = 'left', size = 0.2, controls = 'wasd' } --,
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
  love.mouse.setVisible(false)

  love.graphics.setFont(love.graphics.newFont(64))

  for i, player in ipairs(players) do
    player.item_type = 'paddle'
    player.score = 0

    if player.position == 'left' then
      player.orientation = 'vertical'
      player.x = padding
    elseif player.position == 'right' then
      player.orientation = 'vertical'
      player.x = width - padding - 10 -- paddle_width
    elseif player.position == 'left inner' then
      player.orientation = 'vertical'
      player.x = padding * 2
    elseif player.position == 'right inner' then
      player.orientation = 'vertical'
      player.x = width - (padding +10) * 2
    end

    if player.orientation == 'vertical' then
      player.y = height / 2
      player.width = 10
      player.height = player.size * height
      player.dy = 0
    end

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

  -- add invisible top & bottom walls
  local top_wall = {x = 0, y = 0}
  local bottom_wall = {x = 0, y = height}
  world:add(top_wall, 0,0, width, 1)
  world:add(bottom_wall, 0,height, width, 1)

  -- if there is no 2nd player, add right wall
  local is_right_player = false
  for i, player in ipairs(players) do
    if player.position == 'right' then
      is_right_player = true
    end
  end
  if not is_right_player then
    local right_wall = { x = width, y = 0 }
    world:add(right_wall, width,0, 1, height)
  end

  ball = {
    x = width/2,
    y = height/2,
    dx = -5 * speed,
    dy = 2 * speed
  }
  world:add(ball, ball.x, ball.y, ball_size, ball_size)  

  local joysticks = love.joystick.getJoysticks()
  joystick_1 = joysticks[1]
  joystick_2 = joysticks[2]
end

function love.update(dt)
  -- move ball
  local goal_x = ball.x + dt * ball.dx
  local goal_y = ball.y + dt * ball.dy
  local actualX, actualY, cols, len = world:move(ball, goal_x, goal_y, ballBumpFilter)
  ball.x = actualX
  ball.y = actualY

  if #cols > 0 then
    if cols[1].other.item_type == 'brick' then
      local brick = cols[1].other
      world:remove(brick)
      bricks[brick.ix] = 0
    end
    local norm = cols[1].normal
      if norm.x == 1 or norm.x == -1 then
        ball.dx = -ball.dx
      end
      if norm.y == 1 or norm.y == -1 then
        ball.dy = -ball.dy
      end

      -- the paddle's vertical speed affects the ball's vert speed
      if cols[1].other.item_type == 'paddle' then
        ball.dy = clamp(ball.dy + cols[1].other.dy, -6 * speed, 6 * speed)
      end
  end

  -- someone lost/won, start over
  if ball.x < 0 or ball.x > width then
    if ball.x < 0 then
      if players[2] then
        players[2].score = players[2].score + 1
      end if
    else
      players[1].score = players[1].score + 1
    end
    ball.x = width / 2
    ball.dy = 2 * speed
    world:update(ball, ball.x, ball.y)
  end

  -- move players
  for i, player in ipairs(players) do
    local min = 0
    local max = height - player.height

    if player.controls == 'controller' and joystick_1 then
      player.dy = paddle_speed * joystick_1:getGamepadAxis("lefty")
    elseif player.controls == 'controller_2' and joystick_2 then
      player.dy = paddle_speed * joystick_2:getGamepadAxis("lefty")
    elseif player.controls == 'arrow_keys' then
      if love.keyboard.isDown('up') then
        player.dy = -keyboard_speed
      elseif love.keyboard.isDown('down') then
        player.dy = keyboard_speed
      else
        player.dy = 0
      end
    elseif player.controls == 'wasd' then
      if love.keyboard.isDown('w') then
        player.dy = -keyboard_speed
      elseif love.keyboard.isDown('s') then
        player.dy = keyboard_speed
      else
        player.dy = 0
      end
    elseif player.controls == 'mouse' then
      player.dy = (love.mouse.getY() - player.y) / dt
    else
      print('Warning: controls "' .. player.controls .. '" not valid or input device not connected')
    end

    local goal_y = player.y + player.dy * dt
    goal_y = clamp(goal_y, min, max)
    local actualX, actualY, cols, len = world:move(player, player.x, goal_y)
    player.y = actualY

    -- not sure if this is necessary, but it seems like a healthy precaution
    if clamp(actualY, min, max) ~= actualY then
      player.y = clamp(actualY, min, max)
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
  love.graphics.print(players[1].score, padding, height + 5)
  if players[2] then
    love.graphics.print(players[2].score, width - padding - 50, height + 5)
  end
end

function love.keyreleased(key)
   if key == "escape" then
      love.event.quit()
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