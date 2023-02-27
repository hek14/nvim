import os
import time
from argparse import ArgumentParser
parser = ArgumentParser()
parser.add_argument("--cwd",type=str)
parser.add_argument("--modules",type=str)

args = parser.parse_args()
runtime_dir = args.cwd
os.chdir(runtime_dir)

modules = args.modules.strip().split(' ')
start = time.time()
results = []
for m in modules:
    m = m.strip()
    try:
        module = __import__(m)
        print(module.__file__,runtime_dir)
        if m.find(runtime_dir)>0:
            results.append('local')
        else:
            results.append('global')
            
    except ModuleNotFoundError:
        print(m)
        __import__(m)
        results.append('false')



print(f"spent: {time.time()-start} seconds")
print(results)
