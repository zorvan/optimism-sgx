# LINUX
ARCH_LIBDIR ?= /usr/lib/x86_64-linux-gnu

# NOTE: MUST BE "RELATIVE PATH" TO TEE BINARY
ENCLAVEDIR ?= .
SELF_EXE = ${ENCLAVEDIR}/bin/op-proposer

SGX ?= 1

.PHONY: all
all: proposer.manifest
ifeq ($(SGX),1)
all: proposer.manifest.sgx proposer.sig 
endif

GRAMINE_LOG_LEVEL = debug
MANIFEST_FILE = proposer.manifest.template

proposer.manifest: $(MANIFEST_FILE)
	gramine-manifest \
		-Dlog_level=$(GRAMINE_LOG_LEVEL) \
		-Darch_libdir=$(ARCH_LIBDIR) \
		-Dself_exe=$(SELF_EXE) \
		-Denclave_dir=$(ENCLAVEDIR) \
		$< $@

proposer.manifest.sgx proposer.sig: proposer_sign
	@:

.INTERMEDIATE: proposer_sign
proposer_sign: proposer.manifest
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
	$(GRAMINE) proposer \
	--poll-interval=12s \
	--rpc.port=8560 \
	--rollup-rpc=http://localhost:8547 \
	--l2oo-address=0xC9bd5D2C2d38A4968a89d2D4250d55eC6Ed37C34 \
	--private-key=0x1430610f9df74496f9c1ba9a15b742f5910a9ced85d80939b8186c6e3e27a4b8 \
	--l1-eth-rpc=https://rpc.sepolia.org

.PHONY: clean
clean:
	$(RM) -rf $(ENCLAVEDIR)/*.token $(ENCLAVEDIR)/*.sig $(ENCLAVEDIR)/*.manifest.sgx $(ENCLAVEDIR/)*.manifest $(ENCLAVEDIR)/result-* $(ENCLAVEDIR)/*.log

.PHONY: distclean
distclean: clean
	$(RM) -rf target/ Cargo.lock
