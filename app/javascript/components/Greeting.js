import React, { useEffect, useState } from "react";
import { useSelector, useDispatch } from 'react-redux';
import { displayMessages } from '../redux/Messages';

const Greeting = () => {
    const messages = useSelector((state) => state.messageReducer);
    const [message, setMessage] = useState({});
    

    const dispatch = useDispatch();
    useEffect(() => {
        if (!messages.length) {
            dispatch(displayMessages());
        }
    }, []);
 
   const [ body, displayBody] = useState([]);


   useEffect(() => {
     
        displayBody(messages) 
   
   }, [messages]);

  

    const hello = () => {
        return messages[0] && messages[Math.floor(Math.random() * messages.length)].body
    }


    return (
        
          <div className="display">
              <h2>Display random messages from Redux </h2>
              <p>{messages && hello()}</p>
          </div>
    );
};

export default Greeting;