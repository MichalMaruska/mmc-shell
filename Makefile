INSTALL := install
BIN_INSTALL_DIR := /usr/bin
SHARED_INSTALL_DIR := /usr/share/mmc-shell/

# fixme: ignore *~ files
BINFILES := $(wildcard bin/*)

all:
	echo ""

install: install-zsh
	$(INSTALL) -v -D --directory $(DESTDIR)$(BIN_INSTALL_DIR)
	for p in $(BINFILES); do \
	  $(INSTALL) -v -m 555 $$p $(DESTDIR)$(BIN_INSTALL_DIR) ; \
	done
	$(INSTALL) -v -D --directory $(DESTDIR)$(SHARED_INSTALL_DIR)
	for p in share/*; do \
	  $(INSTALL) -v -m 555 $$p $(DESTDIR)$(SHARED_INSTALL_DIR) ; \
	done



# zsh infrastructure to better use the provided commands!
install-zsh:
	$(INSTALL) -v -D --directory $(DESTDIR)/usr/share/zsh/site-functions/
	for dir in $$(cd  zsh;find . -mindepth 1  -type d ); do \
		mkdir -vp $(DESTDIR)/usr/share/zsh/site-functions/$$dir; done
	for file in $$(cd  zsh;find . -type f ); do \
		install -v -m 444 zsh/$$file $(DESTDIR)/usr/share/zsh/site-functions/$$file; done



clean:

git-clean:
	git clean -f -d -x

