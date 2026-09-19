import unittest
from pathlib import Path

from lupa import LuaRuntime


ROOT = Path(__file__).resolve().parents[1]


class GrabRuntimeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lua = LuaRuntime(unpack_returned_tuples=True)
        cls.grab = cls.lua.execute((ROOT / "client" / "grab.lua").read_text(encoding="utf-8"))

    def api(self, *, networked=True, control_after=2):
        state = {"now": 0, "requests": 0, "detached": False, "unfrozen": False}
        api = self.lua.table()
        api.IsNetworked = lambda entity: networked
        api.HasControl = lambda entity: state["requests"] >= control_after
        api.RequestControl = lambda entity: state.__setitem__("requests", state["requests"] + 1)
        api.Now = lambda: state["now"]
        api.Wait = lambda ms: state.__setitem__("now", state["now"] + max(ms, 1))
        api.Exists = lambda entity: entity not in (None, 0)
        api.IsDead = lambda entity: False
        api.Detach = lambda entity: state.__setitem__("detached", True)
        api.Freeze = lambda entity, value: state.__setitem__("unfrozen", value is False)
        api.ClearTasks = lambda entity: None
        api.StopScene = lambda scene: None
        return api, state

    def test_local_entity_needs_no_network_control(self):
        api, state = self.api(networked=False)
        self.assertTrue(self.grab.AcquireControl(10, 100, api))
        self.assertEqual(state["requests"], 0)

    def test_network_control_is_requested_until_obtained(self):
        api, state = self.api(networked=True, control_after=3)
        self.assertTrue(self.grab.AcquireControl(10, 100, api))
        self.assertEqual(state["requests"], 3)

    def test_network_control_timeout_fails_cleanly(self):
        api, _ = self.api(networked=True, control_after=999)
        self.assertFalse(self.grab.AcquireControl(10, 3, api))

    def test_cleanup_always_detaches_and_unfreezes_player(self):
        api, state = self.api()
        session = self.lua.table_from({"player": 20, "zombie": 10, "scene": 4})
        self.grab.Cleanup(session, api)
        self.assertTrue(state["detached"])
        self.assertTrue(state["unfrozen"])


if __name__ == "__main__":
    unittest.main(verbosity=2)
