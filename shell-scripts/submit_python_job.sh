# Parâmetros
export AWS_DEFAULT_REGION=us-east-1
export EKSCLUSTERNAME=eks-cluster
export EMRCLUSTERNAME=el-emr-on-$EKSCLUSTERNAME
export ROLENAME=emr-on-eks-job-execution-policy
export OUTPUTS3BUCKET=emr-on-eks-runs
export ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)
export EMRCLUSTERID=$(aws emr-containers list-virtual-clusters --query "virtualClusters[?name == '${EMRCLUSTERNAME}' && state == 'RUNNING'].id" --output text)
export ROLEARN=arn:aws:iam::$ACCOUNTID:role/$ROLENAME

# Criando Logs do CloundWatch
aws logs create-log-group --log-group-name=/emr-on-eks-logs/$EMRCLUSTERNAME

# Rodando o Job
aws emr-containers start-job-run \
    --virtual-cluster-id $EMRCLUSTERID \
    --name el_emr_on_eks_py \
    --execution-role-arn $ROLEARN \
    --release-label emr-6.2.0-latest \
    --job-driver '{
        "sparkSubmitJobDriver": {
            "entryPoint": "s3://'$OUTPUTS3BUCKET'/scripts/el_platfarm.ipynb",
        "sparkSubmitParameters": 
            " --conf spark.executor.instances=2 --conf spark.executor.memory=2G --conf spark.executor.cores=2"
        }
    }'

echo "Executado: submit_python_job"
echo "Status disponíveis em: "${EMRCLUSTERID}
echo "Resultados disponíveis em: "${OUTPUTS3BUCKET}