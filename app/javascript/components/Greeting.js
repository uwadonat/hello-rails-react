import React, { useEffect, useState } from "react";
import { useSelector, useDispatch } from 'react-redux';
import { displayMessages } from '../redux/Messages';

const Greeting = () => {
    const messages = useSelector((state) => state.messageReducer);
    
    const [message, setMessage] = useState({});
    const { body, id } = message;

    const dispatch = useDispatch();
    useEffect(() => {
        if (!messages.length) {
            dispatch(displayMessages());
        }
    }, []);
 
    const mess = () => {
        console.log("hell")
    }


    const select = () => {
        setMessage(messages[Math.floor(Math.randow() * messages.length)]);
        console.log("hello")
    };
  console.log("hi")
    return (
        
          <div>
              <button onClick={select}>Load Messages</button>
              <div key={id}>
                 <h2>{body}</h2>
                 
              </div>
          </div>
       
      );
};

export default Greeting;