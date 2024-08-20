# LINUX
ARCH_LIBDIR ?= /usr/lib/x86_64-linux-gnu

# NOTE: MUST BE "RELATIVE PATH" TO TEE BINARY
ENCLAVEDIR ?= .
SELF_EXE = ${ENCLAVEDIR}/bin/geth

SGX ?= 1

.PHONY: all
all: geth.manifest
ifeq ($(SGX),1)
all: geth.manifest.sgx geth.sig 
endif

GRAMINE_LOG_LEVEL = debug
MANIFEST_FILE = geth.manifest.template

geth.manifest: $(MANIFEST_FILE)
	gramine-manifest \
		-Dlog_level=$(GRAMINE_LOG_LEVEL) \
		-Darch_libdir=$(ARCH_LIBDIR) \
		-Dself_exe=$(SELF_EXE) \
		-Denclave_dir=$(ENCLAVEDIR) \
		$< $@

geth.manifest.sgx geth.sig: geth_sign
	@:

.INTERMEDIATE: geth_sign
geth_sign: geth.manifest
	gramine-sgx-sign \
		--manifest $< \
		--output $<.sgx

ifeq ($(SGX),)
GRAMINE = gramine-direct
else
GRAMINE = gramine-sgx
endif 

.PHONY: start-gramine-server
start-gramine-server: all
	$(GRAMINE) geth \
	  --http \
	  --http.corsdomain="*" \
	  --http.vhosts="*" \
	  --http.addr=0.0.0.0 \
	  --http.api=web3,debug,eth,txpool,net,engine \
	  --ws \
	  --ws.addr=0.0.0.0 \
	  --ws.port=8546 \
	  --ws.origins="*" \
	  --ws.api=debug,eth,txpool,net,engine \
	  --syncmode=full \
	  --nodiscover \
	  --maxpeers=0 \
	  --networkid=42069 \
	  --authrpc.vhosts="*" \
	  --authrpc.addr=0.0.0.0 \
	  --authrpc.port=8551 \
	  --rollup.disabletxpoolgossip=true \
	  --datadir=./datadir \
	  --authrpc.jwtsecret=./jwt.txt \
	  --gcmode=archive \
	  --verbosity=5

.PHONY: clean
clean:
	$(RM) -rf $(ENCLAVEDIR)/*.token $(ENCLAVEDIR)/*.sig $(ENCLAVEDIR)/*.manifest.sgx $(ENCLAVEDIR/)*.manifest $(ENCLAVEDIR)/result-* $(ENCLAVEDIR)/*.log

.PHONY: distclean
distclean: clean
	$(RM) -rf target/ Cargo.lock
