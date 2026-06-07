-- ═══════════════════════════════════════════════════════════════════════════
-- MÓDULO: Fly (principal)
-- Este es el punto de entrada del sistema de vuelo. Requiere e inicializa los
-- submódulos FlyText, FlyAnim, FlyLogic y FlyControl, y expone su API pública.
-- Mantiene la misma interfaz que el monolítico original para compatibilidad.
-- ═══════════════════════════════════════════════════════════════════════════

print("version 1.80")   -- Versión del módulo, igual que en el original

-- ============================================================
-- CARGAR SUBMÓDULOS
-- ============================================================
-- Se asume que los módulos están en la misma carpeta que este archivo.
-- Ajusta las rutas si tu estructura de carpetas es diferente.
local FlyText   = require(script.Parent.FlyText)
local FlyAnim   = require(script.Parent.FlyAnim)
local FlyLogic  = require(script.Parent.FlyLogic)
local FlyControl = require(script.Parent.FlyControl)

-- ============================================================
-- INICIALIZACIÓN Y API PÚBLICA
-- ============================================================
-- FlyControl ya expone las funciones Start, Stop, Toggle, etc.
-- Simplemente lo devolvemos como interfaz del módulo principal.

-- Aseguramos que FlyText esté sincronizado con el hub al inicio.
FlyText.Reload()

-- Exponer la misma API que el monolítico original.
-- Todas las funciones son proporcionadas por FlyControl.
return FlyControl
