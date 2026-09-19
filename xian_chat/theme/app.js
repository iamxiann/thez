(async () => {
    const RESOURCE_NAME = 'qbx_chat';

    const data = await fetchNui('config');

    /** @type {{ property: string; value: string | null }[]} */
    const vars = [
        { property: '--main-color', value: data.mainColor },
        { property: '--border-color', value: data.borderColor },
        { property: '--text-color', value: data.textColor },
        { property: '--faint-color', value: data.faintColor },
        { property: '--font-family', value: data.fontFamily },
        { property: '--console-font-family', value: data.consoleFontFamily },
        { property: '--suggestion-font-family', value: data.suggestionFontFamily },
        { property: '--input-icon-url', value: `url(${data.inputIconUrl})` },
        { property: '--message-icon-url', value: `url(${data.messageIconUrl})` },
        { property: '--console-icon-url', value: `url(${data.consoleIconUrl})` },
        { property: '--join-icon-url', value: `url(${data.joinIconUrl})` },
        { property: '--quit-icon-url', value: `url(${data.quitIconUrl})` },
        { property: '--user-icon-url', value: `url(${data.userIconUrl})` },
    ];

    for (const { property, value } of vars) {
        document.documentElement.style.setProperty(property, value);
    }

    setupChatVisibility();

    function setupChatVisibility() {
        const FADE_TIMEOUT = 10000;
        const hiddenClass = 'qbx-chat-window-hidden';
        let hideTimer;
        let inputWasOpen = false;

        const isInputOpen = () => {
            const input = document.querySelector('.chat-input');
            if (!input) return false;

            const style = window.getComputedStyle(input);
            return style.display !== 'none' && style.visibility !== 'hidden' && style.opacity !== '0';
        };

        const showWindow = (keepOpen = false) => {
            document.body.classList.remove(hiddenClass);
            window.clearTimeout(hideTimer);

            if (!keepOpen) {
                hideTimer = window.setTimeout(() => {
                    if (!isInputOpen()) document.body.classList.add(hiddenClass);
                }, FADE_TIMEOUT);
            }
        };

        const syncInputState = () => {
            const inputOpen = isInputOpen();
            if (inputOpen) {
                showWindow(true);
            } else if (inputWasOpen) {
                showWindow();
            }
            inputWasOpen = inputOpen;
        };

        const attachMessageObserver = () => {
            const messages = document.querySelector('.chat-messages');
            if (!messages || messages.dataset.visibilityObserver) return;

            messages.dataset.visibilityObserver = 'true';
            new MutationObserver((mutations) => {
                const hasNewMessage = mutations.some((mutation) => mutation.addedNodes.length > 0);
                if (hasNewMessage) showWindow(isInputOpen());
            }).observe(messages, { childList: true, subtree: true });
        };

        new MutationObserver(() => {
            attachMessageObserver();
            syncInputState();
        }).observe(document.body, {
            childList: true,
            subtree: true,
            attributes: true,
            attributeFilter: ['class', 'style'],
        });

        document.addEventListener('focusin', syncInputState);
        document.addEventListener('focusout', () => window.setTimeout(syncInputState));

        attachMessageObserver();
        syncInputState();
        showWindow();
    }

    /**
     * @param {string} endpoint
     * @param {unknown} data
     */
    async function fetchNui(endpoint, data) {
        const body = typeof data === 'undefined' || data === null ? null : JSON.stringify(data);

        const response = await fetch(`https://${RESOURCE_NAME}/${endpoint}`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json; charset=UTF-8',
            },
            body,
        });

        return await response.json();
    }
})();
