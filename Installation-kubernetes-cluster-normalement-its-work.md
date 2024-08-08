# Installation de Kubernetes

## Préparation du système

1. **Mise à jour du fichier `/etc/hosts` :**

    ```bash
    sudo -- sh -c "echo $(hostname -i) $(hostname) >> /etc/hosts"
    ```

2. **Désactivation de la partition d'échange :**

    ```bash
    sudo sed -i "/swap/s/^/#/" /etc/fstab
    sudo swapoff -a
    ```

3. **Configuration des paramètres sysctl :**

    ```bash
    cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
    overlay
    br_netfilter
    EOF

    sudo modprobe overlay
    sudo modprobe br_netfilter 

    cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
    net.bridge.bridge-nf-call-iptables   = 1
    net.bridge.bridge-nf-call-ip6tables = 1
    net.ipv4.ip_forward                 = 1
    EOF

    sudo sysctl --system
    ```

4. **Installer les paquets prérequis pour HTTPS :**

    ```bash

    sudo apt-get update && sudo apt upgrade

    sudo apt install apt-transport-https ca-certificates curl software-properties-common gnupg net-tools
    ```


## Installation de containerd

1. **Mettre à jour les informations des paquets :**

    ```bash
    sudo apt-get update
    ```


2. **Ajouter la clé GPG du référentiel Docker :**

    ```bash
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    ```

3. **Ajouter le référentiel Docker aux sources APT :**

    ```bash
    echo \
        "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    ```

4. **Mettre à jour la base de données des paquets :**

    ```bash
    sudo apt-get update
    ```

5. **Installer containerd :**

    ```bash
    sudo apt install containerd.io 
    ```

6. **creez le fichier de configuration**

    ```bash
    sudo mkdir -p /etc/containerd
    sudo containerd config default | sudo tee /etc/containerd/config.toml
    ```

7. **configurez le fichier de configuration containerd**

    ```bash
    sudo nano /etc/containerd/config.toml
    ```

    À la fin de cette section, changez SystemdCgroup = false en SystemdCgroup = true

     ```text
        [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]
        ...
          [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
            SystemdCgroup = true
     ```

    Vous pouvez utiliser sed pour remplacer par true

    ```bash
    sudo sed -i 's/            SystemdCgroup = false/            SystemdCgroup = true/' /etc/containerd/config.toml
    ```

8. **restart containerd :**

     ```bash
    sudo systemctl restart containerd
     ```

6. **Vérifier le statut de containerd :**

    ```bash
    sudo systemctl status containerd
    ```

## Installation de `kubectl`, `kubeadm` et `kubelet`

1. **Télécharger la clé publique pour les dépôts Kubernetes :**

    ```bash
    # Si le dossier `/etc/apt/keyrings` n'existe pas, créez-le avant la commande curl
    # sudo mkdir -p -m 755 /etc/apt/keyrings

    curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    sudo chmod 644 /etc/apt/keyrings/kubernetes-apt-keyring.gpg
    ```

2. **Ajouter le dépôt Kubernetes aux sources APT :**

    ```bash
    echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
    sudo chmod 644 /etc/apt/sources.list.d/kubernetes.list
    ```

3. **Mettre à jour les index de paquets et installer `kubelet`, `kubeadm` et `kubectl` :**

    ```bash
    sudo apt-get update
    sudo apt-get install -y kubelet kubeadm kubectl
    sudo apt-mark hold kubelet kubeadm kubectl
    ```

3. **Vérifiez le statut de notre kubelet et de notre runtime de conteneur, containerd.**

    Le kubelet entrera dans une boucle de crash jusqu'à ce qu'un cluster soit créé ou que le nœud soit joint à un cluster existant.

     ```bash
    sudo systemctl status kubelet.service 
    sudo systemctl status containerd.service 
     ```

3. **Assurez-vous que les deux sont configurés pour démarrer lorsque le système démarre.**

    ```bash
    sudo systemctl enable kubelet.service
    sudo systemctl enable containerd.service
    ```

## Installation et configuration de Calico

1. **Télécharger le manifeste Calico :**

    ```bash
    curl https://raw.githubusercontent.com/projectcalico/calico/v3.28.0/manifests/calico.yaml -o /home/YOUR_USER/calico.yaml
    ```

2. **Modifier le fichier `calico.yaml` :**

    ```bash
    sed -i.bak -e 's/# - name: CALICO_IPV4POOL_CIDR/- name: CALICO_IPV4POOL_CIDR/' \
               -e 's/#   value: "192.168.0.0\/16"/  value: "10.0.244.0\/16"/' /home/YOUR_USER/calico.yaml
    ```



## init cluster

1. **initialisation du cluster :**

    ```bash
    kubeadm init
    ```

2. **Appliquer le manifeste Calico :**

    ```bash
    kubectl apply -f /home/YOUR_USER/calico.yaml
    ```

## Configuration de l'accès au cluster

1. **Pour un utilisateur normal :**

    ```bash
    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
    ```

2. **Pour l'utilisateur root :**

    ```bash
    export KUBECONFIG=/etc/kubernetes/admin.conf
    ```


## (Optionnel) Contrôler votre cluster depuis une machine autre que le master

1. **Copier le fichier `admin.conf` sur votre poste de travail :**

    ```bash
    scp root@<master_ip>:/etc/kubernetes/admin.conf .
    ```

2. **Utiliser `kubectl` avec le fichier de configuration :**

    ```bash
    kubectl --kubeconfig ./admin.conf get nodes
    ```

## Installation du tableau de bord Web

## Installation de Helm

1. **Ajouter la clé GPG pour Helm :**

    ```bash
    curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
    ```

2. **Ajouter le dépôt Helm aux sources APT :**

    ```bash
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
    ```

3. **Mettre à jour les index de paquets et installer Helm :**

    ```bash
    sudo apt-get update
    sudo apt-get install helm
    ```

## Vérifier le bon fonctionnement du cluster avec Sonobuoy

1. **Télécharger et installer Sonobuoy :**

    ```bash
    wget https://github.com/vmware-tanzu/sonobuoy/releases/download/v0.57.1/sonobuoy_0.57.1_linux_amd64.tar.gz
    tar -xvf sonobuoy_0.57.1_linux_amd64.tar.gz
    chmod +x sonobuoy
    sudo mv sonobuoy /usr/local/bin/
    ```

2. **Vérifier le chemin et exécuter Sonobuoy :**

    ```bash
    echo $PATH
    sonobuoy run --wait
    ```