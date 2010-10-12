#!/usr/bin/ruby

require 'rubygems'
require 'linode'
require 'commander'
require 'ostruct'
require 'yaml'

config = OpenStruct.new(YAML::load_file('config.yml'))

def pick_one(object, acceptable_input, max_attempts = 3)
  choice = nil
  attempts = 1
  while choice.nil?
    input = ask("Pick a #{object}: ").to_i

    if acceptable_input.include? input
      choice = input
    else
      puts "Invalid #{object}! Please choose one: #{acceptable_input.join(', ')}"
      raise "Error determining #{object}!" if attempts >= max_attempts
    end

    attempts = attempts + 1
  end

  choice
end

print "Connecting to Linode... "
begin
  linode = Linode.new(:api_key => config.api_token)
  print "OK!\n"
rescue Exception => error
  print "Error! #{error.message}\n"
end

node = {}

# Get available datacenters
datacenters = {}
linode.avail.datacenters.each do |datacenter|
  datacenters[datacenter.datacenterid] = datacenter
end

puts ""
# Choose the plan
puts "Available Plans"
acceptable_input = []
linode.avail.linodeplans.each do |plan|
  acceptable_input << plan.planid
  puts "(#{plan.planid}) #{plan.label} :: $#{plan.price} :: #{plan.ram} MB RAM / #{plan.disk} GB HDD / #{plan.xfer} GB BW"
end

choice = pick_one('Plan ID', acceptable_input)
linode.avail.linodeplans.each do |plan|
  if plan.planid == choice
    node[:plan] = plan
    break
  end
end

puts ""
# Choose the datacenter
puts "Available Datacenters"
acceptable_input = []
node[:plan].avail.each do |datacenter_id, available|
  acceptable_input << datacenter_id.to_i
  puts "(#{datacenter_id}) #{datacenters[datacenter_id.to_i].location} :: #{available} available"
end

choice = pick_one('Datacenter ID', acceptable_input)
datacenters.each_pair do |datacenter_id,datacenter|
  if datacenter.datacenterid == choice
    node[:datacenter] = datacenter
    break
  end
end

puts ""
puts "Warning! You are about to create a new Linode!"
puts "Datacenter: #{node[:datacenter].location}"
puts "Plan: #{node[:plan].label}"
puts "This will charge your card for at least $#{node[:plan].price}!"
response = ask("Is this OK? (y/n): ")
raise "Aborting Linode build!" unless response.downcase == 'y'

#response = linode.linode.create(:DatacenterID => node[:datacenter].datacenterid, :PlanID => node[:plan].planid, :PaymentTerm => 1)
#puts response.to_inspect

puts "Finished"

## Choose the architecture (32 or 64 bit)
#acceptable_input = [32, 64]
#arch = pick_one('Architecture', acceptable_input).to_i

## Choose the distribution
#puts "Available Linux Distributions"
#acceptable_input = []
#linode.avail.distributions.each do |distro|
  #if (distro.is64bit == 1 && arch == 64) || (distro.is64bit == 0 && arch == 32)
    #acceptable_input << distro.distributionid
    #puts "(#{distro.distributionid}) #{distro.label} :: created #{Date.parse(distro.create_dt)}"
  #end
#end

#choice = pick_one('Distro ID', acceptable_input)
#linode.avail.distributions.each do |distro|
  #if distro.distributionid == choice
    #node[:distribution] = distro
    #break
  #end
#end

#puts node.inspect
