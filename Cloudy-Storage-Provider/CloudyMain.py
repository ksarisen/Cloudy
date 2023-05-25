#Benjamin Djukastein
from flask import Flask, request, render_template
from werkzeug.utils import secure_filename
from dotenv import load_dotenv

#load the local variables from .env file
load_dotenv() 

app = Flask(__name__)

app.debug = True

@app.route('/upload', methods=['POST'])
def upload_file():
    # Check if the 'file' key exists in the request
    if 'file' not in request.files:
        return 'No file found in the request'

    file = request.files['file']
    
    # Check if a file was selected
    if file.filename == '':
        return 'No file selected'
    
    # Save the file to the specified path
    filename = secure_filename(file.filename)
    file.save(f"{os.getenv('LOCAL_STORAGE_PATH')}/{filename}")

     # Create a response with a custom message
    response = make_response('File uploaded successfully')
    
    # Set the status code to 200
    response.status_code = 200
    
    return response

@app.route('/', methods=['GET'])
def home():
    return render_template('index.html')

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)
