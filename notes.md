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
Tout d'abord il faut savoir qu'une Vagrant box a obligatoirement une interface réseau dédiée à la communication avec la machine hôte. Dans notre cas c'est `eth0`.
En ssh sur la VM un
```bash
sudo ifconfig -a
```
ne montre qu'un eth0 et la boucle locale.
Pour pouvoir de la machine un serveur DHCP dans un réseau de machines virtuelles, il lui faudra une nouvelle interface réseau. Dans le Vagrant file on indique donc une configuration réseau.
Premier essai, on lui attribut une IP fixe :
```ruby
config.vm.network "private_network", ip: "192.168.5.0", :adapter => 2
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
vous indiquera maintenant une interface `eth1`.
Dans le répertoire de travail créez un répertoire cookbooks dans lequel vous téléchargerez les cookbooks `dhcp`, `helpers-databags` et `ruby-helper`.
Toujours dans le répertoire de travail, créez aussi un répertoire `databags/dhcp_networks` avec un fichier 192-168-5-0_24.json :
```json{
  "id": "192-168-5-0_24",
  "routers": [ "192.168.5.0" ],
  "address": "192.168.5.0",
  "netmask": "255.255.255.0",
  "broadcast": "192.168.5.255",
  "range": "192.168.5.50 192.168.5.254"
}
```
Attention les databag en `.json` ne doivent contenir aucun caractère `.` dans le nom du fichier. Notez aussi que l'id et le nom du fichier doivent correspondre.
Toujours dans le répertoire de travail, créez un fichier `attributes/default.json` :
```json
{
  "run_list": [ "recipe[dhcp::server]" ],
  "dhcp" : {
  	"interfaces" : [ "eth1" ],
    "networks": [ "192-168-5-0_24" ]
  }
}
```
On y définit la run-list chef, ici uniquement la recette `dhcp::server`, et les attributs nécessaires, notamment l'interface réseau sur laquelle on configure le serveur dhcp (sinon toutes les interfaces réseaux sont configurées et l'on veut conserver `eth0` pour le ssh uniquement). On désigne aussi le databag de réseau à configurer.
Toujours dans le répertoire de travail, créez un fichier solo.rb :
```ruby
cookbook_path 	[ "/vagrant/cookbooks" ]
data_bag_path	"/vagrant/databags"
log_level	:debug
```
C'est la configuration de chef, le niveau de log debug n'est pas nécessaire mais il vous permet de voir ce qui se passe en détail si vous le désirez.
Dans la vm, lancez 
```bash
sudo chef-solo -c /vagrant/solo.rb -j "/vagrant/attributes/default.json"
```
== Test du DHCP server avec un client
Là on va ajouter une seconde machine virtuelle dans le fichier Vagrant. Pour qu'elles puissent se parler, elles doivent être dans le même réseau virtuel. Identifiez dans virtualbox sur quel réseau est votre première machine. Moi c'est `vboxnet1`.
C'est noté ? ok parce que maintenant on détruit la machine créée avec :
```bash
vagrant destroy
```
Maintenant supprimez le serveur dhcp pour le réseau virtuel dans virtual box (via la GUI ou bien via `VBoxManage`)
Ensuite on retouche le vagrant file : 
```ruby
config.vm.provider :virtualbox do |vb|
  # choisir un réseau virtual box sans dhcpserver
  vb.customize ['modifyvm', :id, '--hostonlyadapter2', 'vboxnet1']
end
# Every Vagrant virtual environment requires a box to build off of.
config.vm.box = "chef/debian-7.4"
config.vm.define "master", primary: true do |master|
  master.omnibus.chef_version = :latest
  master.vm.network "private_network", ip: "192.168.5.0", :netmask => "255.255.255.0", :adapter => 2
end
config.vm.define "client" do |client|
  client.vm.network "private_network", type: "dhcp", :netmask => "255.255.255.0", :adapter => 2, auto_config: false
end
```
Voilà ce que l'on fait en détail : d'abord on déclare que pour toute vm virtualbox, le réseau virtuel à utiliser est `vboxnet1`. Ensuite, toujours pour toutes les vm, la box à utiliser est toujours la même. Enfin, on définit 2 vm distinctes `master` qui a les attributs de notre serveur dhcp et `client` qui n'aura pas de provisionning de chef et pas d'IP fixe. Au passage on désative l'autoconfig de réseau et on précise le masque réseau (j'ai eu des problème de masque attribué automatiquement)
Lancez la machine master avec :
```bash
vagrant up master
```
Ensuite exécutez chef comme précédemment.
Lancez la machine cliente :
```bash
vagrant up client
```
Maintenant en ssh sur la machine master vous devriez la voir accorder un bail dhcp dans le syslog :
```bash
tail /var/log/syslog
```