const DISPLAY_MESSAGES = 'HELLOWORDS/DISPLAY_MESSAGES';

const loadMessages = (json) => ({
    type: DISPLAY_MESSAGES,
    json,
});

const messageReducer = (state = [], action) => {
    switch (action.type) {
        case DISPLAY_MESSAGES:
            return action.json.map((message) => {
                const {
                    id,
                    body
                } = message;
                return {
                    id, body,
                };
            });
            default:
              return state;
    }
};

const displayMessages = () => (dispatch) => {
    fetch('api/messages')
      .then((response) => response.json())
      .then((json) => dispatch(loadMessages(json)));
};

export {
    loadMessages,
    messageReducer,
    displayMessages,
};