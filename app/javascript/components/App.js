import React from "react"
import PropTypes from "prop-types"
class App extends React.Component {
  render () {
    return (
      // <React.Fragment>
          <BrowserRouter>
            <Switch>
              <Route exact path="/" render={() => ("Home!")} />
              <Route path="/hello" render={() => <Greating greating="Friend" />} />
            </Switch>
          </BrowserRouter>
      // </React.Fragment>
    );
  }
}

export default App
