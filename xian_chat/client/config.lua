RegisterNUICallback('config', function(_data, cb)
    cb({
        mainColor = GetConvar('qbx_chat:mainColor', '#101115'),
        borderColor = GetConvar('qbx_chat:borderColor', 'rgba(255, 255, 255, 0.10)'),
        textColor = GetConvar('qbx_chat:textColor', '#e8e9ed'),
        faintColor = GetConvar('qbx_chat:faintColor', '#c9ccd3'),

        fontFamily = GetConvar('qbx_chat:fontFamily', "Roboto, 'Segoe UI', Arial, Helvetica, sans-serif"),
        consoleFontFamily = GetConvar('qbx_chat:consoleFontFamily', 'monospace'),
        suggestionFontFamily = GetConvar('qbx_chat:suggestionFontFamily', 'monospace'),

        inputIconUrl = GetConvar('qbx_chat:inputIconUrl', 'https://cfx-nui-qbx_chat/theme/icons/message.svg'),
        messageIconUrl = GetConvar('qbx_chat:messageIconUrl', 'https://cfx-nui-qbx_chat/theme/icons/message.svg'),
        consoleIconUrl = GetConvar('qbx_chat:consoleIconUrl', 'https://cfx-nui-qbx_chat/theme/icons/console.svg'),
        joinIconUrl = GetConvar('qbx_chat:joinIconUrl', 'https://cfx-nui-qbx_chat/theme/icons/join.svg'),
        quitIconUrl = GetConvar('qbx_chat:quitIconUrl', 'https://cfx-nui-qbx_chat/theme/icons/quit.svg'),
        userIconUrl = GetConvar('qbx_chat:userIconUrl', 'https://cfx-nui-qbx_chat/theme/icons/user.svg'),
    })
end)
