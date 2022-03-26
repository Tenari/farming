#!/usr/bin/env ruby
#
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

# return array of ids of ancestral rabbits
def ancestors(r, data)
  if r[:father] && r[:mother]
    return [
      r[:father], r[:mother],
      ancestors(data[:rabbits][r[:father]], data),
      ancestors(data[:rabbits][r[:mother]], data)
    ].flatten
  else
    return []
  end
end

# return hash of id => %genetic influence
def genes(r, data)
  result = {}
  if r[:father]
    result[r[:father]] ||= 0
    father = data[:rabbits][r[:father]]
    if father[:father].nil?
      result[r[:father]] += 0.5
    else
      result[r[:father]] += 0.25
      father_result = genes(father, data)
      father_result.each do |id, score|
        result[id] ||= 0
        result[id] += (0.25 * score)
      end
    end
  end
  if r[:mother]
    result[r[:mother]] ||= 0
    mother = data[:rabbits][r[:mother]]
    if mother[:mother].nil?
      result[r[:mother]] += 0.5
    else
      result[r[:mother]] += 0.25
      mother_result = genes(mother, data)
      mother_result.each do |id, score|
        result[id] ||= 0
        result[id] += (0.25 * score)
      end
    end
  end

  # root/new stock have unknown parentage so their genes come 100% from themselves
  result[r[:id]] = 1.0 if result.keys.count == 0
  
  return result
end

def gene_overlap(g1, g2)
  result = 0
  g1.each do |id, score|
    next if g2[id].nil?
    overlap = [g2[id], score].min
    result += overlap
  end
  return result
end

# return score from 0 to infinity where 
# 0=blood brothers 
# infinity= no known relation
def relatedness(r1, r2, data)
  if r1[:father] == r2[:father] && r1[:mother] == r2[:mother]
    return 0 # siblings
  elsif r1[:father] == r2[:father] || r1[:mother] == r2[:mother]
    return 1 # half siblings
  else
    common = 0
    a1 = ancestors(r1, data)
    a2 = ancestors(r2, data)
    a1.each do |id|
      if ind = a2.index(id)
        common += 1
        a2[ind] = nil
      end
    end
    return [a1.count, a2.count].max - common
  end
end

def check_error(cond, count, msg)
  if ARGV.count.send(cond, count)
  else
    puts msg
    puts "\n"
    raise ArgumentError
  end
end

if ARGV[0] == 'add'
  check_error(:>=, 4, "error incorrect command arguments count\nusage:\n  ./rabbit.rb add male 2022-05-30 cage-1")

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
elsif ARGV[0] == 'show'
  check_error(:>=, 3, "./rabbit.rb show [rabbit|litters|location] [id]")

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
  elsif ARGV[1] == 'relatedness'
    puts relatedness(data[:rabbits][ARGV[2].to_i], data[:rabbits][ARGV[3].to_i], data)
  elsif ARGV[1] == 'ancestors'
    puts ancestors(data[:rabbits][ARGV[2].to_i], data)
  elsif ARGV[1] == 'genes'
    puts genes(data[:rabbits][ARGV[2].to_i], data)
  elsif ARGV[1] == 'overlap'
    puts gene_overlap(
      genes(data[:rabbits][ARGV[2].to_i], data),
      genes(data[:rabbits][ARGV[3].to_i], data)
    )
  elsif ARGV[1] == 'best_breeder'
    r = data[:rabbits][ARGV[2].to_i]
    raise "selected rabbit has unk gender" if r[:gender] == "unk"
    rg = genes(r, data)
    best = {score: 10, id: nil}
    data[:rabbits].each do |breeder|
      next if breeder[:id] == r[:id]
      next if breeder[:gender] == "unk"
      next if breeder[:gender] == r[:gender]
      score = gene_overlap(genes(breeder, data), rg)
      if score < best[:score]
        best[:score] = score
        best[:id] = breeder[:id]
      end
    end
    puts best
    puts data[:rabbits][best[:id]]
  end
elsif ARGV[0] == 'edit'
  if ARGV[1] == 'rabbit'
    check_error(:==, 5, "./rabbit.rb edit rabbit 0 gender male")

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
  end
end
