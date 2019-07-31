require 'builder'

def create_train(version, id, seats_arr)
	{
		version: version,
		id: id,
		seats: seats_arr[rand(seats_arr.length)]
	}
end

def generate_trains(amount, id_length)
	train_ids = (0...amount).to_a.map { generate_random_alpha_num_string(id_length) }.uniq
	seats = [50, 80, 140, 250]
	half_of_trains = (train_ids.length / 2).to_i
	v2_trains = train_ids.map { |id| create_train(2, id, seats) }
	v1_trains = train_ids.take(half_of_trains).map { |id| create_train(1, id, seats) }
	v3_trains = train_ids.drop(half_of_trains).map { |id| create_train(3, id, seats) }
	{
		v1: v1_trains,
		v2: v2_trains,
		v3: v3_trains
	}
end

def create_trip(version, id, train, stations)
	{
		version: version,
		id: id,
		train: train[:id],
		stations: stations.map { |s| s[:id] }
	}
end

def create_station(version, id)
	{
		version: version,
		id: id,
		name: generate_random_name(20)
	}
end

def generate_stations(amount, id_length)
	station_ids = (0...amount).to_a.map { generate_random_alpha_num_string(id_length) }.uniq
	v2_stations = station_ids.map { |id| create_station(2, id)}
	v1_stations = station_ids.take(amount/2).map { |id| create_station(1, id) }
	v3_stations = station_ids.drop(amount/2).map { |id| create_station(3, id) }
	{	
		v1: v1_stations,
		v2: v2_stations,
		v3: v3_stations
	}
end

def generate_trips()
	trains = generate_trains(200, 10)
	stations = generate_stations(200, 10)
	trip_ids = (0...600).to_a.map { generate_random_alpha_num_string(11) }.uniq
	v1_trips = trip_ids.take(150).map { |id| create_trip(1, id, pick_rand_from_arr(trains[:v1]), pick_rand_several_arr(stations[:v1], 20)) }
	v2_trips = trip_ids.drop(150).take(150).map { |id| create_trip(2, id, pick_rand_from_arr(trains[:v2]), pick_rand_several_arr(stations[:v2], 20)) }
	v3_trips = trip_ids.drop(150).take(150).map { |id| create_trip(3, id, pick_rand_from_arr(trains[:v3]), pick_rand_several_arr(stations[:v3], 20)) }
	trains_rnd = trains[:v1] + trains[:v3] + (0...200).to_a.map { create_train(1, generate_random_alpha_num_string(10), [10]) } 
	stations_rnd = stations[:v1] + stations[:v3] + (0...400).to_a.map { create_station(1, generate_random_alpha_num_string(10)) }
	bad_trips = trip_ids.drop(450).map { |id| create_trip(2, id, pick_rand_from_arr(trains_rnd), pick_rand_several_arr(stations_rnd, 15)) }
	{
		trains: (trains[:v1] + trains[:v2] + trains[:v3]).shuffle,
		stations: (stations[:v1] + stations[:v2] + stations[:v3]).shuffle,
		trips: (v1_trips + v2_trips + v3_trips + bad_trips).shuffle
	}
end

def pick_rand_from_arr(arr)
	arr[rand(arr.length)]
end

def pick_rand_several_arr(arr, num)
	(0...num).to_a.map { pick_rand_from_arr(arr) }.uniq
end



def generate_random_alpha_num_string(length)
	chars = [('a'..'z'), ('A'..'Z'), ('0'..'9')].map(&:to_a).flatten
	(0...length).map { chars[rand(chars.length)] }.join
end

def generate_random_name(length)
	chars = ('A'..'Z').to_a + [' ']
	(0...length).map { chars[rand(chars.length)] }.join
end

def slice_into_10(arr)
	arr.each_slice(arr.length / 10).to_a
end

def write_xml()
	trips = generate_trips()
 	trains_sliced = slice_into_10(trips[:trains])
	stations_sliced = slice_into_10(trips[:stations])
	trips_sliced = slice_into_10(trips[:trips])
	
	trains_sliced.each_with_index do |train_g, idx|
		output = ""
		xml = Builder::XmlMarkup.new(:indent => 2, :target => output)
		xml.instruct! :xml, :encoding => "ASCII"
		xml.trains do |xtrains|
			train_g.each do |train|
				xtrains.train(:version => train[:version]) do |xt|
					xt.id(train[:id])
					xt.seats(train[:seats])
				end
			end
		end
		File.write("trains.#{idx}.xml", output)
	end
	
	stations_sliced.each_with_index do |st_g, idx|
		output = ""
		xml = Builder::XmlMarkup.new(:indent => 2, :target => output)
		xml.instruct! :xml, :encoding => "ASCII"
		xml.stations do |xstations|
			st_g.each do |st|
				xstations.station(:version => st[:version]) do |xs|
					xs.id(st[:id])
					xs.name(st[:name])
				end
			end
		end
		File.write("stations.#{idx}.xml", output)
	end
	
	trips_sliced.each_with_index do |trip_g, idx|
		output = ""
		xml = Builder::XmlMarkup.new(:indent => 2, :target => output)
		xml.instruct! :xml, :encoding => "ASCII"
		xml.trips do |xtrips|
			trip_g.each do |t|
				xtrips.trip(:version => t[:version]) do |xt|
					xt.id(t[:id])
					xt.train(t[:train])
					xt.stations do |xst|
						t[:stations].each { |st| xst.station(st) }
					end
				end
			end
		end
		File.write("trips.#{idx}.xml", output)
	end	
end

def remove_closing_tag(file)
	lines = IO.readlines(file)
	line_nr = rand(lines.length - 5)
	lines[line_nr] = lines[line_nr].tr('/','')
	lines[line_nr+1] = lines[line_nr+1].tr('/','')
	File.write(file, lines.join("\n"))
end

def remove_lines(file)
	lines = IO.readlines(file)
	line_nr = rand(lines.length - 5)
	new_lines = lines[0...line_nr] + lines[line_nr+1..lines.length]
	File.write(file, new_lines.join("\n"))
end

write_xml()
remove_closing_tag("trains.4.xml")
remove_lines("stations.7.xml")