"""Usage: fake_registry.py <dir>

Serves the token and tags-list endpoints of an OCI registry on a free port, which it prints.
<dir>/<repository>/tags.json is the tags-list body; <dir>/<repository>/status overrides the status.
If <dir>/credentials holds user:password, tokens are only issued for those basic-auth credentials.
Repositories with neither answer 404 NAME_UNKNOWN, as GHCR does before the first push.
"""

import base64
import json
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

TOKEN = "fake-token"
root = Path(sys.argv[1])


class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        path = self.path.split("?")[0]
        if path == "/token":
            credentials = root / "credentials"
            if credentials.exists():
                expected = "Basic " + base64.b64encode(credentials.read_text().strip().encode()).decode()
                if self.headers.get("Authorization") != expected:
                    return self.reply(401, {"errors": [{"code": "UNAUTHORIZED"}]})
            return self.reply(200, {"token": TOKEN})
        if self.headers.get("Authorization") != f"Bearer {TOKEN}":
            return self.reply(401, {"errors": [{"code": "UNAUTHORIZED"}]})
        if not (path.startswith("/v2/") and path.endswith("/tags/list")):
            return self.reply(404, {"errors": [{"code": "NOT_FOUND"}]})
        repo = root / path[len("/v2/") : -len("/tags/list")]
        if (repo / "status").exists():
            return self.reply(int((repo / "status").read_text()), {"errors": [{"code": "FAKE"}]})
        if (repo / "tags.json").exists():
            return self.reply(200, json.loads((repo / "tags.json").read_text()))
        return self.reply(404, {"errors": [{"code": "NAME_UNKNOWN"}]})

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def log_message(self, *args):
        pass


server = HTTPServer(("127.0.0.1", 0), Handler)
print(server.server_port, flush=True)
server.serve_forever()
