DOT=bdd.dot

all:
	@dub build
release:
	@dub build -b release
test:
	@dub test; echo -n "[dot] Processing: ${DOT}... "; ./dot2pdf.sh ${DOT}
upgrade:
	@dub upgrade
clean:
	@rm -f ddd bdd.dot bdd.pdf ddd-test-library
