import os
import unittest
import tempfile
import atexit
from flask import Flask
from werkzeug.datastructures import FileStorage

# Import the function to be tested
from CloudyMain import upload_file


class FileUploadTestCase(unittest.TestCase):
    temp_file = tempfile.NamedTemporaryFile(suffix=".xlsx", delete=False)
    def setUp(self):
        # Create a test Flask app
        self.app = Flask(__name__)
        self.app.config['TESTING'] = True

    #helper functions, credit to stephen kilonzo
    def delete_files(files):
        for file in files:
            file.close()
            os.unlink(file.name)

    def tearDown(self):
        atexit.register(FileUploadTestCase.delete_files, FileUploadTestCase.temp_file)
        pass

    def test_file_upload_valid(self):
        # Create a temporary file for testing
        with tempfile.NamedTemporaryFile(delete=False) as temp_file:
            # Write some content to the temporary file (optional)
            temp_file.write(b'Test file content')
            temp_file.flush()

            # Create a test client
            with self.app.test_client() as client:
                # Mock the file to be uploaded
                file = FileStorage(stream=open(temp_file.name, 'rb'), filename='test_file.txt')

                # Upload the file
                response = client.post('/upload', data={'file': file})

                # Assert the response
                self.assertEqual(response.status_code, 200)
                self.assertEqual(response.data, b'File uploaded successfully')

                # Assert the file is saved
                storage_path = os.getenv('LOCAL_STORAGE_PATH')
                self.assertTrue(os.path.exists(os.path.join(storage_path, 'test_file.txt')))


    def test_file_upload_no_file(self):
        # Create a test client
        with self.app.test_client() as client:
            # Upload without a file
            response = client.post('/upload')

            # Assert the response
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.data, b'No file found in the request')

    def test_file_upload_no_filename(self):
        # Create a temporary file for testing
        with tempfile.NamedTemporaryFile() as temp_file:
            # Create a test client
            with self.app.test_client() as client:
                # Mock a file with an empty filename
                file = FileStorage(stream=open(temp_file.name, 'rb'), filename='')

                # Upload the file
                response = client.post('/upload', data={'file': file})

                # Assert the response
                self.assertEqual(response.status_code, 200)
                self.assertEqual(response.data, b'No file selected')

    def test_file_download(self):
        # Placeholder test for the file download endpoint
        pass

    

if __name__ == '__main__':
    unittest.main()
