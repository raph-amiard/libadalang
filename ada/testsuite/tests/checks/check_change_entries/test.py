from __future__ import absolute_import, division, print_function

import os
import subprocess
from utils import LAL_ROOTDIR


subprocess.check_call([
    os.path.join(LAL_ROOTDIR, 'user_manual', 'changes', 'process_changes.py'),
    'rst',
    '--quiet'
])