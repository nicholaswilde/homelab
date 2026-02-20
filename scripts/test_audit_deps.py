import unittest
import os
import tempfile
import sys
from unittest.mock import patch, MagicMock

# Add the scripts directory to the path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

# Import placeholders for TDD
try:
    from audit_deps import scan_compose_files, extract_images, get_registry, get_latest_tag
except ImportError:
    # Placeholders for initial failure
    def scan_compose_files(root_dir): pass
    def extract_images(file_path): pass
    def get_registry(image_name): pass
    def get_latest_tag(image_name): pass

class TestAuditDeps(unittest.TestCase):
    def test_scan_compose_files(self):
        # Create dummy directory structure
        with tempfile.TemporaryDirectory() as tmp_dir:
            app1_dir = os.path.join(tmp_dir, "app1")
            os.makedirs(app1_dir)
            compose1 = os.path.join(app1_dir, "compose.yaml")
            with open(compose1, 'w') as f: f.write("services:\n  web: image: nginx:1.21")
            
            app2_dir = os.path.join(tmp_dir, "app2")
            os.makedirs(app2_dir)
            compose2 = os.path.join(app2_dir, "docker-compose.yml") # Test both naming conventions
            with open(compose2, 'w') as f: f.write("services:\n  db: image: postgres:14")
            
            # Non-compose file
            other_file = os.path.join(tmp_dir, "README.md")
            with open(other_file, 'w') as f: f.write("test")
            
            files = scan_compose_files(tmp_dir)
            if files is None: self.fail("scan_compose_files returned None")
            self.assertEqual(len(files), 2)
            self.assertIn(compose1, files)
            self.assertIn(compose2, files)

    def test_extract_images(self):
        content = """
services:
  web:
    image: nginx:1.21.6
  db:
    image: postgres:14-alpine
  cache:
    image: redis
"""
        with tempfile.NamedTemporaryFile(mode='w+', delete=False) as tmp:
            tmp.write(content)
            tmp_path = tmp.name
        
        try:
            images = extract_images(tmp_path)
            if images is None: self.fail("extract_images returned None")
            self.assertEqual(len(images), 3)
            self.assertIn("nginx:1.21.6", images)
            self.assertIn("postgres:14-alpine", images)
            self.assertIn("redis", images)
        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)

    def test_get_registry(self):
        self.assertEqual(get_registry("nginx:1.21"), "dockerhub")
        self.assertEqual(get_registry("grafana/grafana:latest"), "dockerhub")
        self.assertEqual(get_registry("ghcr.io/linuxserver/wireguard"), "ghcr")
        self.assertEqual(get_registry("registry.example.com/myapp:1.0"), "unknown")

    @patch('requests.get')
    def test_get_latest_tag_dockerhub(self, mock_get):
        # Mocking Docker Hub API response
        mock_get.return_value.status_code = 200
        mock_get.return_value.json.return_value = {"tags": ["1.21.6", "1.21.5", "1.20.0"]}
        
        # Note: In real implementation, we might need a separate mock for token auth
        tag = get_latest_tag("nginx")
        self.assertEqual(tag, "1.21.6")

if __name__ == '__main__':
    unittest.main()
