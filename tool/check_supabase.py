"""Check Daryeel's public Supabase configuration. Never prints API keys."""
import argparse
import base64
import json
import re
from pathlib import Path
from urllib.parse import urlparse
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError

ROOT = Path(__file__).resolve().parents[1]

def validate(config):
    url = str(config.get('SUPABASE_URL', '')).strip().rstrip('/')
    key = str(config.get('SUPABASE_PUBLISHABLE_KEY') or config.get('SUPABASE_ANON_KEY') or '').strip()
    parsed = urlparse(url)
    if not url or not key:
        raise ValueError('Fill SUPABASE_URL and SUPABASE_PUBLISHABLE_KEY in env.json first.')
    if parsed.scheme != 'https' or not (parsed.hostname or '').endswith('.supabase.co') or parsed.username or parsed.password or parsed.port or parsed.path or parsed.query or parsed.fragment or 'YOUR-' in url.upper():
        raise ValueError('Use the HTTPS Project URL from Supabase Connect (https://<project-ref>.supabase.co).')
    if key.startswith('sb_secret_'):
        raise ValueError('Secret keys are forbidden in Flutter. Replace this with the public publishable key.')
    if key.startswith('sb_publishable_'):
        if len(key) < 25 or 'YOUR_' in key.upper() or not re.fullmatch(r'sb_publishable_[A-Za-z0-9_-]+', key):
            raise ValueError('Replace the placeholder with your real public publishable key.')
    else:
        try:
            payload = key.split('.')[1]
            role = json.loads(base64.urlsafe_b64decode(payload + '=' * (-len(payload) % 4))).get('role')
        except (ValueError, IndexError, TypeError):
            role = None
        if role != 'anon':
            raise ValueError('Use an sb_publishable_ key or a legacy anon key, never a service-role or user session token.')
    return url, key

def request(url, key, path, data=None):
    req = Request(url + path, data=None if data is None else json.dumps(data).encode(), headers={'apikey': key, 'Content-Type':'application/json'})
    try:
        with urlopen(req, timeout=20) as response:
            return response.status, json.load(response)
    except HTTPError as error:
        try:
            body = json.loads(error.read())
        except ValueError:
            body = {}
        return error.code, body

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--online', action='store_true', help='Read Auth settings and check anonymous RPC access is denied; creates no users or records.')
    args = parser.parse_args()
    try:
        config = json.loads((ROOT / 'env.json').read_text(encoding='utf-8-sig'))
        url, key = validate(config)
        print('Public-key configuration is valid. No key values were printed.')
        if args.online:
            status, settings = request(url, key, '/auth/v1/settings')
            if status != 200:
                raise ValueError(f'Auth endpoint rejected the configuration (HTTP {status}). Check URL/key and project status.')
            if not settings.get('external', {}).get('email', False):
                raise ValueError('Email authentication is not enabled in this project.')
            print('Auth endpoint reachable; email authentication enabled.')
            status, result = request(url, key, '/rest/v1/rpc/sync_records', {'changes': []})
            if status == 404:
                raise ValueError('sync_records is missing. Run supabase/setup.sql in the project SQL Editor.')
            if status not in (401,403) and not (status == 400 and result.get('code') == 'P0001'):
                raise ValueError(f'Anonymous sync access was not denied as expected (HTTP {status}); inspect grants and RLS.')
            print('Anonymous sync is denied. This does NOT verify two-account RLS or SMTP delivery.')
        return 0
    except (OSError, ValueError, URLError) as error:
        # Validation messages contain no supplied key values. Network messages
        # are reduced to their type to avoid echoing request details.
        print(str(error) if isinstance(error, ValueError) else 'Configuration/network check failed. Check env.json and connectivity.')
        return 1

if __name__ == '__main__':
    raise SystemExit(main())
