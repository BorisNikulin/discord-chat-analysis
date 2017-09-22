
R_OPTS =

all: README.md

README.md:
	R ${R_OPTS} -e 'rmarkdown::render("README.Rmd")'

clean:
	rm README.md
	rm README.html
	rm -r README_files/
