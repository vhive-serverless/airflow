git clone --depth=1 https://github.com/vhive-serverless/vhive.git
cd vhive
mkdir -p /tmp/vhive-logs
./scripts/cloudlab/setup_node.sh stock-only  # this might print errors, ignore them

sudo screen -d -m containerd
./scripts/cluster/create_one_node_cluster.sh stock-only
cd ..