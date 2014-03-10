# Configure a simple Qpid Dispatch Router
#
# Facts are loaded from the /etc/qpid-dispatch/facts.conf file
# which contains name=value pairs.
#

@facts = {}

begin
  f = File.read('/home/mcpierce/Programming/puppet-qpid/facter/facts')
  f.each_line do |line|
    if !line.nil? && !line.empty? && !line.start_with?("#")
      line = line.chomp.split "="
      @facts[line[0]] = line[1]
    end
  end
rescue RuntimeError => error
  # load default values
  put "ERROR: #{error}"
end

def fact_or_find(key, &block)
  if @facts.has_key? key
    value = @facts["#{key}"]
  else
    value = block_given? ? block.yield : nil
  end

  Facter.add(key) { setcode { value } } unless value.nil?
end

def count_entry(key)
  if @facts.has_key? key
    @facts[key].to_i
  else
    0
  end
end

fact_or_find("qpid_dispatch_container_name") { Facter::Util::Resolution.exec('/usr/bin/hostname') }
fact_or_find("qpid_dispatch_worker_thread")  { 4 }
fact_or_find("qpid_dispatch_ssl_profile_name") { nil }

# listeners
listeners = count_entry("qpid_dispatch_listener_count")
Facter.add("qpid_dispatch_listener_count") { setcode { listeners } }
(1..listeners).each do |which|
  fact_or_find("qpid_dispatch_listener_#{which}_role")
  fact_or_find("qpid_dispatch_listener_#{which}_address")
  fact_or_find("qpid_dispatch_listener_#{which}_port")
  fact_or_find("qpid_dispatch_listener_#{which}_sasl_mechanisms")
end

# router
fact_or_find("qpid_dispatch_router_mode") { raise ValueError, "Router mode undefined" }
fact_or_find("qpid_dispatch_router_id") { nil }

# fixed addresses
fixed_addresses = count_entry("qpid_dispatch_fixed_address_count")
Facter.add("qpid_dispatch_fixed_address_count") { setcode { fixed_addresses } }
(1..fixed_addresses).each do |which|
  fact_or_find("qpid_dispatch_fixed_address_#{which}_prefix")
  fact_or_find("qpid_dispatch_fixed_address_#{which}_fanout")
  fact_or_find("qpid_dispatch_fixed_address_#{which}_bias")
end
