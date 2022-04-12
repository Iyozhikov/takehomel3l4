#!/usr/bin/env python
# -*- encoding: utf-8 -*-
"""
Simple service client to check server at port 5000
queries endpoints /api and /healthcheck
"""
from email.policy import default
import http.client
import json
from termcolor import colored
import re
import argparse

connection = None
required_content_type = 'application/json'


def setup_connection(proto: str, host: str, port: str, timeout=5):
    """
    Setup connection object
    :param proto   - Protocol HTTP or HTTPS
    :param host    - remote hostname
    :param port    - remote host port value
    :param timeout - request timeout, default to 5s
    """
    global connection
    print('Remote server address: {}'.format(
        colored('{}://{}:{}'.format(proto, host, port), 'yellow')))
    if proto == 'http':
        connection = http.client.HTTPConnection(
            host=host, port=port, timeout=timeout)
    elif proto == 'https':
        connection = http.client.HTTPSConnection(
            host=host, port=port, timeout=timeout)
    else:
        raise Exception('Unknown protocol: "{}"'.format(proto))


def process_response(response: object):
    """
    Process http(s) response
    :param response - response object containing server response data
    """
    retval = '{}'
    try:
        ct_header = response.getheader('Content-type')
        if ct_header != required_content_type:
            raise Exception('Wrong content type received, status code:{}, reason: {}'.format(
                response.status, response.reason))
        if response.status != 200:
            raise Exception('Server returned error, status code:{}, reason: {}'.format(
                response.status, response.reason))
        else:
            retval = response.read().decode('utf-8')
    except Exception as error:
        print('{} Server returned wrong content type: {}\n Expected content-type: {}\n Error details: {}'.format(
            colored('ERROR:', 'red'), ct_header, required_content_type, error))
        pass
    finally:
        return retval


def get_json_data(webpath: str) -> dict:
    """
    Request data and process response
    :param webpath - web path to be added to proto://host:port/
    """
    headers = {'Content-type': '{}'.format(required_content_type)}
    try:
        print('\nChecking endpoint: {} ...'.format(colored(webpath, 'yellow')))
        connection.request(method='GET', url=webpath,
                           body=None, headers=headers)
        response = connection.getresponse()
        instance_name = response.getheader('X-Instance')
        if instance_name != None:
            print('Reading response from instance: {}'.format(
                colored(instance_name, 'green')))
        response_data = process_response(response)
        json_response = json.loads(response_data)
        return json_response
    except Exception as error:
        print('{} Can\'t process request to {}, remote endpoint is inaccessible, please check input data or network settings'.format(
            colored('ERROR:', 'red'), webpath, connection.host, connection.port))


def query_health():
    """
    Query Healthcheck endpoint
    """
    server_response = get_json_data(webpath='/healthcheck')

    if server_response != {} and server_response != None:
        try:
            if server_response['status'] == 'healthy':
                health_string = colored(server_response['status'], 'green')
            else:
                health_string = colored(server_response['status'], 'red')
            service_string = server_response['service']
            print('Service {} is {}'.format(
                service_string, health_string))
        except Exception as error:
            print('{} Server response is not parseable, due to {}'.format(
                colored('ERROR:', 'red'), error))


def query_api():
    """
    Query API endpoint
    """
    server_response = get_json_data(webpath='/api')
    if server_response != {} and server_response != None:
        try:
            api_list = server_response['api_endpoints'].split(', ')
            print('Received API endpoints list:')
            if len(api_list) > 0:
                for api in api_list:
                    print(' - {}'.format(api))
            else:
                print('{} API endpoints list is empty'.format(
                    colored('WARNING:', 'magenta')))
        except Exception as error:
            print('{} Server response is not parseable, due to {}'.format(
                colored('ERROR:', 'red'), error))


def parse_arguments():
    """
    Parse arguments
    :returns argument values
    """
    parser = argparse.ArgumentParser(
        description='Remote API check script')
    parser.add_argument('-u', '--url', type=str, default='http://18.237.45.210:000',
                        dest='url', help='Server URL http(s)://host[:port]', required=False)
    parser.add_argument('-t', '--timeout', type=float, default=2, dest='timeout',
                        help='(Optional) request timeout in seconds, default is 5', required=False)
    args = None
    try:
        args = vars(parser.parse_args())
        return args
    except:
        exit(2)


if __name__ == "__main__":
    # Parsing command line arguments
    args = parse_arguments()
    url = args['url']
    timeout = args['timeout']
    default_port = 5000
    # Parsing URL into proto, host, port using regexp
    try:
        search_obj = re.findall(
            '((\w+)://([\w\-\.]+):([1-9][0-9]{0,4})?)$', url)
        fullmatch, proto, host, port = search_obj[0]
        # If port value is wrong or returned as '' by regexp
        if len(port) == 0 or port == None or int(port) > 65535:
            raise
    except:
        print(
            '{} Port should be in range of 1 - 65535, default value will be used:{}'.format(colored('WARNING:', 'magenta'), default_port))
        # Extract only protocol & host
        proto, host = re.findall('(\w+)://([\w\-\.]+)', url)[0]
        port = default_port
    # Creating http(s) client
    if connection == None:
        try:
            setup_connection(proto=proto, host=host,
                             port=port, timeout=timeout)
            query_health()
            query_api()
        except Exception as error:
            print('{} Can\'t connect to {}:{}, due to {}'.format(
                colored('ERROR:', 'red'), host, port, error))
