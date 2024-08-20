# LINUX
ARCH_LIBDIR ?= /usr/lib/x86_64-linux-gnu

# NOTE: MUST BE "RELATIVE PATH" TO TEE BINARY
ENCLAVEDIR ?= .
SELF_EXE = ${ENCLAVEDIR}/bin/op-batcher

SGX ?= 1

.PHONY: all
all: batcher.manifest
ifeq ($(SGX),1)
all: batcher.manifest.sgx batcher.sig 
endif

GRAMINE_LOG_LEVEL = debug
MANIFEST_FILE = batcher.manifest.template

batcher.manifest: $(MANIFEST_FILE)
	gramine-manifest \
		-Dlog_level=$(GRAMINE_LOG_LEVEL) \
		-Darch_libdir=$(ARCH_LIBDIR) \
		-Dself_exe=$(SELF_EXE) \
		-Denclave_dir=$(ENCLAVEDIR) \
		$< $@

batcher.manifest.sgx batcher.sig: batcher_sign
	@:

.INTERMEDIATE: batcher_sign
batcher_sign: batcher.manifest
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
	$(GRAMINE) batcher \
	    --l2-eth-rpc=http://localhost:8545 \
	    --rollup-rpc=http://localhost:8547 \
	    --poll-interval=1s \
	    --sub-safety-margin=6 \
	    --num-confirmations=1 \
	    --safe-abort-nonce-too-low-count=3 \
	    --resubmission-timeout=30s \
	    --rpc.addr=0.0.0.0 \
	    --rpc.port=8548 \
	    --rpc.enable-admin \
	    --max-channel-duration=1 \
	    --l1-eth-rpc=https://rpc.sepolia.org \
	    --private-key=0x39828354bd198ccaf3d49d3f3a9cf685d5d222ab22152747283061d4f4c83a6e









http.api=web3,debug,eth,txpool,net,engine \
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
	  --datadir=/datadir \
	  --authrpc.jwtsecret=/jwt.txt \
	  --gcmode=archive

.PHONY: clean
clean:
	$(RM) -rf $(ENCLAVEDIR)/*.token $(ENCLAVEDIR)/*.sig $(ENCLAVEDIR)/*.manifest.sgx $(ENCLAVEDIR/)*.manifest $(ENCLAVEDIR)/result-* $(ENCLAVEDIR)/*.log

.PHONY: distclean
distclean: clean
	$(RM) -rf target/ Cargo.lock
