#!/usr/bin/env bash
# Deletes the two clusters and stops the console. Run it when you're done.
pkill -f "port-forward svc/pipecd" 2>/dev/null
kind delete cluster --name cluster1
kind delete cluster --name cluster2
