# Kubernetes Multi-Node Cluster com Stack Elastic e Horizontal Pod Autoscaler

Este projeto consiste na implementação de um cluster Kubernetes puro utilizando a topologia multi-nós (1 Control-Plane e 2 Workers) via Kind. O objetivo do laboratório é validar o auto escalonamento horizontal de uma API FastAPI baseado no consumo de CPU, integrado à coleta e centralização de logs em tempo real utilizando Elasticsearch, Kibana e Filebeat (DaemonSet).

---

## Arquitetura do Ambiente

* **Cluster Kubernetes:** 1 nó Master (Control-Plane) e 2 nós Workers executando a versão pura v1.29.2.
* **Aplicação Base:** API desenvolvida em Python com o framework FastAPI.
* **Métricas do Cluster:** Metrics Server implantado com bypass de TLS inseguro para coleta de consumo dos pods.
* **Ingestão e Observabilidade:** Stack Elastic (Elasticsearch v7.17.10 em modo single-node e Kibana v7.17.10 para visualização).
* **Coleta de Logs:** Filebeat implantado como DaemonSet, garantindo um agente coletor nativo em cada nó worker mapeando o diretório de logs de containers do cluster.

---

## Estrutura de Pastas do Projeto

* `app/`: Código fonte da API em Python, dependências e Dockerfile.
* `k8s-api/`: Manifestos de Deployment, Service (ClusterIP) da aplicação e configuração do Horizontal Pod Autoscaler (HPA).
* `k8s-elastic/`: Manifestos de infraestrutura da Stack Elastic (Elasticsearch, Kibana) e o DaemonSet do Filebeat.

---

## Mecanismo de Autoscaling (HPA)

O Horizontal Pod Autoscaler foi configurado para monitorar o Deployment da API com os seguintes parâmetros:
* Mínimo de réplicas: 1
* Máximo de réplicas: 5
* Alvo de utilização de CPU: 50%

Durante os testes de estresse (carga constante via loop de requisições concorrentes), o HPA identificou o pico de processamento, elevando a infraestrutura para o limite de 5 réplicas ativas e distribuindo a carga entre os nós workers disponíveis, gerando mais de 84 mil registros de logs indexados.
