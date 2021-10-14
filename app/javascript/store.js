import { combineReducers } from "redux";
import messageReducer from "./reducer";

const rootReducer = combineReducers({
messages: messageReducer 
});
export default rootReducer; 