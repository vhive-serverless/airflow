git clone --depth=1 https://github.com/vhive-serverless/vhive.git
cd vhive
mkdir -p /tmp/vhive-logs
./scripts/cloudlab/setup_node.sh stock-only  # this might print errors, ignore them

sudo screen -d -m containerd
./scripts/cluster/create_one_node_cluster.sh stock-only
cd ..

sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo \
    "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo chmod 666 /var/run/docker.sock

sudo apt install -y python3-pip
pip install apache-airflow-client grpcio grpcio-tools

curl -sS https://webi.sh/k9s | sh
source ~/.config/envman/PATH.env