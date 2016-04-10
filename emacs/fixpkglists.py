#!/usr/bin/python
# I do not understand the insanities of Emacs Lisp.

import sys
data=sorted(sys.stdin.read().replace('\n', '').replace('\\', '').replace('"', '').split())
tabbed = ['\t' + name for name in data]
print '"\t\\\n'+ '\t\\\n'.join(tabbed) + '\t\\\n"'
