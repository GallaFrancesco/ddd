DOT=bdd.dot robdd.dot x.dot y.dot apply_romdd.dot 

all:
	@dub build
release:
	@dub build -b release
test:
	@dub test; for df in ${DOT}; do echo -n "[dot] Processing: dot/$$df... "; ./dot2pdf.sh dot/$$df; done;
upgrade:
	@dub upgrade
clean:
	@rm -f ddd bdd.dot bdd.pdf ddd-test-library
