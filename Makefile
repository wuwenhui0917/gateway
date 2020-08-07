TO_INSTALL = api bin conf dashboard gateway install
GATEWAY_HOME ?= /usr/local/gateway
GATEWAY_BIN ?= /usr/local/bin/gateway
GATEWAY_HOME_PATH = $(subst /,\\/,$(GATEWAY_HOME))

.PHONY: test install show
init-config:
	@ test -f conf/nginx.conf   || (cp conf/nginx.conf.example conf/nginx.conf && echo "copy nginx.conf")
	@ test -f conf/gateway.conf  || (cp conf/gateway.conf.example conf/gateway.conf && echo "copy gateway.conf")

test:
	@echo "to be continued..."

install:init-config
	@rm -rf $(GATEWAY_BIN)
	@rm -rf $(GATEWAY_HOME)
	@mkdir -p $(GATEWAY_HOME)

	@for item in $(TO_INSTALL) ; do \
		cp -a $$item $(GATEWAY_HOME)/; \
	done;

	@cat $(GATEWAY_HOME)/conf/nginx.conf | sed "s/..\/\?.lua;\/usr\/local\/lor\/\?.lua;;/"$(GATEWAY_HOME_PATH)"\/\?.lua;\/usr\/local\/lor\/?.lua;;/" > $(GATEWAY_HOME)/conf/new_nginx.conf
	@rm $(GATEWAY_HOME)/conf/nginx.conf
	@mv $(GATEWAY_HOME)/conf/new_nginx.conf $(GATEWAY_HOME)/conf/nginx.conf

	@echo "#!/usr/bin/env resty" >> $(GATEWAY_BIN)
	@echo "package.path=\"$(GATEWAY_HOME)/?.lua;;\" .. package.path" >> $(GATEWAY_BIN)
	@echo "require(\"bin.main\")(arg)" >> $(GATEWAY_BIN)
	@chmod +x $(GATEWAY_BIN)
	@echo "GATEWAY installed."
	$(GATEWAY_BIN) help

show:
	$(GATEWAY_BIN) help
