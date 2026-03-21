import os
import re

lib_dir = r"c:\Users\Admin\Desktop\projectclg\lib"

# regex patterns and replacements
patterns = [
    (r'(fontSize:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.sp'),
    (r'(height:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.h'),
    (r'(width:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.w'),
    (r'(radius:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.r'),
    (r'(circular\s*\(\s*)([0-9]+(?:\.[0-9]+)?)(\s*\))(?![\.a-zA-Z])', r'\1\2.r\3'),
    (r'(all\s*\(\s*)([0-9]+(?:\.[0-9]+)?)(\s*\))(?![\.a-zA-Z])', r'\1\2.sp\3'), # padding all can be used for both w and h, w or sp? we can use .r or .w. Let's use .w
    (r'(horizontal:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.w'),
    (r'(vertical:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.h'),
    (r'(top:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.h'),
    (r'(bottom:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.h'),
    (r'(left:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.w'),
    (r'(right:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.w'),
    (r'(BlurRadius:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.r'),
    (r'(spreadRadius:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.r'),
    (r'(blurRadius:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.r'),
    (r'(offset:\s*Offset\s*\(\s*[-0-9.]+\s*,\s*)([-0-9.]+)(?:\s*\))(?![\.a-zA-Z])', r'\g<1>\2.h)'), # Offset(x, y) - tricky, let's skip Offset for now or be simple.
    (r'(Offset\s*\(\s*)([-0-9.]+)(\s*,\s*)([-0-9.]+)(\s*\))', r'\1\2.w\3\4.h\5'),
    (r'(Size\s*\(\s*)([-0-9.]+)(\s*,\s*)([-0-9.]+)(\s*\))', r'\1\2.w\3\4.h\5'),
    (r'(iconSize:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.sp'),
    (r'(size:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.sp'),
    (r'(strokeWidth:\s*)([0-9]+(?:\.[0-9]+)?)(?![\.a-zA-Z])', r'\1\2.w'),
]

# specific fix for padding all -> .w
patterns[5] = (r'(all\s*\(\s*)([0-9]+(?:\.[0-9]+)?)(\s*\))(?![\.a-zA-Z])', r'\1\2.w\3')

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    original_content = content
    for pattern, replacement in patterns:
        content = re.sub(pattern, replacement, content)
    
        # Also handle standard cases where dart wants double? `const` will break if we use .w or .h on constants in padding.
        # But wait, .w and .h are not constant. 
        # So we also need to remove 'const ' keyword near EdgeInsets or others if modified.
    
    # Let's completely remove 'const ' keyword from lines that now have .w, .h, .sp, .r
    lines = content.split('\n')
    new_lines = []
    for line in lines:
        if ('.w' in line or '.h' in line or '.sp' in line or '.r' in line) and 'const ' in line:
            # remove const from the line if it appears before widgets or EdgeInsets
            # This is a bit brute force but works mostly in UI code
            line = line.replace('const SizedBox', 'SizedBox')
            line = line.replace('const EdgeInsets', 'EdgeInsets')
            line = line.replace('const BorderRadius', 'BorderRadius')
            line = line.replace('const Radius', 'Radius')
            line = line.replace('const Text', 'Text')
            line = line.replace('const Padding', 'Padding')
            line = line.replace('const Align', 'Align')
            line = line.replace('const Center', 'Center')
            line = line.replace('const TextStyle', 'TextStyle')
            line = line.replace('const Icon', 'Icon')
            line = line.replace('const BoxConstraints', 'BoxConstraints')
            line = line.replace('const ShapeDecoration', 'ShapeDecoration')
            line = line.replace('const DecorationImage', 'DecorationImage')
            line = line.replace('const Border', 'Border')
            line = line.replace('const BorderSide', 'BorderSide')
            line = line.replace('const Offset', 'Offset')
            line = line.replace('const Spacer', 'Spacer')
            line = line.replace('const Divider', 'Divider')
            line = line.replace('const CircularProgressIndicator', 'CircularProgressIndicator')
            line = line.replace('const LinearProgressIndicator', 'LinearProgressIndicator')
            line = line.replace('const ', '') # Last resort
        new_lines.append(line)
    content = '\n'.join(new_lines)
    
    if content != original_content and filepath.endswith('.dart'):
        # also add import if missing
        if 'import \'package:flutter_screenutil/flutter_screenutil.dart\';' not in content:
            if 'import \'package:flutter/material.dart\';' in content:
                content = content.replace('import \'package:flutter/material.dart\';', 'import \'package:flutter/material.dart\';\nimport \'package:flutter_screenutil/flutter_screenutil.dart\';')
            elif 'import \'package:flutter/cupertino.dart\';' in content:
                content = content.replace('import \'package:flutter/cupertino.dart\';', 'import \'package:flutter/cupertino.dart\';\nimport \'package:flutter_screenutil/flutter_screenutil.dart\';')
            else:
                content = 'import \'package:flutter_screenutil/flutter_screenutil.dart\';\n' + content

    if content != original_content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {filepath}")

for root, dirs, files in os.walk(lib_dir):
    for f in files:
        if f.endswith('.dart') and f != 'main.dart':
            process_file(os.path.join(root, f))
