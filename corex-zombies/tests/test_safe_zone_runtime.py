import unittest
from pathlib import Path

from lupa import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]


class SafeZoneRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        self.lua.execute("""
            Config = { SafeZoneBuffer = 30.0 }
            zoneDistance = 0.0
            zoneState = 'started'
            zoneCalls = 0
            failDistanceExport = false
            function GetResourceState() return zoneState end
            function AddRelationshipGroup() return true, 1 end
            function GetHashKey(name) return name end
            function SetRelationshipBetweenGroups() end
            function CreateThread() end
            function AddEventHandler() end
            function RegisterNetEvent() end
            function print() end
            exports = setmetatable({
                ['corex-core'] = {
                    GetCoreObject = function() return { Functions = {} } end
                },
                ['corex-zones'] = {
                    GetSafeZones = function()
                        return {{ points = {
                            { x = 0, y = 0 }, { x = 100, y = 0 },
                            { x = 100, y = 100 }, { x = 0, y = 100 }
                        }, minZ = 0, maxZ = 50 }}
                    end,
                    GetSafeZoneDistance = function(_, coords)
                        zoneCalls = zoneCalls + 1
                        assert(coords.x == 50 and coords.y == 50 and coords.z == 25)
                        if failDistanceExport then error('export unavailable') end
                        return zoneDistance
                    end
                }
            }, { __call = function() end })
        """)
        self.lua.execute((ROOT / "client" / "main.lua").read_text(encoding="utf-8"))
        self.coords = self.lua.table_from({"x": 50, "y": 50, "z": 25})

    def test_polygon_zone_does_not_require_circle_coordinates(self):
        self.assertTrue(self.lua.globals().IsNearSafeZone(self.coords))

    def test_spawn_and_cleanup_buffer_includes_boundary(self):
        for distance, expected in ((0, True), (29.9, True), (30, True), (30.1, False)):
            with self.subTest(distance=distance):
                self.lua.globals().zoneDistance = distance
                self.assertEqual(self.lua.globals().IsNearSafeZone(self.coords), expected)

    def test_configured_buffer_is_respected(self):
        self.lua.globals().Config.SafeZoneBuffer = 10
        self.lua.globals().zoneDistance = 11
        self.assertFalse(self.lua.globals().IsNearSafeZone(self.coords))

    def test_stopped_provider_is_skipped_and_recovers_after_restart(self):
        self.lua.globals().zoneState = "stopped"
        self.assertFalse(self.lua.globals().IsNearSafeZone(self.coords))
        self.assertEqual(self.lua.globals().zoneCalls, 0)
        self.lua.globals().zoneState = "started"
        self.assertTrue(self.lua.globals().IsNearSafeZone(self.coords))

    def test_missing_coords_do_not_call_provider(self):
        self.assertFalse(self.lua.globals().IsNearSafeZone(None))
        self.assertEqual(self.lua.globals().zoneCalls, 0)

    def test_unavailable_or_invalid_distance_does_not_stop_caller(self):
        self.lua.globals().failDistanceExport = True
        self.assertFalse(self.lua.globals().IsNearSafeZone(self.coords))
        self.lua.globals().failDistanceExport = False
        for distance in (None, "invalid", float("inf"), float("nan"), -1):
            with self.subTest(distance=distance):
                self.lua.globals().zoneDistance = distance
                self.assertFalse(self.lua.globals().IsNearSafeZone(self.coords))


if __name__ == "__main__":
    unittest.main(verbosity=2)
