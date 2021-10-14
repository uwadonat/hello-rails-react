import React from "react"
import { BrowserRouter, Switch, Route } from 'react-router-dom'
import { Provider } from 'react-redux'


import store from '../redux/ConfigureStore'
import Greeting from "./Greeting"

const App = () => {
 
    return (
      <Provider store={store}>
        <Greeting />
        
      </Provider>
    );
  
}

export default App
