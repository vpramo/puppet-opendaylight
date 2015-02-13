require 'puppetlabs_spec_helper/module_spec_helper'

# Tests that are common to all possible configurations
def generic_tests(yum_repo)
  # Confirm that module compiles
  it { should compile }
  it { should compile.with_all_deps }

  # Confirm presence of classes
  it { should contain_class('opendaylight') }
  it { should contain_class('opendaylight::params') }
  it { should contain_class('opendaylight::install') }
  it { should contain_class('opendaylight::config') }
  it { should contain_class('opendaylight::service') }

  # Confirm relationships between classes
  it { should contain_class('opendaylight::install').that_comes_before('opendaylight::config') }
  it { should contain_class('opendaylight::config').that_requires('opendaylight::install') }
  it { should contain_class('opendaylight::config').that_notifies('opendaylight::service') }
  it { should contain_class('opendaylight::service').that_subscribes_to('opendaylight::config') }
  it { should contain_class('opendaylight::service').that_comes_before('opendaylight') }
  it { should contain_class('opendaylight').that_requires('opendaylight::service') }

  # Confirm presense of other resources
  it { should contain_service('opendaylight') }
  it { should contain_yumrepo('opendaylight') }
  it { should contain_package('opendaylight') }
  it { should contain_file('org.apache.karaf.features.cfg') }

  # Confirm relationships between other resources
  it { should contain_package('opendaylight').that_requires('Yumrepo[opendaylight]') }
  it { should contain_yumrepo('opendaylight').that_comes_before('Package[opendaylight]') }

  # Confirm properties of other resources
  # NB: These hashes don't work with Ruby 1.8.7, but we
  #   don't support 1.8.7 so that's okay. See issue #36.
  it {
    should contain_yumrepo('opendaylight').with(
      'enabled'     => '1',
      'gpgcheck'    => '0',
      'descr'       => 'OpenDaylight SDN controller',
      'baseurl'     => yum_repo,
    )
  }
  it {
    should contain_package('opendaylight').with(
      'ensure'      => 'present',
    )
  }
  it {
    should contain_service('opendaylight').with(
      'ensure'      => 'running',
      'enable'      => 'true',
      'hasstatus'   => 'true',
      'hasrestart'  => 'true',
    )
  }
  it {
    should contain_file('org.apache.karaf.features.cfg').with(
      'ensure'      => 'file',
      'path'        => '/opt/opendaylight-0.2.2/etc/org.apache.karaf.features.cfg',
    )
  }
end

# Shared tests that specialize in testing Karaf feature installs
def karaf_feature_tests(features)
  it {
    should contain_file('org.apache.karaf.features.cfg').with(
      'ensure'      => 'file',
      'path'        => '/opt/opendaylight-0.2.2/etc/org.apache.karaf.features.cfg',
      'content'     => /^featuresBoot=#{features.join(",")}/
    )
  }
end

# Shared tests for unsupported OSs
def unsupported_os_tests(expected_err_msg)
  # Confirm that classes fail on unsupported OSs
  it { expect { should contain_class('opendaylight') }.to raise_error(Puppet::Error, /#{expected_err_msg}/) }
  it { expect { should contain_class('opendaylight::install') }.to raise_error(Puppet::Error, /#{expected_err_msg}/) }
  it { expect { should contain_class('opendaylight::config') }.to raise_error(Puppet::Error, /#{expected_err_msg}/) }
  it { expect { should contain_class('opendaylight::service') }.to raise_error(Puppet::Error, /#{expected_err_msg}/) }

  # Confirm that other resources fail on unsupported OSs
  it { expect { should contain_yumrepo('opendaylight') }.to raise_error(Puppet::Error, /#{expected_err_msg}/) }
  it { expect { should contain_package('opendaylight') }.to raise_error(Puppet::Error, /#{expected_err_msg}/) }
  it { expect { should contain_service('opendaylight') }.to raise_error(Puppet::Error, /#{expected_err_msg}/) }
  it { expect { should contain_file('org.apache.karaf.features.cfg') }.to raise_error(Puppet::Error, /#{expected_err_msg}/) }
end
