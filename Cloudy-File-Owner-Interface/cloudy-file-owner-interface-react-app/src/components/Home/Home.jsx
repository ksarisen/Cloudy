import React, {useState} from "react";
import './Home.css';
import Navbar from '../Navbar/Navbar';


export const Home = (props) => {
    const[selectedFile, setSelectedFile] = useState('');

    const handleSubmit = (e) => {
        e.preventDefault();

    }
    return(
        // body
        <div>
             {/* top bar */}
             <Navbar/>
            <div>
                <form className="upload-form" onSubmit={handleSubmit}>
                    <div className="flex-container">
                    <div className="flex-child">
                    <label className="greeting-labels">Nice to see you, Ouldooz!</label>
                    <br/>
                    <br/>
                    </div>
                    <div className="flex-child">
                        <label className="upload-labels">Try to Upload a File:</label>
                        <br/>
                        <br/>
                        <button className="button" type="submit">Upload</button>
                        {/* If we want to add anything to the right side of the uploads */}
                    </div>
                    </div>
                </form>
                <br/>
                <br/>
                <div className="table-container">
                    <table className="search-table">
                    <tbody>    
                        <tr>
                            <th>File Name</th>
                            <th>Date Uploaded</th>
                            <th>Download</th>
                            <th>Delete</th>
                        </tr>
                        <tr>
                            <td className="filename">CMPT 495 - Homework 1</td>
                            <td>07/01/2023</td>
                            <td><a className='download-button'>Download</a></td>
                            <td><a className='delete-button'>Delete</a></td>
                        </tr>
                        <tr>
                            <td className="filename">CMPT 495 - Homework 2</td>
                            <td>07/01/2023</td>
                            <td><a className='download-button'>Download</a></td>
                            <td><a className='delete-button'>Delete</a></td>
                        </tr>
                        <tr>
                            <td className="filename">CMPT 495 - Homework 3</td>
                            <td>07/01/2023</td>
                            <td><a className='download-button'>Download</a></td>
                            <td><a className='delete-button'>Delete</a></td>
                        </tr>
                        <tr>
                            <td className="filename">CMPT 495 - Homework 4</td>
                            <td>07/01/2023</td>
                            <td><a className='download-button'>Download</a></td>
                            <td><a className='delete-button'>Delete</a></td>
                        </tr>
                        <tr>
                            <td className="filename">CMPT 495 - Homework 5</td>
                            <td>07/01/2023</td>
                            <td><a className='download-button'>Download</a></td>
                            <td><a className='delete-button'>Delete</a></td>
                        </tr>
                    </tbody>
                    </table>
                </div>
            </div>

        </div>
    )
}
export default Home;