PAPER := aaronson_ambainis_paper

.PHONY: all clean

# Uses latexmk if it is installed, and Tectonic otherwise.
all:
	@if command -v latexmk >/dev/null 2>&1; then \
		latexmk -pdf $(PAPER).tex; \
	else \
		tectonic $(PAPER).tex; \
	fi

clean:
	@if command -v latexmk >/dev/null 2>&1; then latexmk -C $(PAPER).tex; fi
	rm -f $(PAPER).aux $(PAPER).log $(PAPER).out
