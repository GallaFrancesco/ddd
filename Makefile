DOT=bdd.dot robdd.dot x.dot y.dot apply_union_robdd.dot 

all:
	@dub build
release:
	@dub build -b release
test:
	@dub test; for df in ${DOT}; do echo -n "[dot] Processing: $$df... "; ./dot2pdf.sh $$df; done;
upgrade:
	@dub upgrade
clean:
	@rm -f ddd bdd.dot bdd.pdf ddd-test-library
