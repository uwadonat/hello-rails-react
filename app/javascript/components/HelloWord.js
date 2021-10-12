import React from "react"
import { connect } from "react-redux";
import { createStructuredSelector } from 'reselect';

const GET_MESSAGES_REQUEST = 'GET_MESSAGES_REQUEST';
import PropTypes from "prop-types";

function getMessages() {
  console.log('getMessages() Action!!')
  return {
    type: GET_MESSAGES_REQUEST
  };
};

class HelloWord extends React.Component {
  render () {
    return (
      <React.Fragment>
        Greeting: {this.props.greeting}
        <button className="getMessageBtn" onClick={() => this.props.getMessages()}>getMessages</button>
        <br />
        <ul> { MessagesList }</ul>
      </React.Fragment>
    );
  }
}

const structuredSelector = createStructuredSelector({
  messages: state => state.messages,
});

HelloWord.propTypes = {
  greeting: PropTypes.string
};

const mapDispatchToProps = { getMessages };


export default connect(structuredSelector, mapDispatchToProps)(HelloWord);

