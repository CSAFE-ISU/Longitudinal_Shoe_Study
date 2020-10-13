# Makefile for knitr

# optionally put all RNW files to be compiled to pdf here, separated by spaces
RNW_FILES= $(wildcard *.Rnw)

TEX_FILES= $(wildcard *.tex)

RMD_FILES= $(wildcard *.Rmd)

# location of Rscript
R_HOME?=/usr/bin/Rscript

# these pdf's will be compiled from Rnw and Rmd files
PDFS= $(RNW_FILES:.Rnw=.pdf) $(TEX_FILES:.tex=.pdf)

PDFSComp= $(RNW_FILES:.Rnw=-compress.pdf)

DOCs = $(RMD_FILES:.Rmd=.docx)

# these R files will be untangled from RNoWeb files
R_FILES= $(RNW_FILES:.Rnw=-purled.R)

# Bib files
BIB_FILES = $(wildcard *.bib)

# cache and figure directories
CACHEDIR= cache
FIGUREDIR= figure
IMAGEDIR= images
DATADIR= data


.PHONY: all purled clean cleanall open
.SUFFIXES: .Rnw .pdf .R .tex .docx

# these targets will be made by default
all: $(PDFS) $(PDFSComp) $(DOCs)

# use this to create R files extracted from RNoWeb files
purled: $(R_FILES)

# these tex files will be generated from Rnw files
TEX_FILES2 = $(RNW_FILES:.Rnw=.tex)


# remove generated files except pdf and purled R files
clean:
	rm -f *.bbl *.blg *.aux *.out *.log *.spl *tikzDictionary *.fls
	rm -f $(TEX_FILES) $(TEX_FILES2)

# run the clean target then remove pdf and purled R files too
cleanall: clean
	rm -f *.synctex.gz
	rm -f $(PDFS)
	rm -f $(R_FILES)

# compile a PDF from a RNoWeb file
%.pdf: %.Rnw Makefile
	mkdir -p build
	cp $(BIB_FILES) build/
	# ln -sf $(DATADIR) build/$(DATADIR)
	$(R_HOME)/bin/Rscript\
		-e "require(knitr)" \
		-e "knitr::opts_chunk[['set']](fig.path='$(FIGUREDIR)/$*-')" \
		-e "knitr::opts_chunk[['set']](cache.path='$(CACHEDIR)/$*-')" \
		-e "knitr::knit('$*.Rnw', output='build/$*.tex')"
	#cp -r $(IMAGEDIR)/ build/$(IMAGEDIR)
	cp -r $(FIGUREDIR) build/
	latexmk --pdf -halt-on-error -output-directory=build build/$*.tex
	cp build/$*.pdf $*.pdf
	# set up latexsrc dir
	mkdir -p latexsrc
	cp $(BIB_FILES) latexsrc/
	cp -r $(FIGUREDIR) latexsrc/
	cp build/$*.tex latexsrc/$*.tex
	gzip -o latexsrc.zip latexsrc

%-compress.pdf: %.pdf
	~/bin/compress_pdf $< $@


%.pdf: %.tex Makefile
	cp $*.tex build/
	latexmk --pdf -halt-on-error -output-directory=build build/$*.tex
	cp build/$*.pdf $*.pdf

# extract an R file from an RNoWeb file
%-purled.R: %.Rnw
	$(R_HOME)/bin/Rscript\
		-e "require(knitr)" \
		-e "knitr::opts_chunk[['set']](fig.path='$(FIGUREDIR)/$*-')" \
		-e "knitr::opts_chunk[['set']](cache.path='$(CACHEDIR)/$*-')" \
		-e "knitr::purl('$*.Rnw', '$*-purled.R')"

%.html: %.Rmd
	@echo "$< -> $@"
	@Rscript -e "rmarkdown::render('$<')"

%.docx: %.Rmd
	@echo "$< -> $@"
	@Rscript -e "rmarkdown::render('$<')"

%.pdf: %.Rmd
	@echo "$< -> $@"
	@Rscript -e "rmarkdown::render('$<')"

# open all PDF's
open:
	open -a Skim $(PDFS)

# remove generated files except pdf and purled R files
clean:
	rm -f build/*.blg build/*.out *.log build/*.spl build/*.tikzDictionary build/*.fls build/*.fdb_latexmk
