# Parâmetros
export EKSCLUSTERNAME=eks-cluster
export EMRCLUSTERNAME=el-emr-on-$EKSCLUSTERNAME
export EMRCLUSTERID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name == '${EMRCLUSTERNAME}' && state == 'RUNNING'].id" --output text)

# clean up resources
aws emr-containers delete-virtual-cluster --id $EMRCLUSTERID
eksctl delete cluster --name=$EKSCLUSTERNAME
