#!/usr/bin/env bash

# Função para exibir informações
display_info() {
  echo "--------------------------------------------"
  echo "$1"
  echo "--------------------------------------------"
}

# Funcao para instalar ou desinstalar
installOrUninstall() {
  read -p "Você deseja instalar (i) ou remover (r) as aplicações ? [i/r]" choice
  case "$choice" in
    i|install) installApplications;;
    r|remove) uninstallApplications;;
    *) echo " Opção inválida. Por favor, escolha 'i/install' para instalar ou 'r/remove' para desinstalar.";;
  esac
}
installApplications(){

  # Criar cluster k3d
  k3d cluster create thunderdome-teste -p "8081:8080@loadbalancer" --agents=3 --k3s-arg "--disable=traefik@server:0"
  display_info "Cluster 'thunderdome-teste' criado com sucesso."
  # Aplicar namespaces
  kubectl apply -f namespaces.yaml
  display_info "Namespaces aplicados com sucesso."
  # Instalar Ingress Controller
  helm install --namespace ingress ingress bitnami/nginx-ingress-controller
  display_info "Ingress Controller instalado com sucesso."
  # Aplicar ConfigMap
  kubectl apply -f configMap.yaml -n thunderdome-k3d
  display_info "ConfigMap aplicado com sucesso."
  # Aplicar Secret
  kubectl apply -f secret.yaml -n thunderdome-k3d
  display_info "Secret aplicado com sucesso."
  # Aplicar Ingress
  kubectl apply -f ingress.yaml -n thunderdome-k3d
  display_info "Ingress aplicado com sucesso."
  # Aplicar recursos do PostgreSQL
  kubectl apply -f postgresql/. -n thunderdome-k3d
  display_info "Recursos do PostgreSQL aplicados com sucesso."
  # Instalar API Autenticação
  kubectl apply -f thunderdome/. -n thunderdome-k3d
  display_info "Thunderdome aplicado com sucesso."
  helm repo add prometheus-community https://prometheus-community.github.io/helm-chart
  helm repo update
  display_info "Adicionando repo Prometheus"
  helm install stable prometheus-community/kube-prometheus-stack -n prometheus    
  display_info "Prometheus instalado com sucesso"
  helm repo add grafana https://grafana.github.io/helm-charts
  helm repo update
  display_info "Grafana instalado com sucesso"
}
uninstallApplications() {

  # Desinstalar recursos do PostgreSQL
  kubectl delete -f postgresql/. -n thunderdome-k3d
  display_info "Recursos do PostgreSQL desinstalados com sucesso."
  # Desinstalar API Autenticação
  kubectl delete -f thunderdome/. -n thunderdome-k3d
  display_info "Thunderdome desinstalado com sucesso."
  # Desinstalar Ingress
  kubectl delete -f ingress.yaml -n thunderdome-k3d
  display_info "Ingress desinstalado com sucesso."
  # Remover Secret
  kubectl delete -f secret.yaml -n thunderdome-k3d
  display_info "Secret removido com sucesso."
  # Remover ConfigMap
  kubectl delete -f configMap.yaml -n thunderdome-k3d
  display_info "ConfigMap removido com sucesso."
  # Desinstalar Ingress Controller
  helm uninstall --namespace ingress ingress
  display_info "Ingress Controller desinstalado com sucesso."
  # Remover namespaces
  kubectl delete -f namespaces.yaml
  display_info "Namespaces removidos com sucesso."
  # Remover cluster k3d
  k3d cluster delete thunderdome-teste
  display_info "Cluster 'thunderdome-teste' removido com sucesso."
  helm uninstall prometheus -n prometheus
  helm uninstall loko -n prometheus
  display_info "Prometheus e Grafana removido com sucesso"
}
# Executa função para iniciar tarefas
installOrUninstall
