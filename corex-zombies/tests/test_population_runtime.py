import unittest
from pathlib import Path

from lupa import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]


class PopulationRuntimeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lua = LuaRuntime(unpack_returned_tuples=True)
        cls.population = cls.lua.execute(
            (ROOT / "client" / "population.lua").read_text(encoding="utf-8")
        )

    def config(self):
        return self.lua.table_from({
            "LocalClientZombies": True,
            "Spawning": self.lua.table_from({"enabled": True}),
            "Sync": self.lua.table_from({"DisableAmbientLocalSpawner": False}),
            "Performance": self.lua.table_from({
                "nearDistance": 35,
                "midDistance": 80,
                "aiNearInterval": 200,
                "aiMidInterval": 500,
                "aiFarInterval": 1000,
                "runnerMaxDistance": 55,
            }),
        })

    def test_ambient_spawner_honors_all_gates(self):
        cfg = self.config()
        self.assertTrue(self.population.AmbientEnabled(cfg))
        cfg.LocalClientZombies = False
        self.assertFalse(self.population.AmbientEnabled(cfg))
        cfg.LocalClientZombies = True
        cfg.Sync.DisableAmbientLocalSpawner = True
        self.assertFalse(self.population.AmbientEnabled(cfg))

    def test_only_explicit_shared_spawns_are_networked(self):
        self.assertFalse(self.population.ShouldNetwork(self.lua.table()))
        self.assertTrue(self.population.ShouldNetwork(self.lua.table_from({"forceNetworked": True})))
        self.assertTrue(self.population.ShouldNetwork(self.lua.table_from({"sharedId": "event-1"})))

    def test_ai_intervals_scale_by_distance(self):
        cfg = self.config().Performance
        self.assertEqual(self.population.AiInterval(20, cfg), 200)
        self.assertEqual(self.population.AiInterval(60, cfg), 500)
        self.assertEqual(self.population.AiInterval(120, cfg), 1000)

    def test_runner_force_is_near_only(self):
        cfg = self.config().Performance
        self.assertTrue(self.population.RunnerActive(54.9, cfg))
        self.assertFalse(self.population.RunnerActive(55.1, cfg))


if __name__ == "__main__":
    unittest.main(verbosity=2)
