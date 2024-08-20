apt update
apt upgrade -y

# Node.js
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc 
nvm install --lts

# Install pnpm
curl -fsSL https://get.pnpm.io/install.sh | sh -
source /root/.bashrc

# Install Foundry
apt install jq -y
curl -L https://foundry.paradigm.xyz | bash
source /root/.bashrc
foundryup

# Build Node
git clone https://github.com/ethereum-optimism/optimism.git
cd optimism
pnpm install
pnpm build

# Install Golang
# GO-VERSION=1.21.1
curl -OL https://golang.org/dl/go1.21.1.linux-amd64.tar.gz
sudo tar -C /usr/local -xvf go1.21.1.linux-amd64.tar.gz
echo "export PATH=$PATH:/usr/local/go/bin" >> ~/.profile
source ~/.profile
rm go1.21.1.linux-amd64.tar.gz

# Build Geth
git clone https://github.com/ethereum-optimism/op-geth.git
cd op-geth
make geth

# Create shared secret
openssl rand -hex 32 > jwt.txt

# Download L2 snapshot (2TB)
# SNAPSHOT=10-02-2024
# STORAGE=/mnt/block-volume/
apt install aria2 lz4 -y
aria2c -x 16 -s 16 -k100M -d /mnt/block-volume/ https://r2-snapshots.fastnode.io/op/op-10-02-2024-full.tar.lz4
cd /mnt/block-volume/
lz4 -d /mnt/block-volume/op-10-02-2024-full.tar.lz4 -c | tar xvf -

# Start Op-Geth
cd ~/optimism/op-geth
nohup ./build/bin/geth \
  --http \
  --http.port=8545 \
  --http.addr=localhost \
  --authrpc.addr=localhost \
  --authrpc.jwtsecret=./jwt.txt \
  --verbosity=3 \
  --rollup.sequencerhttp=https://mainnet-sequencer.optimism.io/ \
  --op-network=op-mainnet \
  --datadir=/mnt/block-volume/geth > op-geth.log 2>&1 &

# Start Op-Node
# Node Providers : https://github.com/arddluma/awesome-list-rpc-nodes-providers?tab=readme-ov-file#ethereum
cd ~/optimism/op-node
cp ../op-geth/jwt.txt .
nohup ./bin/op-node \
  --l1=https://ethereum-rpc.publicnode.com \
  --l1.rpckind=standard \
  --l1.beacon=https://ethereum-beacon-api.publicnode.com \
  --l2=ws://localhost:8551 \
  --l2.jwt-secret=./jwt.txt \
  --network=op-mainnet \
  --syncmode=execution-layer > op-node.log 2>&1 &


# Fraud Proof - Build
cd ~/optimism/op-program
make op-program

cd ~/optimism/cannon
make cannon
./bin/cannon load-elf --path=../op-program/bin/op-program-client.elf

# Fraud Proof - Run
OUTPUT_ORACLE=0xdfe97868233d1aa22e815a266982f2cf17685a27

L1_API=https://eth-mainnet.g.alchemy.com/v2/lRT76_IURx2QLDhfGoqN5-nHl37C2Fx6
L2_API="http://localhost:8545" #https://opt-mainnet.g.alchemy.com/v2/yDBuEoEsH4-znZcqG28DRzzCGYbTnCYQ
RPC_KIND=alchemy

#L1_API=https://mainnet.infura.io/v3/c37824dc4dde44e3a37ce5e4953aff5e
#L2_API=https://optimism-mainnet.infura.io/v3/c37824dc4dde44e3a37ce5e4953aff5e
#RPC_KIND=infura

DATADIR=${1:-oracledata}
L1_HEAD_NUM=${2:-latest}

echo -e "\n\n"
echo "L1 head num = $L1_HEAD_NUM"

#L1 head block hash
L1_HEAD=$(cast block --rpc-url "$L1_API" "$L1_HEAD_NUM" -f hash)
echo "L1 head = $L1_HEAD"

L1_LATEST_HEAD=$(cast block --rpc-url "$L1_API" "latest" -f hash)
echo "L1 Latest head = $L1_LATEST_HEAD"

# latest L2 output index
L2_LATEST_OUTPUT_INDEX=$(cast call --rpc-url "$L1_API" --block "$L1_LATEST_HEAD" "${OUTPUT_ORACLE}" 'latestOutputIndex()')
echo "L2 Latest Output Index = $L2_LATEST_OUTPUT_INDEX"
L2_OUTPUT_INDEX=${3:-$L2_LATEST_OUTPUT_INDEX}
echo "L2 Output Index = $L2_OUTPUT_INDEX"

# outputRoot, timestamp and l2BlockNumber
L2_OUTPUT=$(cast call --rpc-url "$L1_API" "${OUTPUT_ORACLE}" 'getL2Output(uint256) (bytes32,uint128,uint128)' "$L2_OUTPUT_INDEX")
echo "L2 Response = $L2_OUTPUT"
IFS=$'\n' OUTPUT_COMPONENTS=(${L2_OUTPUT})

#  claimed outputRoot 
L2_CLAIM=${OUTPUT_COMPONENTS[0]}
echo "L2 Claim = $L2_CLAIM"

#  L2 block number 
L2_BLOCK_NUM=$(echo "${OUTPUT_COMPONENTS[2]}" | awk '{print $1}')
echo "L2 Block Number = $L2_BLOCK_NUM"

L2_BLOCK=$(cast block --rpc-url "$L2_API" "$L2_BLOCK_NUM" -f hash)

L2_HEAD_NUM=$( echo "$L2_BLOCK_NUM - 100" | bc )
echo "L2 Head Number = $L2_HEAD_NUM"
L2_HEAD=$(cast block --rpc-url "$L2_API" "$L2_HEAD_NUM" -f hash)
echo "L2 Head  = $L2_HEAD"

# ==========================================================================================

./bin/cannon run   --pprof.cpu  --info-at '%10000000'  --proof-at never  --input ./state.json \
	     --   ../op-program/bin/op-program \
	     --server \
	     --network op-mainnet \
	     --l1 $L1_API \
	     --l2 $L2_API \
	     --l1.trustrpc \
	     --l1.rpckind $RPC_KIND \
	     --l1.head $L1_HEAD  \
	     --l2.head $L2_BLOCK  \
	     --l2.claim $L2_CLAIM \
	     --l2.blocknumber $L2_BLOCK_NUM \
	     --l2.outputroot $L2_OUTPUT \
	     --datadir $DATADIR  \
	     --log.format terminal  --log.color --log.level trace

