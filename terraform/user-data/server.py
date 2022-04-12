#!/usr/bin/env python
# -*- encoding: utf-8 -*-
"""
Simple service repsponding on port 5000
Serves two endpoints /api and /healthcheck
"""
import json
import signal
import socket
import sys
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer


class BaseServer(BaseHTTPRequestHandler):
    def _set_headers(self, contenttype='application/json'):
        """
        Set default headers
        """
        self.send_response(200)
        self.send_header('Content-type', contenttype)
        try:
            self.send_header('X-Instance', '{}'.format(socket.gethostname()))
        except:
            pass
        self.end_headers()

    def do_GET(self):
        """
        Process GET request
        """
        # Default web path to handle ELB health checks
        if self.path == '/':
            self._set_headers(contenttype='text/html')
            self.wfile.write('There is nothing here'.encode('utf-8'))
        # Any other requests are considered as API and should contain proper content type header
        elif not self.check_ContentType():
            self.send_error(415, 'Wrong content type',
                            'Acceptable content-type: application/json')
        else:
            self.serve_Path()

    def check_ContentType(self, content_type='application/json') -> bool:
        """
        Check requested content type
        :param content_type - required content type, defaults to application/json
        """
        retval = True
        requested_contert_type = '{}/{}'.format(
            self.headers.get_content_maintype(), self.headers.get_content_subtype())
        if requested_contert_type != content_type:
            retval = False
        return retval

    def serve_Path(self, endpoints=['/healthcheck', '/api']):
        """
        Serves GET requests to endpoints
        :param endpoints - allowed endpoints to be queried
        """
        if self.path not in endpoints:
            self.send_error(404, 'Not found',
                            'Requested path "{}" was not found on this server'.format(self.path))
        else:
            if self.path == '/healthcheck':
                self.return_Health()
            if self.path == '/api':
                self.return_API()

    def return_API(self, api_endpoints=['ai.instrumental.com', 'api.instrumental.com', 'secure.factory-net.instrumental.com', 'secure.factory-net-v2.instrumental.com']):
        """
        Return APIs sting as json
        :param api_endpoints - list of APIs
        """
        retval = {
            'api_endpoints': ', '.join(api_endpoints)
        }
        self._set_headers()
        self.wfile.write(json.dumps(retval).encode('utf-8'))

    def return_Health(self, status='healthy'):
        """
        Return health status as json
        :param status - status to return, defaults to healthy
        """
        retval = {
            "service": "Instrumental API",
            "status": "{}".format(status)
        }
        self._set_headers()
        self.wfile.write(json.dumps(retval).encode('utf-8'))


def terminate(signalNumber, frame):
    """
    Terminnation and calling for sys.exit()
    """
    print('Received {}'.format(signalNumber))
    sys.exit()


def run(server_class=ThreadingHTTPServer, handler_class=BaseServer, port=5000):
    """
    Start server
    :param server_class  - Base HTTP server class, low level network operations
    :param handler_class - HTTP protocol processing class instance, process GET/POST/etc requests
    :param port          - HTTP server port, defaults to 5000
    """
    server_address = ('', port)
    httpd = server_class(server_address, handler_class)
    signal.signal(signal.SIGTERM, terminate)
    signal.signal(signal.SIGINT, terminate)
    print('HTTP server running on port {}'.format(port))
    httpd.serve_forever()


if __name__ == "__main__":
    run()
