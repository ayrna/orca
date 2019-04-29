import subprocess

cmd = ["jupyter","nbconvert", "--to", "script", "orca_tutorial_1.ipynb"]
returncode = subprocess.call(cmd)

print("returncode:" + str(returncode))

if returncode != 0:
	exit(returncode)

cmd = ["octave-cli", "orca_tutorial_1.m"]
returncode = subprocess.call(cmd)
print("returncode:" + str(returncode))

exit(returncode)
