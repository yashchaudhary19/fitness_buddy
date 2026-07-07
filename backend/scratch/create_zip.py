import os
import zipfile

def zip_backend():
    workspace_dir = r"c:\Users\chaud\OneDrive\Desktop\fitness"
    backend_dir = os.path.join(workspace_dir, "backend")
    output_zip = os.path.join(workspace_dir, "backend_update.zip")
    
    # Exclude list
    exclude_dirs = {".venv", ".pytest_cache", "__pycache__", "tests"}
    exclude_files = {"nutritrack.db", "backend.log"}
    
    print(f"Creating ZIP file: {output_zip}...")
    with zipfile.ZipFile(output_zip, 'w', zipfile.ZIP_DEFLATED) as zipf:
        for root, dirs, files in os.walk(backend_dir):
            # Modify dirs in-place to exclude unwanted subdirectories
            dirs[:] = [d for d in dirs if d not in exclude_dirs]
            
            for file in files:
                if file in exclude_files or file.endswith(".pyc"):
                    continue
                file_path = os.path.join(root, file)
                # Calculate archive name relative to backend_dir
                arcname = os.path.relpath(file_path, backend_dir)
                zipf.write(file_path, arcname)
                
    print("ZIP file created successfully!")

if __name__ == "__main__":
    zip_backend()
