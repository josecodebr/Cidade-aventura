-- =========================================================
-- MINI ENGINE 2D MODULAR E ORIENTADA A ENTIDADES EM LÖVE2D
-- =========================================================

local engine = {}

-- ===================== CONFIGURAÇÕES GLOBAIS DA ENGINE =====================
engine.config = {
    windowWidth = 800,
    windowHeight = 600,
    gravityStrength = 1000, -- Força da gravidade (pixels/segundo^2). Defina como 0 para desativar.
    debugDraw = false,      -- Desenha retângulos de colisão para depuração
    limitEntitiesToWindow = true, -- Se entidades que não são players devem ficar presas na tela
    masterVolume = 0.7,     -- Volume global (0.0 a 1.0)
    musicVolume = 1.0,      -- Volume da música (0.0 a 1.0, relativo ao master)
    sfxVolume = 1.0         -- Volume dos efeitos sonoros (0.0 a 1.0, relativo ao master)
}

-- Listas de Gerenciamento de Entidades e Assets
engine.entities = {}
engine.assets = {} -- Já contém os assets de imagem e áudio
engine.nextEntityId = 1
engine.prefabs = {}

-- ===================== UTILITÁRIOS =====================
function engine.generateId()
    local id = engine.nextEntityId
    engine.nextEntityId = engine.nextEntityId + 1
    return id
end

function engine.loadAsset(name, path, width, height)
    local image = love.graphics.newImage(path)
    engine.assets[name] = {
        image = image,
        width = width or image:getWidth(),
        height = height or image:getHeight()
    }
    print("Imagem carregada: " .. name .. " (" .. path .. ")")
end

-- ===================== MÓDULO DE FÍSICA =====================
function engine.checkCollision(e1, e2)
    if not (e1.x and e1.y and e1.width and e1.height and e2.x and e2.y and e2.width and e2.height) then
        return false, "none"
    end
    local e1_left, e1_right = e1.x, e1.x + e1.width
    local e1_top, e1_bottom = e1.y, e1.y + e1.height
    local e2_left, e2_right = e2.x, e2.x + e2.width
    local e2_top, e2_bottom = e2.y, e2.y + e2.height

    if e1_right > e2_left and e1_left < e2_right and e1_bottom > e2_top and e1_top < e2_bottom then
        local overlapX = math.min(e1_right, e2_right) - math.max(e1_left, e2_left)
        local overlapY = math.min(e1_bottom, e2_bottom) - math.max(e1_top, e2_top)

        if overlapX < overlapY then
            if e1_left < e2_left then return true, "right" else return true, "left" end
        else
            if e1_top < e2_top then return true, "bottom" else return true, "top" end
        end
    end
    return false, "none"
end

function engine.resolveCollision(e1, e2, direction)
    if direction == "bottom" then
        e1.y = e2.y - e1.height
        e1.dy = 0
        if e1.canJump then e1.onGround = true end
    elseif direction == "top" then
        e1.y = e2.y + e2.height
        e1.dy = 0
    elseif direction == "left" then
        e1.x = e2.x + e2.width
        e1.dx = 0
    elseif direction == "right" then
        e1.x = e2.x - e1.width
        e1.dx = 0
    end
end

-- ===================== MÓDULO DE ENTIDADES =====================
function engine.createEntity(type, properties)
    local entity = {
        id = engine.generateId(),
        type = type,
        x = properties.x or 0,
        y = properties.y or 0,
        dx = properties.dx or 0,
        dy = properties.dy or 0,
        speed = properties.speed or 0,
        sprite = properties.sprite,
        width = properties.width,
        height = properties.height,
        direction = 1, -- 1 para direita, -1 para esquerda (usado para flipar sprite)
        isAffectedByGravity = properties.isAffectedByGravity or false,
        isSolid = properties.isSolid or false,
        canJump = properties.canJump or false,
        onGround = false,
        patrol = properties.patrol
    }
    if entity.sprite and engine.assets[entity.sprite] and engine.assets[entity.sprite].image then
        entity.width = entity.width or engine.assets[entity.sprite].width
        entity.height = entity.height or engine.assets[entity.sprite].height
    end
    table.insert(engine.entities, entity)
    return entity
end

function engine.removeEntity(id)
    for i, e in ipairs(engine.entities) do
        if e.id == id then table.remove(engine.entities, i) return true end
    end
    return false
end

-- ===================== MÓDULO DE PREFABS =====================
engine.prefabs = {} -- Tabela para armazenar os modelos de entidades

--- engine.definePrefab(name, defaultProperties)
-- Define um novo modelo (prefab) de entidade.
function engine.definePrefab(name, defaultProperties)
    if engine.prefabs[name] then
        print("Atenção: Prefab '" .. name .. "' já existe e foi sobrescrito.")
    end
    engine.prefabs[name] = defaultProperties
end

--- engine.createPrefab(name, instanceProperties)
-- Cria uma nova entidade baseada em um prefab existente.
function engine.createPrefab(name, instanceProperties)
    local prefab = engine.prefabs[name]
    if not prefab then
        error("Erro: Prefab '" .. name .. "' não definido. Crie-o com engine.definePrefab primeiro.")
    end

    local finalProperties = {}
    for k, v in pairs(prefab) do
        finalProperties[k] = v
    end
    if instanceProperties then
        for k, v in pairs(instanceProperties) do
            finalProperties[k] = v
        end
    end

    return engine.createEntity(finalProperties.type or "default", finalProperties)
end

-- ===================== ENTIDADES (ABSTRAÇÕES PARA CRIAÇÃO FÁCIL) =====================

--- engine.createPlayer(x, y, speed, spriteName)
-- Cria uma entidade de jogador pré-configurada usando um prefab.
function engine.createPlayer(x, y, speed, spriteName)
    if not engine.prefabs.Player then
        engine.definePrefab("Player", {
            type = "player",
            speed = 200,
            sprite = "player_sprite",
            isAffectedByGravity = true,
            isSolid = true,
            canJump = true
        })
    end
    local player = engine.createPrefab("Player", {x = x, y = y, speed = speed, sprite = spriteName})
    engine.player = player
    return player
end

--- engine.createStaticEnemy(x, y, spriteName)
-- Cria uma entidade de inimigo que fica parada, afetada pela gravidade, usando um prefab.
function engine.createStaticEnemy(x, y, spriteName)
    if not engine.prefabs.StaticEnemy then
        engine.definePrefab("StaticEnemy", {
            type = "enemy",
            speed = 0,
            sprite = "enemy_sprite",
            isAffectedByGravity = true,
            isSolid = true
        })
    end
    return engine.createPrefab("StaticEnemy", {x = x, y = y, sprite = spriteName})
end

--- engine.createPatrollingEnemy(x, y, speed, minX, maxX, spriteName)
-- Cria uma entidade de inimigo que patrulha horizontalmente usando um prefab.
function engine.createPatrollingEnemy(x, y, speed, minX, maxX, spriteName)
    if not engine.prefabs.PatrollingEnemy then
        engine.definePrefab("PatrollingEnemy", {
            type = "enemy",
            speed = 80,
            sprite = "enemy_sprite",
            isAffectedByGravity = true,
            isSolid = true,
            patrol = {}
        })
    end
    return engine.createPrefab("PatrollingEnemy", {x = x, y = y, speed = speed, patrol = {minX = minX, maxX = maxX}, sprite = spriteName})
end

--- engine.createPlatform(x, y, num_blocks, tile_sprite_name)
-- Cria uma plataforma composta por múltiplos blocos, que são entidades sólidas.
function engine.createPlatform(x, y, num_blocks, tile_sprite_name)
    local tile = engine.assets[tile_sprite_name]
    if not tile then error("Asset de plataforma não encontrado: " .. tile_sprite_name) end

    if not engine.prefabs.PlatformBlock then
        engine.definePrefab("PlatformBlock", {
            type = "platform_block",
            isSolid = true,
            sprite = tile_sprite_name -- Usa o sprite passado para a plataforma como padrão
        })
    end

    for i = 0, num_blocks - 1 do
        engine.createPrefab("PlatformBlock", {
            x = x + i * tile.width,
            y = y,
            width = tile.width,
            height = tile.height,
            sprite = tile_sprite_name -- Garante que cada bloco use o sprite correto
        })
    end
end

-- ===================== MÓDULO DE CÂMERA =====================
engine.camera = {
    x = 0,
    y = 0,
    target = nil,
    shakeIntensity = 0,
    shakeDuration = 0,
    shakeTimer = 0,
    minX = 0,
    maxX = engine.config.windowWidth,
    minY = 0,
    maxY = engine.config.windowHeight
}

--- engine.camera.setLimits(minX, maxX, minY, maxY)
-- Define os limites pelos quais a câmera pode se mover.
function engine.camera.setLimits(minX, maxX, minY, maxY)
    engine.camera.minX = minX
    engine.camera.maxX = maxX - engine.config.windowWidth
    engine.camera.minY = minY
    engine.camera.maxY = maxY - engine.config.windowHeight
end

--- engine.camera.follow(entity)
-- Define uma entidade para a câmera seguir.
function engine.camera.follow(entity)
    engine.camera.target = entity
end

--- engine.camera.shake(intensity, duration)
-- Aplica um efeito de "tremor" na câmera.
function engine.camera.shake(intensity, duration)
    engine.camera.shakeIntensity = intensity
    engine.camera.shakeDuration = duration
    engine.camera.shakeTimer = duration
end

--- engine.camera.update(dt)
-- Atualiza a posição da câmera a cada frame.
function engine.camera.update(dt)
    if engine.camera.target then
        local target = engine.camera.target
        local centerX = target.x + target.width / 2
        local centerY = target.y + target.height / 2

        engine.camera.x = centerX - engine.config.windowWidth / 2
        engine.camera.y = centerY - engine.config.windowHeight / 2

        engine.camera.x = math.max(engine.camera.minX, math.min(engine.camera.maxX, engine.camera.x))
        engine.camera.y = math.max(engine.camera.minY, math.min(engine.camera.maxY, engine.camera.y))
    end

    if engine.camera.shakeTimer > 0 then
        engine.camera.shakeTimer = engine.camera.shakeTimer - dt
        local offsetX = math.random() * engine.camera.shakeIntensity * 2 - engine.camera.shakeIntensity
        local offsetY = math.random() * engine.camera.shakeIntensity * 2 - engine.camera.shakeIntensity
        love.graphics.translate(offsetX, offsetY)
    else
        engine.camera.shakeIntensity = 0
    end
end

-- ===================== MÓDULO DE PARTÍCULAS =====================
engine.particles = {}
engine.particles.emitters = {}

--- engine.particles.newEmitter(x, y, properties)
-- Cria e retorna um novo sistema de partículas.
function engine.particles.newEmitter(x, y, properties)
    properties = properties or {}
    local emitter = {
        x = x,
        y = y,
        sprite = properties.sprite,
        color = properties.color or {1, 1, 1, 1},
        startSize = properties.startSize or 8,
        endSize = properties.endSize or 0,
        lifeTime = properties.lifeTime or 1,
        speed = properties.speed or 50,
        spread = properties.spread or 360,
        emissionRate = properties.emissionRate or 20,
        duration = properties.duration or 0,
        gravityFactor = properties.gravityFactor or 0,
        minAngle = properties.minAngle,
        maxAngle = properties.maxAngle,
        burst = properties.burst or 0,
        
        particles = {},
        timeToEmit = 0,
        emitterTimer = 0,
        isDead = false
    }

    function emitter:update(dt)
        if self.isDead then return end

        self.emitterTimer = self.emitterTimer + dt

        if self.duration == 0 or self.emitterTimer <= self.duration then
            self.timeToEmit = self.timeToEmit + dt
            while self.timeToEmit >= 1 / self.emissionRate do
                self.timeToEmit = self.timeToEmit - (1 / self.emissionRate)
                self:createParticle()
            end
        elseif self.duration > 0 and self.emitterTimer > self.duration then
            if #self.particles == 0 then
                self.isDead = true
            end
        end

        for i = #self.particles, 1, -1 do
            local p = self.particles[i]
            p.life = p.life - dt

            if p.life <= 0 then
                table.remove(self.particles, i)
            else
                if self.gravityFactor ~= 0 then
                    p.dy = p.dy + engine.config.gravityStrength * self.gravityFactor * dt
                end

                p.x = p.x + p.dx * dt
                p.y = p.y + p.dy * dt

                local lifeRatio = p.life / p.initialLife
                p.currentSize = self.startSize + (self.endSize - self.startSize) * (1 - lifeRatio)
                
                if self.color then
                    p.currentColor = {self.color[1], self.color[2], self.color[3], self.color[4] * lifeRatio}
                end
            end
        end
    end

    function emitter:createParticle()
        local angle = (self.minAngle and self.maxAngle) and math.random(self.minAngle * 100, self.maxAngle * 100) / 100 or math.random() * math.pi * 2
        local speed = self.speed * (0.8 + math.random() * 0.4)
        
        local dx = math.cos(angle) * speed
        local dy = math.sin(angle) * speed
        
        local particle = {
            x = self.x,
            y = self.y,
            dx = dx,
            dy = dy,
            life = self.lifeTime,
            initialLife = self.lifeTime,
            currentSize = self.startSize,
            currentColor = self.color
        }
        table.insert(self.particles, particle)
    end

    function emitter:draw()
        if self.isDead and #self.particles == 0 then return end

        if self.sprite and engine.assets[self.sprite] then
            local img = engine.assets[self.sprite].image
            for _, p in ipairs(self.particles) do
                local s = p.currentSize / img:getWidth()
                love.graphics.setColor(p.currentColor[1], p.currentColor[2], p.currentColor[3], p.currentColor[4])
                love.graphics.draw(img, p.x, p.y, 0, s, s, img:getWidth()/2, img:getHeight()/2)
            end
        elseif self.color then
            for _, p in ipairs(self.particles) do
                love.graphics.setColor(p.currentColor[1], p.currentColor[2], p.currentColor[3], p.currentColor[4])
                love.graphics.circle("fill", p.x, p.y, p.currentSize / 2)
            end
        end
        love.graphics.setColor(1, 1, 1, 1)
    end

    for i = 1, emitter.burst do
        emitter:createParticle()
    end

    table.insert(engine.particles.emitters, emitter)
    return emitter
end

-- ===================== MÓDULO DE GERENCIAMENTO DE ESTADOS/CENAS =====================
engine.stateManager = {
    currentState = nil,
    states = {}
}

--- engine.stateManager.addState(name, stateTable)
-- Adiciona uma nova definição de estado/cena.
function engine.stateManager.addState(name, stateTable)
    if engine.stateManager.states[name] then
        print("Atenção: Estado '" .. name .. "' já existe e foi sobrescrito.")
    end
    engine.stateManager.states[name] = stateTable
end

--- engine.stateManager.changeState(name)
-- Muda para um novo estado.
function engine.stateManager.changeState(name)
    local newState = engine.stateManager.states[name]
    if not newState then
        error("Erro: Estado '" .. name .. "' não definido. Adicione-o com engine.stateManager.addState primeiro.")
    end

    -- Limpa a engine para o novo estado
    engine.entities = {}
    engine.particles.emitters = {}
    engine.nextEntityId = 1
    engine.player = nil -- Reinicia a referência ao player
    engine.camera.target = nil

    engine.stateManager.currentState = newState
    if engine.stateManager.currentState.load then
        engine.stateManager.currentState.load()
    end
end

-- ===================== MÓDULO DE ÁUDIO =====================
engine.audio = {
    sources = {},
    currentMusic = nil
}

--- engine.audio.loadSound(name, path, isMusic, isLooping)
-- Carrega um arquivo de áudio e o armazena na engine.assets.
function engine.audio.loadSound(name, path, isMusic, isLooping)
    isMusic = isMusic or false
    isLooping = isLooping or false

    local source = love.audio.newSource(path, isMusic and "stream" or "static")
    source:setLooping(isLooping)
    engine.assets[name] = {
        type = "audio",
        source = source,
        isMusic = isMusic
    }
    print("Áudio carregado: " .. name .. " (" .. path .. ")")
end

--- engine.audio.playSound(name, volumeOverride)
-- Toca um efeito sonoro (SFX).
function engine.audio.playSound(name, volumeOverride)
    local asset = engine.assets[name]
    if asset and asset.type == "audio" and not asset.isMusic then
        local volume = volumeOverride or engine.config.sfxVolume
        asset.source:setVolume(volume * engine.config.masterVolume)
        asset.source:play()
    else
        print("Atenção: SFX '" .. name .. "' não encontrado ou não é um SFX válido.")
    end
end

--- engine.audio.playMusic(name, fadeDuration)
-- Toca uma faixa de música.
function engine.audio.playMusic(name, fadeDuration)
    fadeDuration = fadeDuration or 0
    local newMusicAsset = engine.assets[name]

    if not (newMusicAsset and newMusicAsset.type == "audio" and newMusicAsset.isMusic) then
        print("Atenção: Música '" .. name .. "' não encontrada ou não é uma música válida.")
        return
    end

    if engine.audio.currentMusic and engine.audio.currentMusic.source:isPlaying() then
        if engine.audio.currentMusic ~= newMusicAsset then
            engine.audio.currentMusic.source:stop()
        else
            return
        end
    end

    engine.audio.currentMusic = newMusicAsset
    
    -- Para um fade suave, um sistema de tweening seria melhor aqui.
    -- Por simplicidade, definimos o volume alvo diretamente.
    local targetVolume = engine.config.musicVolume * engine.config.masterVolume
    engine.audio.currentMusic.source:setVolume(targetVolume)
    engine.audio.currentMusic.source:play()
end

--- engine.audio.stopMusic()
-- Para a música atualmente tocando.
function engine.audio.stopMusic()
    if engine.audio.currentMusic and engine.audio.currentMusic.source:isPlaying() then
        engine.audio.currentMusic.source:stop()
        engine.audio.currentMusic = nil
    end
end

--- engine.audio.setMasterVolume(volume)
-- Define o volume mestre global.
function engine.audio.setMasterVolume(volume)
    engine.config.masterVolume = math.max(0, math.min(1, volume))
    love.audio.setVolume(engine.config.masterVolume) -- LÖVE2D tem um volume global próprio
    
    if engine.audio.currentMusic and engine.audio.currentMusic.source:isPlaying() then
        engine.audio.currentMusic.source:setVolume(engine.config.musicVolume * engine.config.masterVolume)
    end
end

--- engine.audio.setMusicVolume(volume)
-- Define o volume da música.
function engine.audio.setMusicVolume(volume)
    engine.config.musicVolume = math.max(0, math.min(1, volume))
    if engine.audio.currentMusic and engine.audio.currentMusic.source:isPlaying() then
        engine.audio.currentMusic.source:setVolume(engine.config.musicVolume * engine.config.masterVolume)
    end
end

--- engine.audio.setSfxVolume(volume)
-- Define o volume dos efeitos sonoros.
function engine.config.sfxVolume(volume)
    engine.config.sfxVolume = math.max(0, math.min(1, volume))
end

-- ===================== UPDATE PRINCIPAL =====================
function engine.update(dt)
    -- Lógica de input do jogador (específico para o tipo 'player' e se 'canJump' for true)
    if engine.player and engine.player.canJump then
        engine.player.onGround = false
        if love.keyboard.isDown("left") then
            engine.player.dx = -engine.player.speed
            engine.player.direction = -1
        elseif love.keyboard.isDown("right") then
            engine.player.dx = engine.player.speed
            engine.player.direction = 1
        else
            engine.player.dx = 0
        end

        -- Aplica limites da tela ao jogador, se a configuração estiver ativa
        if engine.config.limitEntitiesToWindow then
            engine.player.x = math.max(0, math.min(engine.config.windowWidth - engine.player.width, engine.player.x))
            -- O limite Y inferior é gerenciado por colisões, mas um "fallback" pode ser necessário
            engine.player.y = math.min(engine.config.windowHeight - engine.player.height, engine.player.y)
        end
    end

    -- Atualizar todas as entidades
    for _, e in ipairs(engine.entities) do
        if e.isAffectedByGravity and engine.config.gravityStrength > 0 then
            e.dy = e.dy + engine.config.gravityStrength * dt
        end
        e.x = e.x + e.dx * dt
        e.y = e.y + e.dy * dt

        if e.type == "enemy" and e.patrol then
            e.x = e.x + e.speed * e.direction * dt
            if (e.direction == 1 and e.x + e.width >= e.patrol.maxX) or
               (e.direction == -1 and e.x <= e.patrol.minX) then
                e.direction = -e.direction
            end
        end

        -- Aplica limites da tela para entidades NÃO-jogador, se configurado
        if engine.config.limitEntitiesToWindow and e.type ~= "player" then
            e.x = math.max(0, math.min(engine.config.windowWidth - e.width, e.x))
            e.y = math.min(engine.config.windowHeight - e.height, e.y) -- Previne cair para sempre
        end
    end

    -- Atualização da câmera
    engine.camera.update(dt)

    -- Atualização do sistema de partículas
    for i = #engine.particles.emitters, 1, -1 do
        local emitter = engine.particles.emitters[i]
        emitter:update(dt)
        if emitter.isDead then
            table.remove(engine.particles.emitters, i)
        end
    end

    -- Resolução de colisões entre entidades
    for i, e1 in ipairs(engine.entities) do
        for j, e2 in ipairs(engine.entities) do
            if e1.id ~= e2.id and e2.isSolid then
                local colidiu, dir = engine.checkCollision(e1, e2)
                if colidiu then
                    engine.resolveCollision(e1, e2, dir)
                    if e1.type == "player" and e2.type == "enemy" then
                        if dir == "bottom" then
                            engine.removeEntity(e2.id)
                            e1.dy = -200
                            engine.audio.playSound("hit_sfx") -- Som de pisar no inimigo
                            engine.particles.newEmitter(e2.x + e2.width/2, e2.y + e2.height/2, {
                                color = {1, 0, 0, 1}, startSize = 15, endSize = 5, lifeTime = 0.4, speed = 100, burst = 20, duration = 0.01
                            })
                        else
                            -- Lógica para quando o jogador é atingido pelo inimigo
                            -- Por enquanto, apenas um print e som, pode levar a game over
                            print("Jogador foi atingido!")
                            engine.audio.playSound("hit_sfx") -- Som de ser atingido
                            engine.camera.shake(5, 0.2)
                            -- Aqui você poderia adicionar lógica de vida do jogador ou mudar para Game Over
                            -- engine.stateManager.changeState("GameOver")
                        end
                    end
                end
            end
        end
    end
end

-- ===================== DRAW PRINCIPAL =====================
function engine.draw()
    love.graphics.push()
    love.graphics.translate(-engine.camera.x, -engine.camera.y)

    -- Desenha o fundo
    if engine.assets.background then
        love.graphics.draw(engine.assets.background.image, 0, 0)
    end

    -- Desenha todas as entidades do mundo
    for _, e in ipairs(engine.entities) do
        if e.sprite and engine.assets[e.sprite] and engine.assets[e.sprite].image then
            local asset = engine.assets[e.sprite]
            local img = asset.image
            local scaleX = e.direction
            local offsetX = (scaleX == -1) and e.width or 0
            love.graphics.draw(img, e.x + offsetX, e.y, 0, scaleX, 1)
        elseif e.type == "platform_block" then
            love.graphics.setColor(0.5, 0.3, 0.1, 1)
            love.graphics.rectangle("fill", e.x, e.y, e.width, e.height)
            love.graphics.setColor(1, 1, 1, 1)
        else
            love.graphics.setColor(1, 0, 0, 0.5) -- Entidades sem sprite específico
            love.graphics.rectangle("fill", e.x, e.y, e.width, e.height)
            love.graphics.setColor(1, 1, 1, 1)
        end

        -- Desenho de debug (retângulo de colisão) se ativado
        if engine.config.debugDraw then
            love.graphics.setColor(1, 0, 0, 0.7)
            love.graphics.rectangle("line", e.x, e.y, e.width, e.height)
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

    -- Desenha as partículas
    for _, emitter in ipairs(engine.particles.emitters) do
        emitter:draw()
    end

    love.graphics.pop() -- Restaura as transformações para desenhar o HUD na tela fixa

    -- Desenhos de HUD (Heads-Up Display) vão aqui
    -- love.graphics.print("Pontos: 0", 10, 10)
end

-- ===================== LOVE CALLBACKS (PRINCIPAIS) =====================
function love.load()
    love.window.setMode(engine.config.windowWidth, engine.config.windowHeight)
    love.window.setTitle("Mini Engine 2D")

    -- Carregamento de Assets (imagens e áudio)
    engine.loadAsset("background", "assets/imagens/fundo_cidade.png")
    engine.loadAsset("player_sprite", "assets/imagens/car.png")
    engine.loadAsset("enemy_sprite", "assets/imagens/enemy.png")
    engine.loadAsset("platform_tile", "assets/imagens/platform_tile.png", 32, 32)
    engine.loadAsset("spark_particle", "assets/imagens/spark.png")
    engine.loadAsset("smoke_particle", "assets/imagens/smoke.png")
    engine.loadAsset("gem_sprite", "assets/imagens/gem.png")

    engine.audio.loadSound("menu_music", "assets/audio/menu_loop.ogg", true, true)
    engine.audio.loadSound("game_music", "assets/audio/game_loop.ogg", true, true)
    engine.audio.loadSound("jump_sfx", "assets/audio/jump.wav", false, false)
    engine.audio.loadSound("hit_sfx", "assets/audio/hit.wav", false, false)
    engine.audio.loadSound("collect_sfx", "assets/audio/collect.wav", false, false)

    -- =========================================================
    -- DEFINIÇÃO DE PREFABS (Global para todos os estados)
    -- =========================================================
    engine.definePrefab("CollectibleGem", {
        type = "collectible",
        sprite = "gem_sprite",
        width = 16,
        height = 16,
        isSolid = false,
        isAffectedByGravity = false,
        value = 10
    })

    -- =========================================================
    -- DEFINIÇÃO DOS ESTADOS DO JOGO
    -- =========================================================

    -- Estado do Menu Principal
    engine.stateManager.addState("Menu", {
        load = function()
            print("Entrando no estado: Menu")
            engine.audio.playMusic("menu_music")
        end,
        update = function(dt)
            -- Lógica do menu
        end,
        draw = function()
            love.graphics.setColor(0.2, 0.2, 0.8, 1)
            love.graphics.rectangle("fill", 0, 0, engine.config.windowWidth, engine.config.windowHeight)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(30))
            love.graphics.printf("MINI JOGO", 0, 200, engine.config.windowWidth, "center")
            love.graphics.printf("Pressione ESPAÇO para Iniciar", 0, 300, engine.config.windowWidth, "center")
        end,
        keypressed = function(key)
            if key == "space" then
                engine.stateManager.changeState("GamePlay")
            end
        end
    })

    -- Estado de Jogo Principal (GamePlay)
    engine.stateManager.addState("GamePlay", {
        load = function()
            print("Entrando no estado: GamePlay")
            -- O stateManager.changeState já limpa a engine.
            -- A criação do mundo e entidades deve acontecer AQUI para cada vez que o jogo inicia.
            engine.createPlayer(50, 100, 200, "player_sprite")
            engine.createPlatform(0, 500, 30, "platform_tile")
            engine.createPlatform(400, 400, 5, "platform_tile")
            engine.createPlatform(800, 300, 10, "platform_tile")
            engine.createPlatform(1200, 200, 7, "platform_tile")
            engine.createStaticEnemy(600, 468, "enemy_sprite")
            engine.createPatrollingEnemy(320, 368, 80, 320, 450, "enemy_sprite")
            engine.createPatrollingEnemy(900, 268, 100, 850, 1050, "enemy_sprite")
            engine.createPrefab("CollectibleGem", {x = 350, y = 350})
            engine.createPrefab("CollectibleGem", {x = 850, y = 250})

            engine.camera.setLimits(0, 2000, 0, engine.config.windowHeight)
            engine.camera.follow(engine.player)
            engine.particles.newEmitter(100, 480, {
                color = {0.5, 0.5, 0.5, 1},
                startSize = 10, endSize = 30, lifeTime = 2, speed = 10, spread = 90,
                minAngle = math.pi * 0.75, maxAngle = math.pi * 1.25, emissionRate = 5, gravityFactor = -0.1
            })
            engine.audio.playMusic("game_music")
        end,
        update = function(dt)
            engine.update(dt) -- Chama a atualização da engine principal

            -- Lógica para coletar gemas (específico do GamePlay)
            if engine.player then -- Verifica se o player existe na cena
                for i = #engine.entities, 1, -1 do
                    local e = engine.entities[i]
                    if e.type == "collectible" then
                        local collided, _ = engine.checkCollision(engine.player, e)
                        if collided then
                            print("Gema coletada!")
                            engine.audio.playSound("collect_sfx")
                            engine.removeEntity(e.id)
                        end
                    end
                end
            end
        end,
        draw = function()
            engine.draw() -- Chama o desenho da engine principal
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.print("Pressione ESC para o Menu", 10, 10)
        end,
        keypressed = function(key)
            if engine.player and engine.player.canJump and key == "space" and engine.player.onGround then
                engine.player.dy = -400
                engine.player.onGround = false
                engine.audio.playSound("jump_sfx")
                engine.particles.newEmitter(engine.player.x + engine.player.width / 2, engine.player.y + engine.player.height, {
                    color = {0.8, 0.8, 0.8, 1}, startSize = 5, endSize = 15, lifeTime = 0.3, speed = 30, spread = 180,
                    minAngle = 0, maxAngle = math.pi, burst = 10, duration = 0.01, gravityFactor = 0.5
                })
            elseif key == "escape" then
                engine.stateManager.changeState("Menu")
            end
        end
    })

    -- Estado de Game Over
    engine.stateManager.addState("GameOver", {
        load = function()
            print("Entrando no estado: Game Over")
            engine.audio.stopMusic()
        end,
        update = function(dt)
            -- Lógica de Game Over
        end,
        draw = function()
            love.graphics.setColor(0.8, 0.2, 0.2, 1)
            love.graphics.rectangle("fill", 0, 0, engine.config.windowWidth, engine.config.windowHeight)
            love.graphics.setColor(1, 1, 1, 1)
            love.graphics.setFont(love.graphics.newFont(40))
            love.graphics.printf("GAME OVER", 0, 250, engine.config.windowWidth, "center")
            love.graphics.setFont(love.graphics.newFont(20))
            love.graphics.printf("Pressione R para Reiniciar", 0, 350, engine.config.windowWidth, "center")
        end,
        keypressed = function(key)
            if key == "r" then
                engine.stateManager.changeState("GamePlay")
            end
        end
    })

    -- Inicia o jogo no estado do Menu
    engine.stateManager.changeState("Menu")
end

-- ===================== CALLBACKS DO LÖVE2D (Chamadas pelo sistema) =====================
function love.update(dt)
    if engine.stateManager.currentState and engine.stateManager.currentState.update then
        engine.stateManager.currentState.update(dt)
    end
    love.audio.setVolume(engine.config.masterVolume) -- Garante que o volume global do Love2D esteja sempre de acordo
end

function love.draw()
    if engine.stateManager.currentState and engine.stateManager.currentState.draw then
        engine.stateManager.currentState.draw()
    end
end

function love.keypressed(key)
    if engine.stateManager.currentState and engine.stateManager.currentState.keypressed then
        engine.stateManager.currentState.keypressed(key)
    end
end

function love.mousepressed(x, y, button)
    if engine.stateManager.currentState and engine.stateManager.currentState.mousepressed then
        engine.stateManager.currentState.mousepressed(x, y, button)
    end
end

return engine
