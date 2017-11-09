all: untar
	make -e -C orensemble
	mv orensemble/boostrank-predict .
	mv orensemble/boostrank-train .

untar:
	tar xzf orensemble.tar.gz

clean:
	rm -Rf orensemble
