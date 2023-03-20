--[[
    PauseState class

    Pause state happens when the user inputs a certain button
    such as P, shift, etc.
]]


PauseState = Class{__includes = BaseState}

function PauseState:enter(params) 
    scrolling = false
    self.bird = params["bird"]
    self.pipePairs = params["pipePairs"]
    self.score = params["score"]
end



function PauseState:update(dt)
    -- We will transition back into the playState
    -- when the user presses these certain buttons
    if love.keyboard.wasPressed('p')
    then
        sounds['pause']:play()
        sounds['music']:play()
        gStateMachine:unPauseState()
    end
end


function PauseState:render()

    for k, pair in pairs(self.pipePairs) do
        pair:render()
    end
    love.graphics.print('Score: ' .. tostring(self.score), 8, 8)
    self.bird:render()

    love.graphics.print('Game Paused', VIRTUAL_WIDTH/2 - 30, 8)
    love.graphics.draw(pauseIcon, VIRTUAL_WIDTH/2, VIRTUAL_HEIGHT/2, 0, 5, 5, 5, 5)
end

function PauseState:exit() 
    scrolling = true
end