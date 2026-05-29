compile:
	@-mkdir -p output/info
	-@bsc -systemc -g mkAdder -vdir output -bdir output -info-dir output/info -no-warn-action-shadowing Adder.bsv

link:
	-@bsc -systemc -e mkAdder -bdir output -vdir output -info-dir output/info
	@-mkdir -p output/gen
	@-mv -f *.h *.cxx *.o output/gen/ 2>/dev/null || true

all: compile link

clean:
	@-rm -rf output

.DEFAULT_GOAL := all
