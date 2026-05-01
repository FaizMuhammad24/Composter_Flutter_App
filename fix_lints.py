import os
import re

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content

    # replace withOpacity(X) -> withValues(alpha: X)
    content = re.sub(r'\.withOpacity\(([^)]+)\)', r'.withValues(alpha: \1)', content)

    # replace Share.shareXFiles -> Share.share (wait, I will leave Share for now or try to fix it)
    content = content.replace('Share.shareXFiles(', 'Share.share(')

    # replace main.dart background -> surface
    if 'main.dart' in filepath:
        content = content.replace('background:', 'surface:')

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")

def main():
    for root, dirs, files in os.walk('lib'):
        for file in files:
            if file.endswith('.dart'):
                filepath = os.path.join(root, file)
                process_file(filepath)

if __name__ == '__main__':
    main()
