
all: orensemble
	make -C orensemble
	mv orensemble/boostrank-predict .
	mv orensemble/boostrank-train .

orensemble:
	tar xzf orensemble.tar.gz

clean:
	rm -Rf orensemble
