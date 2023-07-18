To run our Cloudy distributed storage App locally for testing, follow the README setup guides in each of the folders in the following order:
Note that each folder is a separate app that must be run from its own terminal window (Only exception is: Cloudy-Blockchain doesn't run from terminal, rather it's deployed from a Remix browser tab locally)

1.Cloudy-Blockchain, to set up a remix/ganache local blockchain instance tracking ownership and storage of files and shards.
2.Cloudy-Storage-Provider, to set your computer up as a File Storage Provider, and allow users to store shards on a local directory of your choice via an exposed port.
3.Cloudy-File-Owner-Interface, to run our File Owner frontend browser interface for you try uploading downloading, and deleting files you wish to store.
4.Cloudy-Incentives-Manager, to run a looping function that ensures storage providers receive compensation for storing shards if they can confirm their successful storage.
