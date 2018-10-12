
Port of K8S-TESTBED to the Raspberry Pi

# Purpose
With the K8S-TESTBED project maturing and extending to be not only a technology testbed 
and demonstration but also a demonstration platform for incorporating true performance 
testing and engineering into the DevOps CI/CD pipeline, and interesting idea came about: 
Can a microservice automated build and test pipeline operate within a microCloud?  This question 
is heavily rooted in the example from 2015 at https://kubernetes.io/blog/2015/12/creating-raspberry-pi-cluster-running/ 
but brought up to current versions since Kubernetes (and Hypriot) have evolved substantially.

# Microcloud

The idea of a microcloud demonstration platform is attractive due to the idea of extremely low cost
as well as insuring scale of microservices.  If a microservice, and in fact the entire CI/CD pipeline
can operate in a microcloud, then the promise of greater efficiency and cost containment of all these
emerging technology stacks is quantitatively demonstrated.

The microcloud architecture for this experiment is a Kubernetes cluster running on a set 
of 4 Raspberry Pi 3s with the following cost breakdown:
Quantity | Unit Cost | Description
------- | -------- | -----------------------------------------------
4|$40| Raspberry Pi 3 B+
4|$9| Sumsung EVO 32GB microSD cards
4|$1| Cat6 Ethernet Cables (1 ft)
4|$1| Micro USB cables
1|$31| Multiport USB Rapid Charger
1|--| 8 port 10/100 switch
1|$34| Stackable case for 4 Rasberry Pi 3 B+

Total cost: $269 (excluding network switch)

NOTE: this build mirrors the 2015 build using a 10/100 wired switch.  The Pi3 includes build-in wifi so the need
for the Cat6 cables and switch could no longer be needed.  One to-do item would be to use the wifi on the Master to 
expose the cluster to the outside world and use the wired network for all intra-cluster communication.

# Installation
Hypriot suggests using their flash tool to burn the SD image.  While other IMG burning tools are available, 
the one from Hypriot is OS aware and able to perform a few nice to have operations from the commandline like 
setting the hostname.  It was retrieved from https://github.com/hypriot/flash .  Alternatively, you can the tools 
at: https://blog.hypriot.com/getting-started-with-docker-and-windows-on-the-raspberry-pi/ .  If you use the Win32 Disk Imager
then you will want to edit the /user-data file on the SD since Hypriot uses cloud-init on the first boot (at the very least, hostname).


