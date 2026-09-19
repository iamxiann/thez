# xian_chat

Standalone Qbox chat replacement with job messages, command suggestions, chat
history, automatic fading, `/clear`, and a mouse-driven local emoji picker.
The `/me` and `/do` commands render synchronized, distance-scaled NUI bubbles
above the character without adding an entry to the chat window.

## Installation

Stop the default FiveM `chat` resource and ensure `xian_chat` after `qbx_core`.
Existing scripts can continue using `chat:addMessage`, `chat:addSuggestion`, and
the standard chat server exports because this resource declares `provide 'chat'`.

Default icons are by https://nucleoapp.com/.

<img width="767" height="583" alt="Screenshot 2025-11-07 200027" src="https://github.com/user-attachments/assets/e5a81c0f-282a-4c6e-a1ca-e8f8ea16eacc" />
