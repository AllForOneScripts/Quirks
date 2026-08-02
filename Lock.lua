*** Apply the following changes to Lock.lua ***

@@ local L = {
     lockKey        = Enum.KeyCode.X,
+    systemEnabled  = false, -- M.Start/M.Stop lifecycle; distinct from a selected target
     lockActive     = false,
     lockedTarget   = nil,
+    avatarRequestId = 0,    -- invalidates thumbnail tasks that finish after Stop/clear
@@
 local function applyLockIcon(player)
+    if not L.systemEnabled or not L.lockActive or player ~= L.lockedTarget then return end
     removeLockIcon()
@@
 local function updateLockHighlight()
-    if not L.lockActive or not L.lockedTarget then
+    if not L.systemEnabled or not L.lockActive or not L.lockedTarget then
         if L.lockHighlight then L.lockHighlight.Parent = nil end
         return
@@
 local function loadAvatarImage()
-    if not L.lockInfoGui then return end
+    if not L.systemEnabled or not L.lockActive or not L.lockedTarget or not L.lockInfoGui then return end
     local playerImg = L.lockInfoGui:FindFirstChild("PlayerImage", true)
     if not playerImg then return end
-    if L.lockActive and L.lockedTarget then
-        local userId = L.lockedTarget.UserId
-        task.spawn(function()
-            local success, content = pcall(function()
-                return Players:GetUserThumbnailAsync(
-                    userId,
-                    Enum.ThumbnailType.AvatarBust,
-                    Enum.ThumbnailSize.Size420x420
-                )
-            end)
-            if success and content and playerImg and playerImg.Parent then
-                playerImg.Image = content
-            end
-        end)
-    end
+    local target = L.lockedTarget
+    local infoGui = L.lockInfoGui
+    local requestId = L.avatarRequestId
+    local userId = target.UserId
+    task.spawn(function()
+        local success, content = pcall(function()
+            return Players:GetUserThumbnailAsync(userId, Enum.ThumbnailType.AvatarBust, Enum.ThumbnailSize.Size420x420)
+        end)
+        -- No escribir una carga vieja ni después de apagar/cambiar Lock.
+        if success and content
+            and L.systemEnabled
+            and L.lockActive
+            and L.lockedTarget == target
+            and L.lockInfoGui == infoGui
+            and L.avatarRequestId == requestId
+            and playerImg.Parent then
+            playerImg.Image = content
+        end
+    end)
 end
@@
 local function createLockInfoGui(parentFrame)
+    if not L.systemEnabled or not L.lockActive or not L.lockedTarget then return end
     if L.lockInfoGui then
@@
 local function clearLock()
+    L.avatarRequestId += 1
     L.lockActive   = false
@@
 local function toggleLock()
+    if not L.systemEnabled then return end
     if not L.lockActive then
@@
 local function startLockSystem()
@@
     L.lockConn = UserInputService.InputBegan:Connect(function(input, gpe)
-        if gpe or isTyping() then return end
+        if not L.systemEnabled or gpe or isTyping() then return end
         if input.KeyCode == L.lockKey then toggleLock() end
     end)
@@
     L.lockRenderConn = RunService.RenderStepped:Connect(function()
+        if not L.systemEnabled then return end
         updateLockInfoGui()
@@
 local function stopLockSystem()
+    -- Primero se invalida el estado: incluso una coroutine ya iniciada queda bloqueada.
+    L.systemEnabled = false
+    L.avatarRequestId += 1
     if L.lockConn       then L.lockConn:Disconnect();       L.lockConn       = nil end
@@
 function M.Start(lplrRef, lockKeyCode)
@@
     if lockKeyCode then L.lockKey = lockKeyCode end
     _reloadFT()
+    L.systemEnabled = true
     startLockSystem()
 end
@@ function M.SetLockKey(keyCode)
     if L.lockLabels then
         L.lockLabels.label.Text = FT.lock_label .. "  [" .. keyCode.Name .. "]"
         L.lockLabels.hint.Text  = FT.lock_hint_prefix .. keyCode.Name
     end
+    -- No recrear un listener si el módulo está detenido.
+    if not L.systemEnabled then return end
     if L.lockConn then L.lockConn:Disconnect(); L.lockConn = nil end
     L.lockConn = UserInputService.InputBegan:Connect(function(input, gpe)
-        if gpe or isTyping() then return end
+        if not L.systemEnabled or gpe or isTyping() then return end
         if input.KeyCode == L.lockKey then toggleLock() end
     end)
 end
@@
-M.CreateInfoGui      = createLockInfoGui
+M.CreateInfoGui = function(parentFrame)
+    -- La API pública ya no permite generar el panel con Lock apagado.
+    if L.systemEnabled and L.lockActive and L.lockedTarget then
+        createLockInfoGui(parentFrame)
+    end
+end
