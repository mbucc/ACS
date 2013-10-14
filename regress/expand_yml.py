import yaml
import string
import sys

def fn_to_yml(fn):
    with open(fn, 'r') as f:
        data = yaml.load(f.read())
    return data

def expand(s, data):
    return "$" in str(s) \
        and expand(string.Template(str(s)).substitute(data), data) \
        or  s

raw = fn_to_yml(sys.argv[1])
expanded = {k: expand(v, raw) for k, v in raw.items()}
print '\n'.join( ['%s=%s' % i for i in expanded.items()])
