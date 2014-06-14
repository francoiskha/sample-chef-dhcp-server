= Notes

== Setup
Un peu de setup :
- installer virtualbox
- installer vagrant
- installer le provider omnibus pour vagrant, permettra de provisionner chef
```bash
vagrant plugin install vagrant-omnibus
```
- installer le plugin vagrant pour prendre des snapshots
```bash
vagrant plugin install vagrant-vbox-snapshot
```
- ouvrez un shell, créez un répertoire de travail et entrez dedans

== Installation de la vm et provisionning de chef
Pour commencer récupérer une vragrant box debian nue 
```bash
vagrant box init chef/debian-7.4
```
Editez le Vagrant file et ajouter la ligne nécessaire au provider chef
```ruby
config.omnibus.chef_version = :latest
```
A partir de maintenant, il faut lancez les commandes vagrant dans le répertoire de travail, celui avec le Vagrant file.
lancer et provisionner la vm avec :
```bash
vagrant up --provision
```
La vm se lance et vous pouvez vous connecter en ssh. Faites le dans une autre tab shell via 
```bash
vagrant ssh
```
Vous constaterez que le répertoire de travail est monté sur la vm dans /vagrant, bien pratique car vous pouvez 
Hors de la vm prenez un snapshot
```bash
vagrant snapshot take etat-initial
```
Si vous cassez un truc vous pourrez revenir à l'état du snapshot avec 
```bash
vagrant snapshot back
```
C'est utile quand on joue avec les config réseau.
== DHCP Server
Tout d'abord il faut savoir qu'une Vagrant box a obligatoirement une interface réseau dédiée à la communication avec la machine hôte. Dans notre cas c'est eth0.
En ssh sur la VM un
```bash
sudo ifconfig -a
```
ne montre qu'un eth0 et la boucle locale.
Pour pouvoir de la machine un serveur DHCP dans un réseau de machines virtuelles, il lui faudra une nouvelle interface réseau. Dans le Vagrant file on indique donc une configuration réseau.
Premier essai, on lui attribut une IP fixe :
```ruby
config.vm.network "private_network", ip: "192.168.4.0", :adapter => 2
```
On relance la VM avec un 
```bash
vagrant reload
```
Si vagrant signale que l'IP choisie est en conflit avec un de vos réseaux, changez de masque d'IP.
En ssh sur la VM un
```bash
sudo ifconfig -a
```
vous indiquera maintenant une interface eth1.
Dans le répertoire de travail créez un répertoire cookbooks dans lequel vous téléchargerez les cookbooks dhcp, helpers-databags et ruby-helper.
Toujours dans le répertoire de travail, créez aussi un répertoire databags/dhcp_networks avec un fichier 192-168-5-0_24.json :
```json{
  "id": "192-168-5-0_24",
  "routers": [ "192.168.5.0" ],
  "address": "192.168.5.0",
  "netmask": "255.255.255.0",
  "broadcast": "192.168.5.255",
  "range": "192.168.5.50 192.168.5.240"
}
```
Attention les databag en .json ne doivent contenir aucun character . dans le nom du fichier. L'id et le nom du fichier doivent correspondre.
Toujours dans le répertoire de travail, créez un fichier attributes/default.json :
```json
{
  "run_list": [ "recipe[dhcp::server]" ],
  "dhcp" : {
  	"interfaces" : [ "eth1" ],
    "networks": [ "192-168-5-0_24" ]
  }
}
```
Toujours dans le répertoire de travail, créez un fichier solo.rb :
```ruby
cookbook_path 	[ "/vagrant/cookbooks" ]
data_bag_path	"/vagrant/databags"
log_level	:debug
```
Dans la vm, lancez 
```bash
sudo chef-solo -c /vagrant/solo.rb -j "/vagrant/attributes/default.json"
```
