import React, {useState} from 'react';
import './Navbar.css';


function Navbar(){
    return(
        <div className="top-bar">
                <nav className="nav-container">
                 <img className='cloudy-logo' src='/images/cloudy-logo1.png'  height="50"/>
                 <ul className='nav-menu'>
                    <li className='nav-list-item '><a className='nav-item hover-underline-animation' href="/">Home</a></li>
                    <li className='nav-list-item '><a className='nav-item hover-underline-animation' href="#">Upload</a></li>
                    <li className='nav-list-item '><a className='nav-item hover-underline-animation' href="#">Profile</a></li>
                    <li className='nav-list-item '><a className='nav-item hover-underline-animation' href="#">Log Out</a></li>
                 </ul>
                 <div className='nav-toggler'>
                    <div className='line1'></div>
                    <div className='line2'></div>
                    <div className='line3'></div>
                 </div>
                </nav>
        </div>
    )
}

export default Navbar;