Author: Benjamin Djukastein.
Created on May 24th, 2023.

Startup guide for local development:

Installation guide:
make a folder where you want to code, and clone this repo there. Also, make a folder where you will want to store the incoming files.
Create a file called ".env" containing the line LOCAL_STORAGE_PATH = "D:/path/to/where/you/want/to/store/files" with the actual path where you want to store the uploaded files.
Create a virtual environment using "python -m venv venv"
Enter the virtual environment using ".\venv\Scripts\activate"
python -m pip install numpy
python -m pip install flask
python -m pip install werkzeug
python -m pip install --upgrade setuptools
python -m pip install python-dotenv


Run the program locally for testing using the command:
python CloudyMain.py

Interact with the running service by hitting the following endpoint with a POST containing the file you want to upload
http://127.0.0.1:5000/upload


TODOS:
Ensure the max storage limit is tracked and enforced.
connect to the blockchain to track available shards
Ensure only actual owner can delete relevant shards via a view external check the Provider can hit in the storage contract.