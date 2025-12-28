import os

def check_taskfiles():
    missing = []
    for root, dirs, files in os.walk('.'):
        if 'Taskfile.yml' in files:
            path = os.path.join(root, 'Taskfile.yml')
            with open(path, 'r') as f:
                content = f.read()
                if 'encrypt:' in content and 'verify-secrets:' not in content:
                    missing.append(path)
    return missing

if __name__ == "__main__":
    missing = check_taskfiles()
    if missing:
        print("Files missing verify-secrets:")
        for m in missing:
            print(m)
    else:
        print("All Taskfiles with 'encrypt' have 'verify-secrets'.")
