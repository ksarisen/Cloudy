import time
import requests
from flask import Flask

app = Flask(__name__)

# @app.route('/ping')
# def ping_endpoint():
#     # Perform any desired actions or logic for the ping endpoint
#     # ...

#     return 'Ping received'

def ping_loop():
    while True:
        try:
            # Ping the desired endpoint
            #TODO: get list of storage provider ips from blockchain, then loop to query each of them.
            response = requests.get('http://localhost:5000/audit')
            print(response.text)  # Print the response for demonstration

        except requests.RequestException as e:
            print('Error occurred during ping:', e)

        time.sleep(300)  # Sleep for 5 minutes (300 seconds)

if __name__ == '__main__':
    # Start the ping loop in a separate thread
    import threading
    threading.Thread(target=ping_loop, daemon=True).start()

    # Run the Flask server
    app.run()
