import base64
import json
import unittest
from check_supabase import validate

class ConfigTests(unittest.TestCase):
    url = 'https://example-project.supabase.co'
    def test_empty_config_is_rejected(self):
        with self.assertRaises(ValueError): validate({})
    def test_public_key_is_accepted(self):
        key = 'sb_publishable_' + 'a' * 30
        self.assertEqual(validate({'SUPABASE_URL':self.url,'SUPABASE_PUBLISHABLE_KEY':key}),(self.url,key))
    def test_secret_and_service_role_are_rejected(self):
        payload = base64.urlsafe_b64encode(json.dumps({'role':'service_role'}).encode()).decode().rstrip('=')
        for key in ['sb_secret_'+'a'*30, 'header.'+payload+'.signature']:
            with self.assertRaises(ValueError): validate({'SUPABASE_URL':self.url,'SUPABASE_PUBLISHABLE_KEY':key})
    def test_wrong_host_and_http_are_rejected(self):
        for url in ['http://example-project.supabase.co','https://supabase.co.attacker.example','https://user@example-project.supabase.co']:
            with self.assertRaises(ValueError): validate({'SUPABASE_URL':url,'SUPABASE_PUBLISHABLE_KEY':'sb_publishable_'+'a'*30})

if __name__ == '__main__': unittest.main()
