# Graylog Kubernetes Cluster

## Infrastructure

We use `terraform` and `Digital Ocean` to create the cluster cloud resources.

Remember to set the following env variables:

```
export DIGITALOCEAN_TOKEN=token
export SPACES_ACCESS_KEY_ID=key
export SPACES_SECRET_ACCESS_KEY=secret
```

Then `cd cluster/ && terraform apply` to create a DO k8s cluster

## Resources Instalattion

The resources should be installed in the following order:

### Elastic Search

We use the elasticsearch [operator](https://www.elastic.co/guide/en/cloud-on-k8s/current/index.html) for managing elastic resources so first we need to create the custom resource definitions

```sh
kubectl apply -f resources/elasticsearch/operator.yml
```

Then we create the elastic cluster:

```sh
kubectl apply -f resources/elasticsearch/elasticsearch.yml
```

You can check the cluster status with `kubectl get elasticsearch`:

```sh
NAME            HEALTH   NODES   VERSION   PHASE   AGE
elasticsearch   green    1       7.15.2    Ready   46m
```


### MongoDB

We use the mongodb community [operator](https://github.com/mongodb/mongodb-kubernetes-operator) for managing mongodb resources so we first need to create the custom resource definitions:

```sh
kubectl apply -f resources/mongodb/operator.yml
```

Then create a secret for holding the mongodb user password:

```
kubectl create secret generic mongodb-password --from-literal=password='yourpassword'
```

Finally create the mongodb cluster:

```sh
kubectl apply -f resources/mongodb/mongodb.yml
```

You can check the cluster status with `kubectl get MongoDBCommunity`:

```sh
NAME      PHASE     VERSION
mongodb   Running   4.2.6
```

### Graylog

Graylog is the last resource we need to create but before we need a secret containing graylog's environment variables:

```
elastic_password=$(kubectl get secret elasticsearch-es-elastic-user -o go-template='{{.data.elastic | base64decode}}') \
mongo_uri=$(kubectl get secret mongodb-graylog-mongodb -o json | jq -r '.data | ."connectionString.standardSrv"'|base64 -d) && \
kubectl create secret generic graylog-env-test \
--from-literal=GRAYLOG_PASSWORD_SECRET=$(pwgen -N 1 -s 96) \
--from-literal=GRAYLOG_ROOT_PASSWORD_SHA2="echo -n '<GRAYLOG_UI_PASSWORD>'| sha256sum| awk '{print $1}'" \
--from-literal=GRAYLOG_ELASTICSEARCH_HOSTS=http://elastic:$elastic_password@elasticsearch-es-default-0.elasticsearch-es-default:9200 \
--from-literal=GRAYLOG_MONGODB_URI=$mongo_uri
```

Then `kubectl apply resources/graylog/graylog.yml`

```
kubectl get deploy,svc -l service=graylog
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/graylog   1/1     1            1           58m

NAME              TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)                        AGE
service/graylog   LoadBalancer   10.245.223.18   144.126.250.6   80:30951/TCP,12201:30321/TCP   58m
```

Use the service `EXTERNAL-IP` to access graylog's UI: https://144.126.250.6

## Local Setup

If you just want to test the graylog stack locally you can just use `docker-compose up`