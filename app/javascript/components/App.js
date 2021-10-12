import React from "react"

import PropTypes from "prop-types"
import { BrowserRouter, Switch, Route } from 'react-router-dom'
import HelloWord from "./HelloWord"
class App extends React.Component {
  render () {
    return (
      
          <BrowserRouter>
            <Switch>
              {/* <Route exact path="/" render={() => ("Home!")} /> */}
              <Route path="/" render={() => <HelloWord  greeting="Friend"/>} />
            </Switch>
          </BrowserRouter>
      
    );
  }
}

export default App
