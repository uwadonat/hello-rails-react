import React from "react"
import PropTypes from "prop-types"
class HelloWord extends React.Component {
  render () {
    return (
      <React.Fragment>
        Greeting: {this.props.greeting}
      </React.Fragment>
    );
  }
}

HelloWord.propTypes = {
  greeting: PropTypes.string
};
export default HelloWord
