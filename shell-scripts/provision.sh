# Parâmetros
export AWS_DEFAULT_REGION=us-east-1
export EKSCLUSTERNAME=eks-cluster
export EMRCLUSTERNAME=el-emr-on-$EKSCLUSTERNAME
export ROLENAME=emr-on-eks-job-execution-policy
export OUTPUTS3BUCKET=emr-on-eks-runs
export ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)

# Máquina (como escolher a opção spot?) (como deixar o cluster elástico?)
EKSCTL_PARAM="--nodes 2 --node-type t3.xlarge"

# Instalando eksctl
curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
sudo mv /tmp/eksctl /usr/local/bin

# Atualizando o AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip" 
unzip -q -o /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install --update

# Instalando kubectl 
curl -L "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" \
    -o "/tmp/kubectl" 
chmod +x /tmp/kubectl
sudo mv /tmp/kubectl /usr/local/bin

# Provisionando cluster eks usando instâncias do ec2
eksctl create cluster --name $EKSCLUSTERNAME --with-oidc --zones ${AWS_DEFAULT_REGION}a,${AWS_DEFAULT_REGION}b $EKSCTL_PARAM
aws eks update-kubeconfig --name $EKSCLUSTERNAME

# Criando um namespace kubernetes ('emr' para EMR)
kubectl create namespace emr

# Aguarda o provisionamento e libera os logs
# Libera o acesso do cluster ao Amazon EMR on EKS na namespace 'emr'
eksctl create iamidentitymapping --cluster $EKSCLUSTERNAME --namespace "emr" --service-name "emr-containers"
eksctl utils update-cluster-logging --cluster $EKSCLUSTERNAME --enable-types all --approve

# Atribui política ao container
aws iam attach-role-policy --role-name $ROLENAME --policy-arn arn:aws:iam::$ACCOUNTID:policy/$ROLENAME
aws emr-containers update-role-trust-policy --cluster-name $EKSCLUSTERNAME --namespace emr --role-name $ROLENAME

# Cria cluster virtual do EMR
aws emr-containers create-virtual-cluster --name $EMRCLUSTERNAME \
    --container-provider '{
        "id": "'$EKSCLUSTERNAME'",
        "type": "EKS",
        "info": { "eksInfo": { "namespace": "emr" } }
    }'

echo "Executado: Provision"