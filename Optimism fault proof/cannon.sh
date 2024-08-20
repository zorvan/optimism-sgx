#!/bin/bash
set -euo pipefail
SCRIPTS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" > /dev/null && pwd )"
cd "${SCRIPTS_DIR}"

OUTPUT_ORACLE=0xdfe97868233d1aa22e815a266982f2cf17685a27
L1_API=https://ethereum-mainnet.core.chainstack.com/8c5d7d503fcdbaa63dbe42ab0e602cc7 #https://rpc.flashbots.net/fast #https://eth-mainnet.g.alchemy.com/v2/lRT76_IURx2QLDhfGoqN5-nHl37C2Fx6
L2_API=https://nd-840-223-668.p2pify.com/5a6c8f28a10ba65b211b5d18b7f6121c #https://optimism-mainnet.core.chainstack.com/4b49d51a6c378b7461d7f71378f73fdd
RPC_KIND=debug_geth
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
L2_CLAIM=${4:-$OUTPUT_COMPONENTS[0]}
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

./bin/cannon run   --pprof.cpu  --info-at '%10000000'  --proof-at %1000000000  --input ./state.json \
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
	     --log.format terminal \
	     --log.color \
	     --log.level trace > Cannon.log 2>&1 &

	     
