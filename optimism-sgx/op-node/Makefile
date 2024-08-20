# LINUX
ARCH_LIBDIR ?= /usr/lib/x86_64-linux-gnu

# NOTE: MUST BE "RELATIVE PATH" TO TEE BINARY
ENCLAVEDIR ?= .
SELF_EXE = ${ENCLAVEDIR}/bin/op-node

SGX ?= 1

.PHONY: all
all: node.manifest
ifeq ($(SGX),1)
all: node.manifest.sgx node.sig 
endif

GRAMINE_LOG_LEVEL = debug
MANIFEST_FILE = node.manifest.template

node.manifest: $(MANIFEST_FILE)
	gramine-manifest \
		-Dlog_level=$(GRAMINE_LOG_LEVEL) \
		-Darch_libdir=$(ARCH_LIBDIR) \
		-Dself_exe=$(SELF_EXE) \
		-Denclave_dir=$(ENCLAVEDIR) \
		$< $@

node.manifest.sgx node.sig: node_sign
	@:

.INTERMEDIATE: node_sign
node_sign: node.manifest
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
	$(GRAMINE) node \
	--l2=http://localhost:8551 \
	--l2.jwt-secret=./jwt.txt \
	--sequencer.enabled \
	--sequencer.l1-confs=5 \
	--verifier.l1-confs=4 \
	--rollup.config=./rollup.json \
	--rpc.addr=0.0.0.0 \
	--rpc.port=8547 \
	--p2p.disable \
	--rpc.enable-admin \
	--p2p.sequencer.key=0xd1456175520a03414c219c6e7ec53942a93e959ee65d7a833d8cf2c9222b69ad \
	--l1=https://rpc.sepolia.org \
	--l1.rpckind=standard

.PHONY: clean
clean:
	$(RM) -rf $(ENCLAVEDIR)/*.token $(ENCLAVEDIR)/*.sig $(ENCLAVEDIR)/*.manifest.sgx $(ENCLAVEDIR/)*.manifest $(ENCLAVEDIR)/result-* $(ENCLAVEDIR)/*.log

.PHONY: distclean
distclean: clean
	$(RM) -rf target/ Cargo.lock
