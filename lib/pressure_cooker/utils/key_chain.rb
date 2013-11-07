require 'mixlib/shellout'

class KeyChain
  def self.find_internet_password(account, server)
    cmd = "security find-internet-password -w -a #{account} -s #{server}"
    shell = Mixlib::ShellOut.new(cmd)
    shell.run_command
    shell.error!
    shell.stdout
  end
end
