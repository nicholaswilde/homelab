import unittest
import os
import tempfile
import sys

# Add the scripts directory to the path so we can import the module we're about to create
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

try:
    from rotate_secret import generate_secret, update_env
except ImportError:
    # If the file doesn't exist yet, we'll define placeholders so the test can run and fail
    def generate_secret(length): pass
    def update_env(path, key, value): pass

class TestRotateSecret(unittest.TestCase):
    def test_generate_secret_length(self):
        secret = generate_secret(32)
        self.assertEqual(len(secret), 32)

    def test_generate_secret_is_string(self):
        secret = generate_secret(16)
        self.assertIsInstance(secret, str)

    def test_update_env_adds_variable(self):
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as tmp:
            tmp.write("EXISTING_VAR=old_value\n")
            tmp_path = tmp.name
        
        try:
            update_env(tmp_path, "NEW_VAR", "new_value")
            with open(tmp_path, 'r') as f:
                content = f.read()
            self.assertIn("NEW_VAR=new_value", content)
            self.assertIn("EXISTING_VAR=old_value", content)
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def test_update_env_updates_variable(self):
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as tmp:
            tmp.write("TARGET_VAR=old_value\n")
            tmp_path = tmp.name
        
        try:
            update_env(tmp_path, "TARGET_VAR", "updated_value")
            with open(tmp_path, 'r') as f:
                content = f.read()
            self.assertIn("TARGET_VAR=updated_value", content)
            self.assertNotIn("TARGET_VAR=old_value", content)
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

if __name__ == '__main__':
    unittest.main()
