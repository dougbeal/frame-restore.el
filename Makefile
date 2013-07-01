EMACS ?= emacs
EMACSFLAGS =
CARTON = carton

# Export Emacs to recipes
export EMACS

SRCS = frame-restore.el
OBJECTS = $(SRCS:.el=.elc)

.PHONY: compile
compile : $(OBJECTS)

.PHONY: clean-all
clean-all : clean clean-elpa

.PHONY: clean
clean :
	rm -f $(OBJECTS)

.PHONY: clean-elpa
clean-elpa:
	rm -rf elpa

%.elc : %.el elpa
	$(CARTON) exec $(EMACS) -Q --batch $(EMACSFLAGS) -f batch-byte-compile $<

elpa : Carton
	$(CARTON) install
