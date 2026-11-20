-- ═══════════════════════════════════════════════════════════════════════════
--  Omniblock_maths.lua  (NO ofuscar: se sube tal cual a GitHub)
--  Mecanismo matematico de repulsion con el plano matriz.
--
--  El espacio alrededor del jugador se discretiza en una matriz N x N de celdas
--  centrada en el jugador. Cada celda recibe un RIESGO (suma de amenazas, cae con
--  1/d^2 + nucleo de contacto) y un estado (libre / obstaculo bajo / pared / vacio).
--  Dijkstra recorre la matriz acumulando EXPOSICION (riesgo x tiempo) y se elige la
--  celda meta con menor exposicion total + territorio futuro.
--
--  Lua puro (sin API de Roblox): el entorno (rayos) entra por `env`.
--
--  Uso desde Omniblock.lua:
--      local Maths = loadstring(game:HttpGet(URL))()(OCFG)
--      local plan  = Maths.GridPlan(env, px, pz, dangers, hint, forceMove)
--  OCFG se pasa por referencia: los GRID_* que cambies en el principal se leen en vivo.
-- ═══════════════════════════════════════════════════════════════════════════

return function(OCFG)
    -- dangers[i] = { x, z, speed, weight, radius, lead }   (plano XZ)
    --   speed = velocidad con la que la amenaza PUEDE moverse hacia cualquier celda
    -- Modelo de alcanzabilidad: en el tiempo t la amenaza puede haber recorrido speed*t hacia
    -- la celda evaluada (sin sobrepasarla). Asi un perseguidor nunca "atraviesa" tu posicion en
    -- la prediccion, y quedarte quieto se vuelve mas caro cuanto mas tiempo pasa.
    local function omniRiskAt(dangers, x, z, t)
        local d0, coreW = OCFG.GRID_RISK_D0, OCFG.GRID_CORE_WEIGHT
        local r = 0
        for i = 1, #dangers do
            local d  = dangers[i]
            local tt = (t < d.lead) and t or d.lead
            local dx = x - d.x
            local dz = z - d.z
            local dist = math.sqrt(dx * dx + dz * dz) - d.speed * tt
            if dist < 0 then dist = 0 end
            local far = d0 / (d0 + dist)
            local v = far * far
            if dist < d.radius then
                local k = 1 - dist / d.radius
                v = v + coreW * k * k
            end
            r = r + d.weight * v
        end
        return r
    end

    local OMNI_GRID_OFFS = {
        { 1, 0 }, { -1, 0 }, { 0, 1 }, { 0, -1 },
        { 1, 1 }, { 1, -1 }, { -1, 1 }, { -1, -1 },
    }

    -- env.edge(x0, z0, x1, z1) -> 0 libre | 1 obstaculo bajo (saltable) | 2 pared
    -- env.ground(x, z)         -> true si hay suelo (opcional)
    -- hint = { x, z } meta del plan anterior (anti-temblor, opcional)
    -- forceMove = true: hay una amenaza acercandose; nunca te quedes quieto (elige la mejor celda != actual)
    -- Devuelve nil si no hay nada que hacer; si no, una tabla con la ruta elegida.
    local function omniGridPlan(env, px, pz, dangers, hint, forceMove)
        local C     = OCFG
        local N     = C.GRID_N
        local cell  = C.GRID_CELL
        local half  = math.floor((N - 1) / 2)
        local speed = C.GRID_SPEED

        local function id(i, j) return (j + half) * N + (i + half) + 1 end

        local cost, plen, parent, jumpIn, closed, ci, cj = {}, {}, {}, {}, {}, {}, {}
        local orth, ground = {}, {}

        -- Arista ortogonal entre (i,j) y (i+di,j+dj); se cachea por arista
        local function orthKind(i, j, di, dj)
            local a, b = i, j
            if di < 0 or dj < 0 then a, b = i + di, j + dj end
            local key = id(a, b) * 2 + ((di ~= 0) and 0 or 1)
            local k = orth[key]
            if k == nil then
                k = env.edge(px + a * cell, pz + b * cell,
                             px + (a + math.abs(di)) * cell, pz + (b + math.abs(dj)) * cell)
                orth[key] = k
            end
            return k
        end

        -- Diagonal permitida solo si las 4 aristas que la rodean lo permiten (no corta esquinas)
        local function edgeKind(i, j, di, dj)
            if di == 0 or dj == 0 then return orthKind(i, j, di, dj) end
            return math.max(
                orthKind(i, j, di, 0), orthKind(i, j, 0, dj),
                orthKind(i + di, j, 0, dj), orthKind(i, j + dj, di, 0))
        end

        local function standable(i, j)
            local key = id(i, j)
            local g = ground[key]
            if g == nil then
                g = (env.ground == nil) or env.ground(px + i * cell, pz + j * cell)
                ground[key] = g
            end
            return g
        end

        -- ── Dijkstra sobre la matriz: costo = exposicion (riesgo x tiempo de transito) ──
        local startId = id(0, 0)
        cost[startId], plen[startId] = 0, 0
        ci[startId], cj[startId] = 0, 0
        local open = { startId }
        local timeCost = C.GRID_TIME_COST
        local jumpCost = C.GRID_JUMP_COST

        while #open > 0 do
            local bi, bc = 1, cost[open[1]]
            for k = 2, #open do
                local c = cost[open[k]]
                if c < bc then bi, bc = k, c end
            end
            local cur = open[bi]
            open[bi] = open[#open]; open[#open] = nil

            if not closed[cur] then
                closed[cur] = true
                if cost[cur] <= C.GRID_COST_CAP then
                    local i, j = ci[cur], cj[cur]
                    for _, o in ipairs(OMNI_GRID_OFFS) do
                        local di, dj = o[1], o[2]
                        local ni, nj = i + di, j + dj
                        if ni >= -half and ni <= half and nj >= -half and nj <= half then
                            local nid = id(ni, nj)
                            if not closed[nid] then
                                local kind = edgeKind(i, j, di, dj)
                                if kind < 2 and standable(ni, nj) then
                                    local stepLen = cell * ((di ~= 0 and dj ~= 0) and 1.41421356 or 1)
                                    local nl = plen[cur] + stepLen
                                    local dt = stepLen / speed
                                    local rk = omniRiskAt(dangers, px + ni * cell, pz + nj * cell, nl / speed)
                                    local nc = cost[cur] + rk * dt + timeCost * dt
                                    if kind == 1 then nc = nc + jumpCost end
                                    if cost[nid] == nil or nc < cost[nid] then
                                        cost[nid], plen[nid], parent[nid] = nc, nl, cur
                                        jumpIn[nid] = (kind == 1)
                                        ci[nid], cj[nid] = ni, nj
                                        open[#open + 1] = nid
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Apertura: que tan despejado esta el entorno 5x5 de una celda (fuera de la matriz = abierto)
        local function openness(i, j)
            local free, total = 0, 0
            for a = -2, 2 do
                for b = -2, 2 do
                    local ai, bj = i + a, j + b
                    total = total + 1
                    if ai < -half or ai > half or bj < -half or bj > half then
                        free = free + 1
                    elseif closed[id(ai, bj)] then
                        free = free + 1
                    end
                end
            end
            return free / total
        end

        -- ── Eleccion de meta: menor exposicion total + territorio futuro ──
        local tRef, goalT = C.GRID_STAY_TIME, C.GRID_GOAL_TIME
        local hystR = C.GRID_HYST_RADIUS * cell
        local cand = {}
        for nid in pairs(closed) do
            local i, j = ci[nid], cj[nid]
            local x, z = px + i * cell, pz + j * cell
            local tg = math.max(plen[nid] / speed, goalT)
            local rg = omniRiskAt(dangers, x, z, tg)
            local s = -(cost[nid] + tRef * rg) + C.GRID_OPEN_WEIGHT * openness(i, j)
            if nid ~= startId and hint then
                local dd = math.sqrt((x - hint.x) ^ 2 + (z - hint.z) ^ 2)
                if dd < hystR then s = s + C.GRID_HYST_WEIGHT * (1 - dd / hystR) end
            end
            cand[#cand + 1] = { id = nid, s = s, risk = rg, x = x, z = z }
        end
        table.sort(cand, function(a, b) return a.s > b.s end)

        -- Territorio: celdas libres a las que llegas ANTES que cualquier amenaza si te paras
        -- en la meta. Una esquina o un callejon tienen poco; un hueco hacia espacio abierto, mucho.
        local free = {}
        for nid in pairs(closed) do free[#free + 1] = { px + ci[nid] * cell, pz + cj[nid] * cell } end
        local function territory(c)
            local t0, n = plen[c.id] / speed, 0
            for _, f in ipairs(free) do
                local tp = t0 + math.sqrt((f[1] - c.x) ^ 2 + (f[2] - c.z) ^ 2) / speed
                local tt = math.huge
                for k = 1, #dangers do
                    local d = dangers[k]
                    local td = math.sqrt((f[1] - d.x) ^ 2 + (f[2] - d.z) ^ 2) / math.max(d.speed, 1e-3)
                    if td < tt then tt = td end
                end
                if tp < tt then n = n + 1 end
            end
            return n / (N * N)
        end

        local bestId, bestScore, bestRisk = startId, -math.huge, 0
        local stayScore, stayRisk = 0, 0
        local checked, startDone = 0, false
        for _, c in ipairs(cand) do
            local isStart = (c.id == startId)
            if checked < C.GRID_TERR_TOPK or (isStart and not startDone) then
                local s = c.s + C.GRID_TERR_WEIGHT * territory(c)
                c.s = s
                checked = checked + 1
                if isStart then startDone = true; stayScore, stayRisk = s, c.risk end
                if (not isStart or not forceMove) and s > bestScore then bestId, bestScore, bestRisk = c.id, s, c.risk end
            end
        end
        if not startDone then -- la celda actual no entro al top: evaluarla igual (referencia de "quedarse")
            for _, c in ipairs(cand) do
                if c.id == startId then
                    stayScore = c.s + C.GRID_TERR_WEIGHT * territory(c); stayRisk = c.risk
                    break
                end
            end
        end

        -- Quedarse tiene que ganar por un margen para no quedarse quieto por ruido
        if bestId == startId or (not forceMove and bestScore < stayScore + C.GRID_MOVE_MARGIN) then
            return { stay = true, stayRisk = stayRisk, cornered = false }
        end

        -- ── Reconstruir la ruta y promediar los primeros waypoints (movimiento suave) ──
        local wps, jump = {}, false
        local n = bestId
        while n and n ~= startId do
            table.insert(wps, 1, n)
            n = parent[n]
        end
        local sx, sz, used = 0, 0, 0
        for k = 1, math.min(C.GRID_LOOKAHEAD, #wps) do
            local w = wps[k]
            local ux, uz = ci[w] * cell, cj[w] * cell
            local m = math.sqrt(ux * ux + uz * uz)
            if m > 0.01 then sx, sz, used = sx + ux / m, sz + uz / m, used + 1 end
            if k <= 2 and jumpIn[w] then jump = true end
        end
        if used == 0 then return { stay = true, stayRisk = stayRisk, cornered = false } end
        local m = math.sqrt(sx * sx + sz * sz)
        if m < 0.01 then return { stay = true, stayRisk = stayRisk, cornered = false } end

        local cornered = stayRisk > C.GRID_CORNER_RISK
            and (cost[bestId] > C.GRID_BREAKOUT_COST or bestRisk > C.GRID_CORNER_RATIO * stayRisk)

        return {
            stay = false, dx = sx / m, dz = sz / m, jump = jump, cornered = cornered,
            goalX = px + ci[bestId] * cell, goalZ = pz + cj[bestId] * cell,
            stayRisk = stayRisk, goalRisk = bestRisk, transit = cost[bestId],
        }
    end

    return {
        RiskAt   = omniRiskAt,
        GridPlan = omniGridPlan,
    }
end
