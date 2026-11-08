"""Interactive real-account verification. Passwords and tokens stay in process memory."""
import argparse
import json
import secrets
import sys
from urllib.request import Request, urlopen
from urllib.error import HTTPError
from check_supabase import ROOT, validate

parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('--email', required=True)
args = parser.parse_args()
if not sys.stdin.isatty():
    raise SystemExit('Run this interactive check in a terminal so email confirmation can be acknowledged before testing continues.')
url, key = validate(json.loads((ROOT / 'env.json').read_text(encoding='utf-8-sig')))
password = secrets.token_urlsafe(32) + 'Aa1!'

def call(path, body=None, token=None, method=None):
    headers = {'apikey':key, 'Content-Type':'application/json'}
    if token: headers['Authorization'] = 'Bearer ' + token
    req = Request(url+path, data=None if body is None else json.dumps(body).encode(), headers=headers, method=method)
    try:
        with urlopen(req, timeout=30) as response:
            raw=response.read()
            return response.status, json.loads(raw) if raw else {}
    except HTTPError as e:
        try: result=json.loads(e.read())
        except ValueError: result={}
        return e.code,result

def report(label,status,result):
    print(label + ' HTTP ' + str(status) + ' code=' + str(result.get('code',result.get('error_code','none'))),flush=True)

status,result=call('/auth/v1/signup?redirect_to=io.daryeel.app%3A%2F%2Flogin-callback%2F',{'email':args.email,'password':password,'data':{'full_name':'Daryeel verification'}})
report('Signup',status,result)
if status >= 400: raise SystemExit(1)
user=result.get('user',result)
if user.get('identities') == []:
    print('Existing/obfuscated account response. No authenticated registration established.',flush=True)
    raise SystemExit(2)
if not result.get('access_token'):
    print('WAITING_FOR_EMAIL_CONFIRMATION. Open the signup email, confirm it, then reply confirmed.',flush=True)
    input()
status,result=call('/auth/v1/token?grant_type=password',{'email':args.email,'password':password})
report('Login',status,result)
if status != 200: raise SystemExit(3)
token=result['access_token']
uid=result['user']['id']
status,profile=call('/rest/v1/profiles?select=id,full_name&id=eq.'+uid,token=token)
print('Own profile lookup HTTP '+str(status)+' rows='+str(len(profile) if isinstance(profile,list) else 0),flush=True)
status,rows=call('/rest/v1/rpc/sync_records',{'changes':[]},token)
print('Authenticated sync HTTP '+str(status)+' rows='+str(len(rows) if isinstance(rows,list) else 0),flush=True)
status,bad=call('/auth/v1/token?grant_type=password',{'email':args.email,'password':secrets.token_urlsafe(32)})
report('Incorrect password',status,bad)
status,out=call('/auth/v1/logout',{},token)
report('Logout',status,out)
status,recovery=call('/auth/v1/recover?redirect_to=io.daryeel.app%3A%2F%2Flogin-callback%2F',{'email':args.email})
report('Recovery request',status,recovery)
print('Account retained. Use the recovery email to choose your own password. Email delivery and completion require user confirmation.',flush=True)
