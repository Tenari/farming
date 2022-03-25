#!/usr/bin/env ruby
#

#File.write(FILENAME, YAML.dump(data))
require 'yaml'
require 'date'

FILENAME = 'data.yml'
data = YAML.load_file(FILENAME)
data ||= {}
data[:rabbits] ||= []

def litters(rabbit, data)
  id = rabbit[:id]
  parent = rabbit[:gender] == 'male' ? :father : :mother
  children = data[:rabbits].select {|r| r[parent] == id }
  litters = {}
  children.each do |child|
    litters[child[:birth]] ||= 0
    litters[child[:birth]] += 1
  end
  litters
end

if ARGV[0] == 'add'
  if ARGV.count >= 4
    rabbit = {
      id: data[:rabbits].count,
      gender: ARGV[1],
      birth: Date.parse(ARGV[2]),
      location: ARGV[3],
    }
    if ARGV[4]
      rabbit[:father] = ARGV[4].to_i
    end
    if ARGV[5]
      rabbit[:mother] = ARGV[5].to_i
    end
    data[:rabbits].push(rabbit)
    File.write(FILENAME, YAML.dump(data))
    puts rabbit
  else
    puts "error incorrect command arguments count"
    puts "usage:\n  ./rabbit.rb add male 2022-05-30 cage-1"
  end
elsif ARGV[0] == 'show'
  if ARGV[1] == 'rabbit'
    puts data[:rabbits][ARGV[2].to_i]
  elsif ARGV[1] == 'litters'
    r = data[:rabbits][ARGV[2].to_i]
    puts "litter count: #{litters(r, data).keys.count}"
    litters(r, data).each do |d, c|
      puts "#{d} => #{c}"
    end
  elsif ['loc', 'location'].include?(ARGV[1])
    puts data[:rabbits].select{|r| r[:location] == ARGV[2]}
  end
elsif ARGV[0] == 'edit'
  if ARGV[1] == 'rabbit'
    if ARGV.count == 5
      id = ARGV[2].to_i
      key = ARGV[3].to_sym
      val = ARGV[4]
      if key == :birth
      elsif key == :id
        raise "Not allowed to edit id"
      end
      data[:rabbits][id][key] = val
      File.write(FILENAME, YAML.dump(data))
      puts data[:rabbits][id]
    else
      puts "./rabbit.rb edit rabbit 0 gender male"
    end
  end
end
