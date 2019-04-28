errmsg = lasterr();
if ~isempty(errmsg)
	printf("== One or more errors ocurred during the test. Forcing exit with error code == \n")
	printf("Note: Octave might crash during the calling exit/quit while exiting. \
\nApparently this is the only way to return an error code to \
\nthe operating system.\n")
    printf("==\n")
	exit(1)
end
