Author: Benjamin Djukastein.
Created on May 24th, 2023.

Startup guide for local development:

Installation guide:
make a folder where you want to code, and clone this repo there. Also, make a folder where you will want to store the incoming files.
python -m pip install numpy
python -m pip install flask
python -m pip install werkzeug.utils
Create a file called ".env" containing the line LOCAL_STORAGE_PATH = "D:/path/to/where/you/want/to/store/files" with the actual path where you want to store the uploaded files.

Run the program locally for testing using the command:
python CloudyMain.py

Interact with the running service by hitting the following endpoint with a POST containing thee file you want to upload
http://127.0.0.1:5000/upload