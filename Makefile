all:
	@dub build
test:
	@dub test
	@./dot2pdf.sh bdd.dot
clean:
	@rm -f ddd bdd.dot bdd.pdf ddd-test-library
