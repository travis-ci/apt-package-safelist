PROVISION_SCRIPTS = [
  <<-EOF,
    export DEBIAN_FRONTEND=noninteractive

    apt-get update -y
    apt-get install -yq lvm2 xfsprogs
  EOF

  <<-EOF,
    if ! command -v docker ; then
      curl -sSL https://get.docker.io | bash
    fi
  EOF

  'usermod -a -G docker vagrant',
  'usermod -a -G docker ubuntu',
  'docker pull quay.io/travisci/travis-ruby:latest',

  <<-EOF,
    if ! jq --version ; then
      curl -sSL -o /usr/local/bin/jq http://stedolan.github.io/jq/download/linux64/jq
      chmod 0755 /usr/local/bin/jq
    fi
  EOF

  <<-EOF,
    docker images | grep -q -E '^travis\\s+\\bruby\\b\\s+' || \\
      docker tag quay.io/travisci/travis-ruby:latest travis:ruby
  EOF

  <<-EOF
    cp -v /vagrant/bin/travis-download-deb-sources /usr/local/bin/
    chmod 0755 /usr/local/bin/travis-download-deb-sources
  EOF
]

Vagrant.configure('2') do |config|
  config.vm.define 'trusty' do |trusty|
    trusty.vm.hostname = 'apt-package-safelist-trusty'
    trusty.vm.box = 'ubuntu/trusty64'
  end

  config.vm.provider 'virtualbox' do |vbox|
    vbox.memory = 4096
    vbox.cpus = 2
  end

  PROVISION_SCRIPTS.each do |script|
    config.vm.provision 'shell', inline: <<-EOF, privileged: true
      set -o errexit
      set -o xtrace
      #{script}
    EOF
  end
end
