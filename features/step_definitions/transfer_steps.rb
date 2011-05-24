TRANSFER_TYPES = [
  'between plates',
  'from plate to tube'
]

TRANSFER_TYPES_REGEXP = TRANSFER_TYPES.join('|')

def transfer_model(name)
  "transfer/#{name}".gsub(/\s+/, '_').camelize.constantize
end

Given /^the UUID for the transfer (#{TRANSFER_TYPES_REGEXP}) with ID (\d+) is "([^\"]+)"$/ do |model,id,uuid_value|
  set_uuid_for(transfer_model(model).find(id), uuid_value)
end

Given /^the transfer (between plates|from plate to tube) exists with ID (\d+)$/ do |name,id|
  Factory(:"transfer_#{name.gsub(/\s+/, '_')}", :id => id)
end

Given /^the UUID for the (source|destination) of the transfer (#{TRANSFER_TYPES_REGEXP}) with ID (\d+) is "([^\"]+)"$/ do |target, model, id, uuid_value|
  set_uuid_for(transfer_model(model).find(id).send(target), uuid_value)
end

Given /^the transfer template called "([^\"]+)" exists$/ do |name|
  Factory(:transfer_template, :name => name)
end

Then /^the transfers from plate (\d+) to plate (\d+) should be:$/ do |id1, id2, table|
  source, destination = Plate.find(id1), Plate.find(id2)
  table.hashes.each do |transfers|
    source_well_location, destination_well_location = transfers['source'], transfers['destination']

    source_well      = source.wells.located_at(source_well_location).first           or raise StandardError, "Plate #{source.id} does not have well #{source_well_location.inspect}"
    destination_well = destination.wells.located_at(destination_well_location).first or raise StandardError, "Plate #{destination.id} does not have well #{destination_well_location.inspect}"
    assert_not_nil(TransfertRequest.between(source_well, destination_well).first, "No transfer between #{source_well_location.inspect} and #{destination_well_location.inspect}")
  end
end

Given /^a transfer plate exists with ID (\d+)$/ do |id|
  Factory(:transfer_plate, :id => id)
end