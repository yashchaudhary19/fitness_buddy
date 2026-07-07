import os

search_dir = r"c:\Users\chaud\OneDrive\Desktop\fitness\backend"
terms = ["urlopen", "urllib", "urllib2", "request.get", "urllib.request"]

found = []
for root, dirs, files in os.walk(search_dir):
    if ".venv" in root or "__pycache__" in root or ".pytest_cache" in root:
        continue
    for file in files:
        if file.endswith(".py"):
            file_path = os.path.join(root, file)
            try:
                with open(file_path, "r", encoding="utf-8") as f:
                    content = f.read()
                for term in terms:
                    if term in content:
                        found.append((file_path, term))
            except Exception as e:
                pass

print("Search results:")
for path, term in found:
    print(f"File: {path} | Term: {term}")
