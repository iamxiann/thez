'use strict';

const resource = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'xian_chat';
const log = document.querySelector('#chat-log');
const composer = document.querySelector('#composer');
const form = document.querySelector('#chat-form');
const input = document.querySelector('#chat-input');
const suggestionsEl = document.querySelector('#suggestions');
const emojiButton = document.querySelector('#emoji-button');
const emojiPicker = document.querySelector('#emoji-picker');

const state = {
    open: false,
    fadeDelay: 10000,
    maxMessages: 60,
    suggestions: new Map(),
    serverSuggestionNames: new Set(),
    templates: new Map(),
    history: [],
    historyIndex: 0,
    fadeTimer: null,
};

const emojis = [
    '😀', '😁', '😂', '🤣', '😊', '😍', '😘', '😎', '🤔', '😅',
    '😢', '😭', '😡', '🥳', '🤝', '👍', '👎', '👏', '🙏', '💪',
    '❤️', '💔', '🔥', '✨', '🎉', '🎁', '🚗', '🚓', '🚑', '🚒',
    '📢', '📱', '💰', '✅', '❌', '⚠️', '💯', '👀', '🎭', '🏁',
];

const defaultTemplates = {
    default: '<div class="message"><div class="message-title">{0}</div><div class="message-body">{1}</div></div>',
    defaultAlt: '<div class="message"><div class="message-body">{0}</div></div>',
    user: '<div class="message user-message"><div class="message-title">{0}</div><div class="message-body">{1}</div></div>',
};

Object.entries(defaultTemplates).forEach(([id, html]) => state.templates.set(id, html));

function post(endpoint, data = {}) {
    return fetch(`https://${resource}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).catch(() => undefined);
}

function escapeHtml(value) {
    return String(value ?? '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
}

const gtaColors = {
    0: '#ffffff', 1: '#f05252', 2: '#76c442', 3: '#f6c945', 4: '#4da3ff',
    5: '#52c7c7', 6: '#a66cff', 7: '#ffffff', 8: '#f47a38', 9: '#9b9b9b',
};

function colorize(value) {
    const escaped = escapeHtml(value);
    const parts = escaped.split(/(\^[0-9])/g);
    let result = '';
    let spanOpen = false;

    for (const part of parts) {
        const match = part.match(/^\^([0-9])$/);
        if (!match) {
            result += part;
            continue;
        }
        if (spanOpen) result += '</span>';
        result += `<span style="color:${gtaColors[match[1]]}">`;
        spanOpen = true;
    }
    return result + (spanOpen ? '</span>' : '');
}

function templateFor(message, args) {
    if (message.template) return message.template;
    if (message.templateId && state.templates.has(message.templateId)) return state.templates.get(message.templateId);
    return args.length > 1 ? state.templates.get('default') : state.templates.get('defaultAlt');
}

function renderMessage(message = {}) {
    const args = Array.isArray(message.args) ? message.args : [message.args ?? ''];
    let html = templateFor(message, args);
    html = html.replace(/\{(\d+)\}/g, (_, index) => colorize(args[Number(index)] ?? ''));

    const wrapper = document.createElement('article');
    wrapper.className = 'chat-entry';
    wrapper.innerHTML = html;

    const timestamp = document.createElement('time');
    timestamp.textContent = new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    wrapper.prepend(timestamp);
    log.append(wrapper);

    while (log.children.length > state.maxMessages) log.firstElementChild.remove();
    log.scrollTop = log.scrollHeight;
    revealLog();
}

function revealLog() {
    log.classList.add('visible');
    clearTimeout(state.fadeTimer);
    if (!state.open) state.fadeTimer = setTimeout(() => log.classList.remove('visible'), state.fadeDelay);
}

function openChat() {
    state.open = true;
    composer.classList.remove('hidden');
    revealLog();
    requestAnimationFrame(() => input.focus());
    updateSuggestions();
}

function closeChat() {
    state.open = false;
    composer.classList.add('hidden');
    emojiPicker.classList.add('hidden');
    input.value = '';
    updateSuggestions();
    clearTimeout(state.fadeTimer);
    state.fadeTimer = setTimeout(() => log.classList.remove('visible'), state.fadeDelay);
}

function submitMessage() {
    const message = input.value.trim();
    if (message) {
        state.history = state.history.filter((item) => item !== message);
        state.history.push(message);
        if (state.history.length > 30) state.history.shift();
        state.historyIndex = state.history.length;
    }
    post('submit', { message });
    closeChat();
}

function matches() {
    const query = input.value.toLowerCase();
    if (!query.startsWith('/')) return [];
    return [...state.suggestions.values()]
        .filter((suggestion) => suggestion.name.toLowerCase().startsWith(query.split(' ')[0]))
        .slice(0, 5);
}

function updateSuggestions() {
    const items = matches();
    suggestionsEl.replaceChildren();
    suggestionsEl.classList.toggle('hidden', !state.open || items.length === 0);

    items.forEach((suggestion) => {
        const row = document.createElement('button');
        row.type = 'button';
        row.className = 'suggestion';
        const params = (suggestion.params || []).map((param) => `[${escapeHtml(param.name)}]`).join(' ');
        row.innerHTML = `<strong>${escapeHtml(suggestion.name)}</strong><span>${params}</span><small>${escapeHtml(suggestion.help || '')}</small>`;
        row.addEventListener('click', () => {
            input.value = `${suggestion.name} `;
            input.focus();
            updateSuggestions();
        });
        suggestionsEl.append(row);
    });
}

function insertEmoji(emoji) {
    const start = input.selectionStart ?? input.value.length;
    const end = input.selectionEnd ?? start;
    input.value = `${input.value.slice(0, start)}${emoji}${input.value.slice(end)}`;
    const caret = start + emoji.length;
    input.focus();
    input.setSelectionRange(caret, caret);
    updateSuggestions();
}

emojis.forEach((emoji) => {
    const button = document.createElement('button');
    button.type = 'button';
    button.className = 'emoji';
    button.textContent = emoji;
    button.title = emoji;
    button.addEventListener('click', () => insertEmoji(emoji));
    emojiPicker.append(button);
});

emojiButton.addEventListener('click', (event) => {
    event.stopPropagation();
    emojiPicker.classList.toggle('hidden');
    input.focus();
});

document.addEventListener('click', (event) => {
    if (!emojiPicker.contains(event.target) && event.target !== emojiButton) emojiPicker.classList.add('hidden');
});

form.addEventListener('submit', (event) => {
    event.preventDefault();
    submitMessage();
});

input.addEventListener('input', updateSuggestions);
input.addEventListener('keydown', (event) => {
    if (event.key === 'Escape') {
        event.preventDefault();
        post('close');
        closeChat();
        return;
    }
    if (event.key === 'ArrowUp' && state.history.length) {
        event.preventDefault();
        state.historyIndex = Math.max(0, state.historyIndex - 1);
        input.value = state.history[state.historyIndex] || '';
        updateSuggestions();
    }
    if (event.key === 'ArrowDown' && state.history.length) {
        event.preventDefault();
        state.historyIndex = Math.min(state.history.length, state.historyIndex + 1);
        input.value = state.history[state.historyIndex] || '';
        updateSuggestions();
    }
    if (event.key === 'Tab') {
        const first = matches()[0];
        if (first) {
            event.preventDefault();
            input.value = `${first.name} `;
            updateSuggestions();
        }
    }
});

window.addEventListener('message', ({ data }) => {
    const payload = data?.data;
    switch (data?.action) {
        case 'init':
            Object.assign(state, payload || {});
            break;
        case 'open': openChat(); break;
        case 'message': renderMessage(payload); break;
        case 'clear': log.replaceChildren(); break;
        case 'template': state.templates.set(payload.id, payload.html); break;
        case 'suggestion': state.suggestions.set(payload.name, payload); updateSuggestions(); break;
        case 'suggestions': {
            state.serverSuggestionNames.forEach((name) => state.suggestions.delete(name));
            state.serverSuggestionNames.clear();
            (payload || []).forEach((item) => {
                if (!item?.name) return;
                state.suggestions.set(item.name, item);
                state.serverSuggestionNames.add(item.name);
            });
            updateSuggestions();
            break;
        }
        case 'removeSuggestion':
            state.suggestions.delete(payload.name);
            state.serverSuggestionNames.delete(payload.name);
            updateSuggestions();
            break;
        case 'updateJobChatStyle': {
            if (!payload?.jobName) break;
            document.querySelectorAll('.job-message').forEach((message) => {
                if (message.dataset.job !== payload.jobName) return;
                message.style.setProperty('--role-color', payload.textColor);
                message.style.setProperty('--job-outline', payload.outlineColor);
            });
            break;
        }
        default: break;
    }
});

post('ready');
