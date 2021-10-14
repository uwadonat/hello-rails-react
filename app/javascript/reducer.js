const initialState = {
   messages: {}
};

function messageReducer(state = initialState, action) {
  switch (action.type) {
  case "FETCH_MESSAGE":
    return action.payload;
   default:
       return state;
    }
}
   
export default messageReducer;
