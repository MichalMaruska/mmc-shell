INSTALL := install
BIN_INSTALL_DIR := /usr/bin
SHARED_INSTALL_DIR := /usr/share/mmc-shell/
ZSH_COMPLETIONS_DIR := /usr/share/zsh/vendor-completions

# fixme: ignore *~ files
BINFILES := $(wildcard bin/*)

all:
	echo ""

install: install-zsh
	$(INSTALL) -v -D --directory $(DESTDIR)$(BIN_INSTALL_DIR)
	for p in $(BINFILES); do \
	  $(INSTALL) --owner=root -v --mode 555 $$p $(DESTDIR)$(BIN_INSTALL_DIR) ; \
	done
	$(INSTALL) -v -D --directory $(DESTDIR)$(SHARED_INSTALL_DIR)
	for p in share/*; do \
	  $(INSTALL) --owner=root -v --mode 555 $$p $(DESTDIR)$(SHARED_INSTALL_DIR) ; \
	done



# zsh infrastructure to better use the provided commands!
install-zsh:
	$(INSTALL) -v -D --directory $(DESTDIR)$(ZSH_COMPLETIONS_DIR)
#	for dir in $$(cd  zsh;find . -mindepth 1  -type d ); do \
#		mkdir -vp $(DESTDIR)$(ZSH_COMPLETIONS_DIR)/$$dir; done
	for file in $$(cd  zsh/Completion; find . -type f ); do \
		install -v --mode 444 zsh/Completion/$$file $(DESTDIR)$(ZSH_COMPLETIONS_DIR)/$$file; done

clean:

git-clean:
	git clean -f -d -x
