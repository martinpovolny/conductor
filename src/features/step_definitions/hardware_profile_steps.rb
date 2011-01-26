Given /^there are the following aggregator hardware profiles:$/ do |table|
  table.hashes.each do |hash|
    create_hwp(hash)
  end
end

Given /^the Hardare Profile "([^"]*)" has the following Provider Hardware Profiles:$/ do |name, table|
  provider = Factory :mock_provider
  front_end_hwp = HardwareProfile.find_by_name(name)
  back_end_hwps = table.hashes.collect { |hash| create_hwp(hash, provider) }

  front_end_hwp.provider_hardware_profiles = back_end_hwps
  front_end_hwp.save!
end

def create_hwp(hash, provider=nil)
  memory = Factory(:mock_hwp1_memory, :value => hash[:memory])
  storage = Factory(:mock_hwp1_storage, :value => hash[:storage])
  cpu = Factory(:mock_hwp1_cpu, :value => hash[:cpu])
  arch = Factory(:mock_hwp1_arch, :value => hash[:architecture])
  Factory(:mock_hwp1, :name => hash[:name], :memory => memory, :cpu => cpu, :storage => storage, :architecture => arch, :provider => provider)
end

When /^I enter the following details for the Hardware Profile Properties$/ do |table|
  table.hashes.each do |hash|
    hash.each_pair do |key, value|
      unless (hash[:name] == "architecture" && (key == "range_first" || key == "range_last" || key == "property_enum_entries")) || key == "name"
        When "I fill in \"#{"hardware_profile_" + hash[:name] + "_attributes_" + key}\" with \"#{value}\""
      end
    end
  end
end

Given /^there are the following provider hardware profiles:$/ do |table|
  provider = Factory :mock_provider
  table.hashes.each do |hash|
    create_hwp(hash, provider)
  end
end