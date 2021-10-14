import React from "react"
import { BrowserRouter, Switch, Route } from 'react-router-dom'
import { Provider } from 'react-redux'

import Greeting from "./Greeting"
import store from '../redux/ConfigureStore'


const App = () => {
 
    return (
      <Provider store={store}>
        <Greeting />
        
      </Provider>
    );
  
}

export default App
