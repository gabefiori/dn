OUTPUT = dn
TEST_OUTPUT = dn-test

BASE_BUILD = odin build src/ -out:$(OUTPUT)

INSTALL_PATH = /usr/local/bin/$(OUTPUT)

build:
	 $(BASE_BUILD) -o:speed
	
build-debug:
	 $(BASE_BUILD) -debug

install:
	$(MAKE) build && { [ -f $(INSTALL_PATH) ] && sudo rm $(INSTALL_PATH); } ; sudo ln -s $(CURDIR)/$(OUTPUT) $(INSTALL_PATH)

test:
	odin test src/ -out:$(TEST_OUTPUT)

run:
	./$(OUTPUT)
