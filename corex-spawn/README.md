# corex-spawn

> Spawn flow with character creation and appearance persistence provided by illenium-appearance.

Part of the [COREX Framework](https://github.com/ABUGIZA/COREX-Framework).

## Install

Drop the `corex-spawn` folder into:
```
server-file/resources/[corex]/corex-spawn/
```

Make sure it loads after `corex-core` and `illenium-appearance`:
```cfg
ensure corex-core
ensure illenium-appearance
ensure corex-spawn
```

## Appearance integration

- Character creation and full skin persistence use `illenium-appearance`.
- After server confirmation, spawn refreshes appearance player data and shop blips,
  restores metadata armour, and restores the current session's uniform when
  `illenium-appearance` enables `Config.PersistUniforms`.
- Job/gang metadata changes refresh appearance access data and shop blips.
- Restarting appearance while the player is active refreshes the integration without
  replacing the player's model. During loading, `corex-spawn` owns skin application.
- A failed character editor opening keeps the player hidden for the spawn retry.

Validation: run `illenium-appearance/tests/corex_spawn_lifecycle.lua` from the
workspace root using Lua 5.4. In-game, check new character creation, reconnect,
respawn while wearing a uniform, and restarting either resource.

## Update

Download the latest release ZIP from the **Releases** tab and replace the folder.

## Docs
📖 <https://corex-zombies.gitbook.io/corex-docs/resources/player/corex-spawn>

## Community
💬 <https://discord.gg/G95rtnb9sg>

## License
Released under the [MIT License](LICENSE).
