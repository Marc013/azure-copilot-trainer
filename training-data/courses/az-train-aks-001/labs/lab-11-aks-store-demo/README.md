# Lab 11: Deploy aks-store-demo End-to-End on Private AKS
# Objective IDs: ACR-02, ACR-03, NET-05, CICD-01, CICD-02
#
# This directory contains all Kubernetes manifests to deploy the complete
# Azure-Samples/aks-store-demo application to the private AKS cluster.
#
# Apply all manifests from the consolidated multi-document file:
#   kubectl apply -f manifests.yaml
#
# You can still apply by directory if this folder later contains split files:
#   kubectl apply -f . -n aks-store-demo
