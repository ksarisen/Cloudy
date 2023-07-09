import React, {useState} from "react";
import './Home.css';
import Navbar from '../Navbar/Navbar';


export const Home = (props) => {
    const[file, setFile] = useState('');

    function handleFile(event){
        if(typeof(event.target.files[0]) !== 'undefined' && event.target.files[0] != null){
            setFile(event.target.files[0]);
            console.log(event.target.files[0]);
            console.log({file});
        }else{
            console.log("File Not Chosen");
        }
       
       
    }

    function handleUpload(){
        const formData = new FormData()
        formData.append('file', file)
        fetch(
            'url',
            {
                method: "POST",
                body: formData
            }
        )
        .then((response) => response.json())
        .then(
            (result) => {
                console.log('success', result)
            }
        )
        .catch(error =>{
            console.error("Error:", error)
        })
    }

    return(
        // body
        <div>
             {/* top bar */}
             <Navbar/>
            <div>
                <div className="upload-form">
                    <div className="flex-container">
                    <div className="flex-child">
                    <label className="greeting-labels">Nice to see you, Ouldooz!</label>
                    <br/>
                    <br/>
                    </div>
                    <div className="flex-child">
                        <form onSubmit={handleUpload}>
                            <div className="upload-container">
                            <label className="upload-labels">Try to Upload a File: &nbsp;</label> 
                            <input className="file" type = "file" name="file" onChange={handleFile}/>
                            </div>
                            <br/>
                            <button className="button" type="submit">Upload</button>
                        </form>
                        {/* If we want to add anything to the right side of the uploads */}
                    </div>
                    </div>
                </div>
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