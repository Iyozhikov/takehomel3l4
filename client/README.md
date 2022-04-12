# A simple web client

## Setup

```
python3 -m virtualenv venv
venv/bin/python3 -m pip install -r requirements.txt
```

## Usage

```
usage: clinet.py [-h] -u URL [-t TIMEOUT]
```

### Command line arguments
- -u or --url - http(s)://host\[:port], if port is omitted or has value higher than 65535, default faule will be used - 5000
- -t or --timeout - request timeout in seconds, default is 5

