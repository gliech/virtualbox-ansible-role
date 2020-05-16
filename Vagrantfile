# -*- mode: ruby -*-
# vi: set ft=ruby :
require 'set'
require 'digest'
require 'ipaddr'

# Im Normalfall wird der Name des Projektes, der in den Namen der VMs benutzt
# wird, aus dem Namen des Verzeichnisses aus dem Vagrant ausgeführt wird
# gebildet. Wenn gewünscht kann das hier überschrieben werden.
#project_name = 'myproject'

# Jedes Item dieses Arrays definiert eine Virtuelle Machine, die mit Ansible
# verwaltet werden kann. Die Schlüssel name und box müssen in jedem Item
# vorhanden sein. Der Rest der Schlüssel ist optional.
guests = [
    { name: 'fedora', box: 'bento/fedora-31' },
#   { name: 'centos', box: 'centos/8' },
#   { name: 'sl6', box: 'bytepark/scientific-6.5-64' },
#   { name: 'sl7', box: 'ropsu/scientific7_x86_64_minimal' },
#   { name: 'ubuntu', box: 'bento/ubuntu-18.04' },
#   { name: 'debian', box: 'debian/testing64' },
#   { name: 'arch', box: 'archlinux/archlinux' },
#   { name: 'example1', box: 'centos/6', groups: ['web', 'mon'], ip: '10.10.10.2', hostvars: { test: 42 } },
#   { name: 'example2', box: 'centos/7', groups: ['db', 'mon'], cpus: 2, mem: 1024 },
]

ansible_cfg          = 'vagrant/ansible.cfg'
ansible_playbook     = 'vagrant/playbook.yml'
ansible_requirements = 'vagrant/requirements.yml'
ansible_roles_host   = 'vagrant/roles'
ansible_roles_guest  = 'vagrant/roles'
ansible_galaxy_force = false
ansible_galaxy_sudo  = false
vbox_default_cpus    = 1
vbox_default_mem     = 512
vagrant_intnet       = '10.10.10.0'
vagrant_netmask      = '255.255.255.0'

vagrant_intnet_dhcp = false
dhcp_range_start    = '10.10.10.10'
dhcp_range_end      = '10.10.10.30'
dhcp_domain         = 'vagrant'

# Hier können zusätzliche Ansible Gruppen für das von Vagrant erstellte Inventar
# angegeben werden. Die Gruppenzugehörigkeit von Clients sollte nicht hier
# sondern in der groups Liste in der Definition der VM festgelegt werden. So
# kann Vagrant die Namen mit denen die VMs erstellt werden selbst verwalten. 
# Auch sollten, obwohl ich ihre Verwendung im Beispiel demonstriere,
# Gruppenvariablen besser in ein group_vars Verzeichnis ausgelagert werden.
# Siehe hierzu auch die Ansible Dokumentation:
# http://docs.ansible.com/ansible/latest/intro_inventory.html#splitting-out-host-and-group-specific-data
# Wenn man trotzdem Gruppenvariablen hier definiert, ist zu beachten, dass
# Booleans nur korrekt erkannt werden, wenn sie genau als 'True' und 'False'
# geschrieben sind.
ansible_groups = {
#   'web:children': ['db'],
#   'db:vars': { secure_setup: 'True' },
#   'mon:vars': { monitoring_server: 'mon.example.com', monitorin_port: '1234' },
}

# Dieser Vagrantfile kann Ansible entweder vom Host aus ausführen, oder eine
# zuätzliche VM hochfahren, die als Ansible Controller fungiert. Dieses
# Verhalten kann über die Variable ansible_mode angepasst werden. Als Werte
# akzeptiert werden:
# host  => Verwende Ansible auf dem Host mit dem 'ansible' Provisioner
# guest => Fahre noch eine VM hoch und verwende 'ansible_local' als Provisioner
# auto  => Verwende den 'ansible' Provisioner, wenn Abnsible auf dem Host
#          installiert ist, ansonsten verwende 'ansible_local' mit zusätzlicher
#          VM
ansible_mode = 'auto'

# Vagrant Boxen die von den beiden zusätzlichen VMs benutzt werden, die je nach
# Konfiguration hochgefahren werden. Sollte nur verändert werden müssen, wenn
# die Box veraltet ist.
provisioner_box = 'centos/7'
dhcp_box = 'centos/7'

################################################
# Ab hier sollte der Vagrantfile im Normalfall #
# nicht mehr angepasst werden müssen!          #
################################################

VAGRANTFILE_API_VERSION = "2"

# Funktion um zu bestimmen ob ein Programm auf der ausführenden Maschiene
# installiert ist
def which(cmd)
    exts = ENV['PATHEXT'] ? ENV['PATHEXT'].split(';') : ['']
    ENV['PATH'].split(File::PATH_SEPARATOR).each do |path|
        exts.each { |ext|
            exe = File.join(path, "#{cmd}#{ext}")
            return exe if File.executable?(exe) && !File.directory?(exe)
        }
    end
    return nil
end

# Bestimme in welchem Modus der Rest des Vagrantfiles ausgeführt werden soll
# wenn 'auto' gewählt wurde
if ansible_mode == 'auto'
    ansible_mode = which('ansible-playbook') ? 'host' : 'guest'
end

unless ['host','guest'].include? ansible_mode
    raise 'Could not determine how to execute Ansible. Maybe ansible_mode has a wrong value?'
end

# Bestimme den Namen des Moduls das zu testen ist aus dem Basename des 
# Directories in dem sich der Vagrantfile befindet
role_name = File.basename( File.dirname(__FILE__) )
unless defined?(project_name)
    project_name = role_name
end

# Bestimme ob es einen requirements File gibt, der von Ansible ausgeführt
# werden muss
run_galaxy = File.file?(File.join( File.dirname(__FILE__), ansible_requirements ))
galaxy_cmd = ( ansible_galaxy_sudo ? 'sudo ' : '' ) +
    'ansible-galaxy install --role-file=%{role_file} --roles-path=' +
    ( ansible_mode == 'host' ? ansible_roles_host : ansible_roles_guest ) +
    ( ansible_galaxy_force ? ' --force ' : '' )


# Wandele die Konfigurationsschlüssel zum internen Netzwerk der VMs in IPAddr
# Objekte um, um später mit ihnen rechnen zu können.
intnet_ip = IPAddr.new(vagrant_intnet)
intnet = intnet_ip.mask(vagrant_netmask)
netmask_ip = IPAddr.new(vagrant_netmask)
broadcast_ip = intnet_ip|(~netmask_ip)
first_ip = intnet_ip|1

# Pool definieren, in den schon verwendete, oder nicht benutzbare IP-Addressen
# kommen.
ip_pool = Set[ intnet_ip, broadcast_ip ]

# Überprüfe ob die DHCP Range im Netzwerk liegt, wenn DHCP verwendet wird.
if vagrant_intnet_dhcp
    dhcp_range_start_ip = IPAddr.new(dhcp_range_start)
    dhcp_range_end_ip = IPAddr.new(dhcp_range_end)
    [dhcp_range_start_ip, dhcp_range_end_ip].each do |dhcp_ip|
        if ! intnet.include?( dhcp_ip) or ip_pool.include?( dhcp_ip )
            raise "The provided DHCP range #{dhcp_range_start}-#{dhcp_range_end} "\
                  "appears not to be inside the chosen network #{intnet.to_s()}."
        end
    end
end

# Packe alle VMs die wirklich als Teil der Testumgebung hochgefahren werden
# in eine gemeinsame Gruppe 'guests', um sie von Management VMs (DHCP Server
# und Ansible Controller) unterscheiden zu können
guests.each do |guest|
    ( guest[:groups] ||= [] ) << 'guests'
end

# Wenn der Guestmode verwended wird, eine VM als Ansible Controller hochfahren
# Die IP der VM ist immer die letzte IP die im Netzwerk verwendet werden kann.
if ansible_mode == 'guest'
    provisioner_ip = intnet_ip|(IPAddr.new('255.255.255.254')&(~netmask_ip))
    provisioner_specs = {
        name: 'provisioner',
        box: provisioner_box,
        ip: provisioner_ip.to_s(),
        cpus: 1,
        mem: 256
    }
    # Setzt den Eintrag ans Ende der Liste. Der Provisioner wird zuletzt hoch
    # gefahren.
    guests.push(provisioner_specs)
end

# Wenn der DHCP Modus verwendet wird, eine VM als DHCP und DNS Server hochfahren
# Die IP der VM ist die letzte oder vorletzte IP die im Netzwerk verwendet
# werden kann, je nachdem ob auch ein Ansible Controller hoch gefahren wird.
if vagrant_intnet_dhcp
    if ansible_mode == 'guest'
        dhcp_server_mask = '255.255.255.253'
    else
        dhcp_server_mask = '255.255.255.254'
    end
    dhcp_server_ip = intnet_ip|(IPAddr.new(dhcp_server_mask)&(~netmask_ip))
    dhcp_server_specs = {
        name: 'dhcp',
        box: dhcp_box,
        ip: dhcp_server_ip.to_s(),
        cpus: 1,
        mem: 256
    }
    # Setzt den Eintrag an den Anfang der Liste. Der DHCP Server wird als erstes
    # hoch gefahren.
    guests.unshift(dhcp_server_specs)
end

# Überarbeitung der Liste hochzufahrender VMs für den späteren Gebrauch im
# Main Loop
guests.each do |guest|
    # Ersetze jede statische IP Addresse in den VM Definitionen durch ein IPAddr
    # Objekt, das die Addresse repräsentiert
    if guest.has_key?(:ip)
        guest[:ip] = IPAddr.new(guest[:ip])
        # Überprüfe ob die soeben erzeugte Addresse bereits verwendet wird oder
        # geschützt ist, und füge sie dem Pool geschützter Addressen hinzu
        if ip_pool.add?( guest[:ip] ).nil?
            raise "The custom IP #{guest[:ip].to_s()} of the VM #{guest[:name]} "\
                  "is already in use by another machine or it is a protected "\
                  "network address."
        end
    end
    # Baue die Namen der Maschinen für Vagrant und Virtualbox. Der Name in
    # Virtualbox enthält zusätzlich den Prefix 'vagrant' um die VMs besser
    # von anderen unterscheiden zu können.
    guest[:vagrant_name] = (project_name.empty? ? "" : "#{project_name}-") + guest[:name]
    guest[:vbox_name] = 'vagrant_' + (project_name.empty? ? "" : "#{project_name}_") + guest[:name]
end

ip_pool.each do |protected_ip|
    # Überprüfe ob alle statischen Addressen im Netzwerk sind.
    unless intnet.include?(protected_ip)
        raise "The IP #{protected_ip.to_s()} is not part of the network "\
              "#{intnet.to_s()}. Replace this IP or change the network to "\
              "include it."
    end
    # Überprüfe ob alle statischen Addressen außerhalb der DHCP Range sind.
    if vagrant_intnet_dhcp and
       protected_ip >= dhcp_range_start_ip and
       protected_ip <= dhcp_range_end_ip
        raise "The static IP #{protected_ip.to_s()} appears to be inside the "\
              "chosen DHCP range of #{dhcp_range_start}-#{dhcp_range_end}. "\
              "Replace this IP or change the DHCP range to not include it."
    end
end

# Wenn kein DHCP verwendet wird, versuche allen Rechnern ohne IP Addresse
# automatisch eine zuzuweisen.
unless vagrant_intnet_dhcp
    ip_pool.add(first_ip)
    guests.each do |guest|
        unless guest.has_key?(:ip)
            # Bestimmt wie häufig wir versuchen eine zufällige IP zu vergeben
            # bevor wir aufgeben
            ttl = 10000
            # Verwende den Namen der VM als Seed für einen RNG, mit dem eine
            # zufällige IP-Addresse generiert wird. Durch Umformung wird die
            # IP Adresse dann so verändert, dass sie sich im gleichen
            # Subnetz wie alle anderen Adressen befindet.
            guest_hash = Digest::SHA512.hexdigest(guest[:vagrant_name]).to_i(16)
            guest_rand = Random.new(guest_hash)
            guest_ip = ''
            loop do
                if ttl == 0
                    raise "Could not find an unused IP address for #{guest[:name]}. "\
                          "Is the network #{intnet.to_s()} too small?"
                end
                raw_ip = IPAddr.new(guest_rand.rand(2**32), Socket::AF_INET)
                guest_ip = (raw_ip&(~netmask_ip))|intnet_ip
                break unless ip_pool.add?( guest_ip ).nil?
                ttl -= 1
            end
            guest[:ip] = guest_ip
        end
    end
end

# Fülle die Gruppen und Hostvariablen Datenstrukturen für Ansible.
# Oh ja, so legt man ein leeres Array oder einen leeren Hash als Defaultvalue
# für ein Hash fest. Ist Ruby nicht eine formschöne leicht verständliche
# Programmiersprache?
ansible_hostvars = Hash.new{ |hash, key| hash[key] = {} }
ansible_groups.default_proc = proc { |hash, key| hash[key] = [] }

guests.each do |guest|
    # Lege Alias für den Hash an, in den die Hostvars der grade evaluierten VM
    # abgelegt werden, um den Rest dieses Abschnitts etwas leserlicher zu machen
    hostvar_hash = ansible_hostvars[ guest[:vagrant_name].to_sym ]
    # Wenn der Ansible Provisioner im Guestmode ausgeführt wird, werden dem
    # Ansible Controller die Private Keys mit denen man sich auf die anderen VMs
    # verbinden kann über einen Synced Folder zur Verfügung gestellt. Diese
    # Hostvar ist notwendig, damit diese Keys auch in Ansible verwendet werden.
    if ansible_mode == 'guest'
        hostvar_hash[:ansible_ssh_private_key_file] = "/machines/#{guest[:vagrant_name]}/virtualbox/private_key"
    end
    # Wenn der Guestmode ohne DHCP/DNS Server verwendet wird, muss dem Ansible
    # Controller zusätzlich mitgeteilt werden, unter welchen IPs die anderen
    # VMs im internen Netzwerk erreichbar sind.
    if ansible_mode == 'guest' and ! vagrant_intnet_dhcp
        hostvar_hash[:ansible_ssh_host] = guest[:ip].to_s()
    end
    # Lege vom Benutzer definierte Hostvars in den Hash
    if guest.has_key?(:hostvars)
        hostvar_hash.update(guest[:hostvars])
    end
    # Für jede Gruppe, die bei einem Guest angegeben wurde, lege den Namen des
    # Guests in die entsprechende Gruppe im ansible_groups Hash
    if guest.has_key?(:groups)
        guest[:groups].each do |group|
            ansible_groups[group.to_sym] << guest[:vagrant_name]
        end
    end
end

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

    # Konfiguration des DHCP Servers für den dhcp mode

    # Konfiguration aller Maschinen die in guests definiert sind
    guests.each_with_index do |guest, index|

        config.vm.define guest[:vagrant_name] do |machine|
            machine.vm.hostname = guest[:vagrant_name]
            machine.vm.box = guest[:box]

            if guest.has_key?(:ip)
                machine.vm.network 'private_network',
                    ip: guest[:ip].to_s(),
                    netmask: netmask_ip.to_s(),
                    virtualbox__intnet: "vagrant-#{project_name}-network"
            else
                machine.vm.network 'private_network',
                    type: 'dhcp',
                    virtualbox__intnet: "vagrant-#{project_name}-network"
            end

            # Allgemeine Einstellungen die jede Maschine in Virtualbox bekommt.
            machine.vm.provider 'virtualbox' do |vbox|
                vbox.name = guest[:vbox_name]
                vbox.cpus = guest.has_key?(:cpus) ? guest[:cpus] : vbox_default_cpus
                vbox.memory = guest.has_key?(:mem) ? guest[:mem] : vbox_default_mem
            end

            if ansible_mode == 'guest' and guest[:name] == 'provisioner'
                machine.vm.synced_folder '.', '/vagrant',
                    disabled: true
                machine.vm.synced_folder ".", "/#{role_name}",
                    type: "rsync"
                machine.vm.synced_folder "./.vagrant/machines", "/machines",
                    type: "rsync",
                    rsync__args: [ "--verbose", "--archive", "--delete", "-z", "--copy-links", "--chmod=D700,F600"]
            else
                machine.vm.synced_folder '.', '/vagrant',
                    type: "rsync"
            end

            machine.vm.provision 'shell',
                path: 'vagrant/install-python.sh'

            if vagrant_intnet_dhcp and guest[:name] == 'dhcp'
                machine.vm.provision 'ansible_local' do |ansible|
                    ansible.playbook = 'vagrant/dhcp/server.yml'
                    ansible.config_file = 'vagrant/dhcp/ansible.cfg'
                    # Färbe den Output von ansible_local ein wie natives Ansible
                    ansible.playbook_command = 'PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ansible-playbook'
                    ansible.become = true
                    ansible.extra_vars = {
                        dhcp_range_start: dhcp_range_start,
                        dhcp_range_end: dhcp_range_end,
                        dhcp_lease_time: '1h',
                        dhcp_domain: dhcp_domain,
                        dhcp_static_ips: guests.select{ |item| item.has_key?(:ip) }.map{ |item| [ item[:vagrant_name], item[:ip].to_s() ] }.to_h()
                    }
                end
            end

            if vagrant_intnet_dhcp and guest[:name] != 'dhcp'
                machine.vm.provision 'shell' do |shell|
                    shell.path = 'vagrant/dhcp/ignore-vagrant-dns.sh'
                    shell.env = {
                        VAGRANT_DHCP_DOMAIN: dhcp_domain,
                        VAGRANT_DHCP_IP: dhcp_server_ip.to_s()
                    }
                end
            end

            if ansible_mode == 'guest' and guest[:name] == 'provisioner'
                machine.vm.provision 'ansible_local', run: 'always' do |ansible|
                    ansible.provisioning_path = "/#{role_name}"
                    ansible.playbook = ansible_playbook
                    # Färbe den Output von ansible_local ein wie natives Ansible
                    ansible.playbook_command = 'PYTHONUNBUFFERED=1 ANSIBLE_FORCE_COLOR=true ansible-playbook'
                    if run_galaxy
                        ansible.galaxy_role_file = ansible_requirements
                        ansible.galaxy_command = galaxy_cmd
                    end
                    ansible.config_file = ansible_cfg
                    ansible.limit = 'all'
                    ansible.become = false
                    ansible.groups = ansible_groups
                    ansible.host_vars = ansible_hostvars
                    ansible.extra_vars = {
                        role_name: role_name,
                    }
                end
            end

            # Provisioniere im Hostmode, wenn die letzte Maschine hochgefahren 
            # wurde, alle Maschinen mit Ansible. Würde dieser Block außerhalb
            # einer einzigen Maschinendefinition stehen, würde Ansible beim
            # Hochfahren jeder Maschine versuchen alle Maschinen zu
            # konfigurieren.
            if ansible_mode == 'host' and index == guests.size - 1
                machine.vm.provision 'ansible', run: 'always' do |ansible|
                    ansible.playbook = ansible_playbook
                    if run_galaxy
                        ansible.galaxy_role_file = ansible_requirements
                        ansible.galaxy_command = galaxy_cmd
                    end
                    ansible.config_file = ansible_cfg
                    ansible.limit = 'all'
                    ansible.become = false
                    ansible.groups = ansible_groups
                    ansible.host_vars = ansible_hostvars
                    ansible.extra_vars = {
                        role_name: role_name,
                    }
                end
            end
        end
    end
end
