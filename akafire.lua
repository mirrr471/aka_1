local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")

-- 플레이어와 캐릭터 가져오기
local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid")
local rootPart = character:WaitForChild("HumanoidRootPart")

-- 이펙트를 위한 Attachment 생성 (캐릭터 중심에서 시작)
local attachment = Instance.new("Attachment")
attachment.Position = Vector3.new(0, 0, 0) -- 캐릭터 중심
attachment.Parent = rootPart

-- 두께, 속도 및 거리 조절 변수
local thickness = 7 -- 이펙트 두께 설정
local speed = 2000 -- 이펙트 속도 설정
local maxDistance = 100 -- 이펙트가 이동할 최대 거리 (스터드 단위)

-- ParticleEmitter: Sparks (XML 기반)
local sparks = Instance.new("ParticleEmitter")
sparks.Name = "Sparks"
sparks.Enabled = false
sparks.Brightness = 5
sparks.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
sparks.Drag = 5
sparks.Lifetime = NumberRange.new(maxDistance / speed, maxDistance / speed) -- 거리 / 속도 = Lifetime
sparks.Rate = 700
sparks.RotSpeed = NumberRange.new(-100, 100)
sparks.Rotation = NumberRange.new(-360, 360)
sparks.Shape = Enum.ParticleEmitterShape.Box -- 직진을 위해 Box로 변경
sparks.ShapeInOut = Enum.ParticleEmitterShapeInOut.Inward -- 퍼짐 방지
sparks.Size = NumberSequence.new({
    NumberSequenceKeypoint.new(0, thickness), -- 두께 조절
    NumberSequenceKeypoint.new(1, 0)
})
sparks.Speed = NumberRange.new(speed, speed) -- 속도 조절
sparks.SpreadAngle = Vector2.new(0, 0) -- 퍼짐 없음
sparks.Texture = "rbxassetid://11817592243"
sparks.Transparency = NumberSequence.new({
    NumberSequenceKeypoint.new(0, 0),
    NumberSequenceKeypoint.new(1, 0)
})
sparks.ZOffset = 3
sparks.Parent = attachment

-- 화면 반전 효과 설정
local function applyScreenFlash()
    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Name = "FlashEffect"
    colorCorrection.Enabled = true
    colorCorrection.TintColor = Color3.new(1, 0, 0) -- 빨간색 반전
    colorCorrection.Brightness = -0.2
    colorCorrection.Contrast = 0.3
    colorCorrection.Saturation = -0.5
    colorCorrection.Parent = Lighting

    task.delay(0.3, function()
        colorCorrection:Destroy()
    end)
end

-- 잔상 효과 생성 (단일 잔상)
local function createAfterImage(position)
    local afterImageAttachment = Instance.new("Attachment")
    afterImageAttachment.Position = position -- 이펙트 경로 상의 위치
    afterImageAttachment.Parent = workspace.Terrain

    local afterImage = Instance.new("ParticleEmitter")
    afterImage.Name = "AfterImage"
    afterImage.Enabled = true
    afterImage.Brightness = 5
    afterImage.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
    afterImage.Lifetime = NumberRange.new(0.2, 0.2) -- 0.2초 동안 보임
    afterImage.Rate = 50
    afterImage.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, thickness * 0.5), -- 잔상 크기 조정
        NumberSequenceKeypoint.new(1, 0)
    })
    afterImage.Speed = NumberRange.new(0, 0) -- 이동 없음
    afterImage.SpreadAngle = Vector2.new(0, 0)
    afterImage.Texture = "rbxassetid://11817592243"
    afterImage.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0.5),
        NumberSequenceKeypoint.new(1, 1) -- 자연스럽게 사라짐
    })
    afterImage.Parent = afterImageAttachment

    task.delay(0.2, function()
        afterImageAttachment:Destroy()
    end)
end

-- 이펙트 경로를 따라 잔상 생성 (startPos에서 endPos 방향으로)
local function createAfterImagesAlongPath(startPos, endPos)
    local distance = (endPos - startPos).Magnitude
    local step = 5 -- 잔상 생성 간격 (스터드 단위, 더 촘촘하게)
    local steps = math.floor(distance / step)

    for i = 0, steps, 1 do -- 순방향으로 잔상 생성
        local t = i / steps
        local position = startPos:Lerp(endPos, t) -- 경로를 따라 선형 보간
        createAfterImage(position)
    end
end

-- 이펙트 활성화/비활성화 함수
local function activateEffects()
    -- 캐릭터가 보는 방향으로 이펙트 설정
    local lookDirection = rootPart.CFrame.LookVector -- 방향을 캐릭터가 보는 방향으로 설정
    sparks.EmissionDirection = Enum.NormalId.Front
    attachment.WorldCFrame = CFrame.new(rootPart.Position + Vector3.new(0, 0, -2)) * CFrame.lookAt(Vector3.new(0, 0, 0), lookDirection)

    -- 이펙트 활성화
    sparks.Enabled = true

    -- 화면 반전 효과 적용
    applyScreenFlash()

    -- 이펙트 경로 계산 및 잔상 생성
    local startPos = rootPart.Position + Vector3.new(0, 0, -2)
    local endPos = startPos + (lookDirection * maxDistance)
    createAfterImagesAlongPath(startPos, endPos)

    -- 짧은 시간 후 Rate를 0으로 설정해 추가 방출 방지
    task.delay(maxDistance / speed, function()
        sparks.Rate = 0
    end)

    -- 1초 후 비활성화
    task.delay(1, function()
        deactivateEffects()
    end)
end

local function deactivateEffects()
    sparks.Enabled = false
    sparks.Rate = 700
end

-- 스크립트 시작 시 이펙트 자동 활성화
activateEffects()

-- 캐릭터 리셋 시 이펙트 다시 설정
player.CharacterAdded:Connect(function(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    rootPart = character:WaitForChild("HumanoidRootPart")
    
    -- Attachment 재설정
    attachment.Parent = nil
    attachment.Position = Vector3.new(0, 0, 0)
    attachment.Parent = rootPart
    sparks.Parent = attachment
    
    -- 이펙트 비활성화 상태로 초기화
    deactivateEffects()
    
    -- 캐릭터 리셋 후 이펙트 자동 활성화
    activateEffects()
end)
