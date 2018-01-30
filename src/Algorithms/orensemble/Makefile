all: 
	make -e -C orensemble
	mv orensemble/boostrank-predict .
	mv orensemble/boostrank-train .

octave: all

untar:
	#tar xzf orensemble.tar.gz

clean:
	rm -f orensemble/*~ orensemble/*.o orensemble/*.obj
