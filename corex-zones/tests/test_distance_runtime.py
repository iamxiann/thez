"""Run polygon distance regressions against the installed PolyZone Lua source.

Requires lupa. Set POLYZONE_CLIENT to PolyZone/client.lua when it is not in a
standard sibling resource directory or this workspace's qbx installation.
"""

import math
import os
import re
import unittest
from pathlib import Path

from lupa import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]
CANDIDATES = [
    Path(os.environ["POLYZONE_CLIENT"]) if os.environ.get("POLYZONE_CLIENT") else None,
    ROOT.parent / "PolyZone" / "client.lua",
    ROOT.parent.parent / "[standalone]" / "PolyZone" / "client.lua",
    ROOT.parents[2] / "qbx" / "resources" / "[standalone]" / "PolyZone" / "client.lua",
]
POLYZONE = next((path for path in CANDIDATES if path and path.is_file()), None)


@unittest.skipUnless(POLYZONE, "Set POLYZONE_CLIENT to the installed PolyZone/client.lua")
class DistanceRuntimeTests(unittest.TestCase):
    def setUp(self):
        self.lua = LuaRuntime(unpack_returned_tuples=True)
        # Only Cfx vector arithmetic and resource boot hooks are stubbed;
        # polygon construction, lazy grids and membership use real PolyZone.
        self.lua.execute("""
            local vectorMeta = {}
            function vector2(x, y)
                return setmetatable({ x = x, y = y }, vectorMeta)
            end
            function vector3(x, y, z) return { x = x, y = y, z = z } end
            vectorMeta.__add = function(a, b) return vector2(a.x + b.x, a.y + b.y) end
            vectorMeta.__sub = function(a, b) return vector2(a.x - b.x, a.y - b.y) end
            vectorMeta.__div = function(a, b) return vector2(a.x / b, a.y / b) end
            function CreateThread() end
            function AddEventHandler() end
            function print() end
            Citizen = { CreateThread = CreateThread }
            exports = { ['corex-core'] = { GetCoreObject = function()
                return { Functions = {} }
            end } }
        """)
        self.lua.execute(POLYZONE.read_text(encoding="utf-8-sig"))

    def load(self, zones):
        self.lua.globals().Config = self.lua.table_from({
            "SafeZones": self.lua.table_from(zones) if zones is not None else None,
        })
        self.lua.execute((ROOT / "shared" / "zones.lua").read_text(encoding="utf-8"))
        client = (ROOT / "client" / "main.lua").read_text(encoding="utf-8")
        # Cfx hash literals are unrelated to polygon distance and cannot be
        # parsed by stock Lua. No gameplay threads execute in this harness.
        client = re.sub(r"`[^`]+`", "0", client)
        self.lua.execute(client)

    def polygon(self, points=None, min_z=0, max_z=10):
        points = points or [(0, 0), (10, 0), (10, 10), (0, 10)]
        return self.lua.table_from({
            "name": "test",
            "points": self.lua.table_from([
                self.lua.globals().vector2(x, y) for x, y in points
            ]),
            "minZ": min_z,
            "maxZ": max_z,
        })

    def distance(self, x, y, z):
        return self.lua.globals().GetSafeZoneDistance(
            self.lua.globals().vector3(x, y, z)
        )

    def test_inside_volume_is_zero(self):
        self.load([self.polygon()])
        self.assertEqual(self.distance(5, 5, 5), 0)
        self.assertEqual(self.distance(1, 9, 0), 0)
        self.assertEqual(self.distance(9, 1, 10), 0)

    def test_all_edges_and_corners_are_zero(self):
        self.load([self.polygon()])
        for x, y in [(0, 0), (0, 10), (10, 0), (10, 10),
                     (0, 5), (10, 5), (5, 0), (5, 10)]:
            with self.subTest(x=x, y=y):
                self.assertEqual(self.distance(x, y, 5), 0)

    def test_outside_edge_and_corner_use_nearest_segment(self):
        self.load([self.polygon()])
        self.assertEqual(self.distance(13, 5, 5), 3)
        self.assertEqual(self.distance(-3, 14, 5), 5)
        self.assertEqual(self.distance(5, -30, 5), 30)

    def test_elevation_inside_and_outside_footprint(self):
        self.load([self.polygon()])
        self.assertEqual(self.distance(5, 5, 14), 4)
        self.assertEqual(self.distance(5, 5, -4), 4)
        self.assertEqual(self.distance(13, 5, 14), 5)
        self.assertEqual(self.distance(5, 10, 14), 4)

    def test_concave_notch_is_outside(self):
        # L shape: (7, 7) is in the bounding box but outside the polygon.
        self.load([self.polygon([(0, 0), (10, 0), (10, 3),
                                (3, 3), (3, 10), (0, 10)])])
        self.assertEqual(self.distance(7, 7, 5), 4)
        self.assertEqual(self.distance(1, 7, 5), 0)
        self.assertEqual(self.distance(7, 7, 13), 5)

    def test_slanted_edge_and_clockwise_vertices(self):
        self.load([self.polygon([(0, 0), (0, 10), (10, 0)])])
        self.assertEqual(self.distance(5, 5, 5), 0)
        self.assertAlmostEqual(self.distance(8, 8, 5), math.sqrt(18))
        self.assertEqual(self.distance(2, 2, 5), 0)

    def test_repeated_corner_has_no_division_by_zero(self):
        self.load([self.polygon([(0, 0), (10, 0), (10, 0), (10, 10), (0, 10), (0, 0)])])
        self.assertEqual(self.distance(-3, -4, 5), 5)

    def test_optional_height_bounds(self):
        self.load([self.polygon(min_z=None, max_z=None)])
        self.assertEqual(self.distance(5, 5, 100000), 0)
        self.assertEqual(self.distance(13, 5, -100000), 3)
        self.load([self.polygon(min_z=0, max_z=None)])
        self.assertEqual(self.distance(5, 5, 100000), 0)
        self.assertEqual(self.distance(5, 5, -4), 4)
        self.load([self.polygon(min_z=None, max_z=10)])
        self.assertEqual(self.distance(5, 5, -100000), 0)
        self.assertEqual(self.distance(5, 5, 14), 4)

    def test_nearest_zone_after_invalid_config_entry(self):
        self.load([
            self.polygon([(0, 0), (1, 1)]),
            self.polygon(),
            self.polygon([(20, 0), (30, 0), (30, 10), (20, 10)]),
        ])
        self.assertEqual(self.distance(17, 5, 5), 3)
        self.assertEqual(self.distance(25, 5, 5), 0)

    def test_invalid_coords_and_absent_zones_return_infinity(self):
        self.load([self.polygon()])
        for coords in [None, False, 1, "bad", self.lua.table(),
                       self.lua.table_from({"x": 1, "y": 2}),
                       self.lua.table_from({"x": "1", "y": 2, "z": 3})]:
            self.assertEqual(self.lua.globals().GetSafeZoneDistance(coords), math.inf)
        self.assertEqual(self.distance(math.nan, 5, 5), math.inf)
        self.assertEqual(self.distance(5, math.inf, 5), math.inf)
        self.assertEqual(self.distance(5, 5, -math.inf), math.inf)
        for zones in [None, [], [self.polygon([(0, 0), (1, 1)])],
                      [self.polygon([(0, 0), (1, 1), (2, 2)])],
                      [self.polygon(min_z=10, max_z=0)]]:
            self.load(zones)
            self.assertEqual(self.distance(5, 5, 5), math.inf)

    def test_configured_polygon_uses_actual_bounds(self):
        self.lua.execute((ROOT / "config.lua").read_text(encoding="utf-8"))
        zones = self.lua.globals().Config.SafeZones
        self.load([zones[index] for index in range(1, len(zones) + 1)])
        self.assertEqual(self.distance(-1202, 71.4, 55), 0)
        self.assertEqual(self.distance(-1022, 71.4, 55), 30)
        self.assertEqual(self.distance(-1202, 71.4, 89), 4)


if __name__ == "__main__":
    unittest.main(verbosity=2)
