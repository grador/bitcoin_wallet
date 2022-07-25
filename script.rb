#! /usr/bin/env ruby
require 'bitcoin'
require 'bitcoin/protocol'
require 'bitcoin/protocol/tx'
require 'bitcoin/protocol/txout'
require 'bitcoin/protocol/txin'
require 'stringio'
require 'bitcoin/key'
require 'net/http'
require 'net/https'
require 'json'
include Bitcoin::Builder

Bitcoin.network = :testnet

FILENAME = '/keys/keys.csv'
URL = 'https://blockstream.info/testnet/api/'
KOEFF = 100000000

def to_satoshi(i)
  (i.to_f * KOEFF).round(0).to_i
end

def to_bitoc(i)
  (i.to_f / KOEFF).round(5).to_s
end

def parse_json(string)
  JSON.parse(string)
rescue
  puts 'Parse json error!'
  nil
end

def new_walet_info(key)
  puts "Your new 58base key is #{key} save it to restore!"
  puts '---------------------------------------------------------'
end

def create_addr
  key = Bitcoin::Key.generate
  File.write(FILENAME,"#{key.to_base58}\n", mode: 'a')
  key
end

def is_addr(str)
  # ^[13][a-km-zA-HJ-NP-Z1-9]{25,35}$  - for real
  str.match(/^[2mn][1-9A-Za-z]{26,35}/) || str.match(/^[t][0-9A-Za-z]{26,42}/)
end

# start
puts "Test job of Serafimov Sergey\n\n"

keys = if File.exist?(FILENAME)
  keys_arr = File.read(FILENAME).split("\n").map(&:chomp)
  keys_arr.map{ |i| Bitcoin::Key.from_base58(i)}
else
  [create_addr]
end
key = keys.last
begin
  return unless utxo = parse_json(Net::HTTP.get(URI("#{URL}address/#{key.addr}/utxo")))
  utxo_sum = utxo.sum(0){|i| i['status']['confirmed'] ? i['value'] : 0}
  puts "On address: #{key.addr} you have #{to_bitoc(utxo_sum)} tBTC\n\n"
  if utxo_sum > 10000
    puts 'Transfer - 1'
  else
    puts 'Insufficient funds to transfer'
    l = utxo.reject{|i| i['status']['confirmed']}.length
    puts "Your address has #{l} unconfirmed transaction#{l > 1 ? 's' : ''}, try later, please." if l > 0
    return
  end
  puts "Exit - 2"
  flag = gets.chomp
  if flag == '1' && utxo_sum > 10000
    puts "Enter amount, tBTC"
    amount = to_satoshi( gets.chomp )
    break if amount == 0
    if amount + 10000 > utxo_sum
      puts "Insufficient funds to transfer #{to_bitoc(amount)}\n\n"
      next
    end
    begin
      puts "Enter BTC address"
      addr = gets.chomp
      break if addr.length == 0
    end while !is_addr(addr)
    next if addr.length == 0
    #scan unconfirmed transaction
    return unless response = parse_json(Net::HTTP.get(URI("#{URL}address/#{key.addr}/txs/mempool")))
    if response.length > 0
      tr = response.length > 1 ? 's' : ''
      puts "Your address has #{response.length} unconfirmed transaction#{tr}.\nWe recommend waiting for the complete transaction#{tr} to exclude losses.\n"
      return
    end
    puts 'Transferring...'
    #  transfer
    return_me = (utxo_sum - amount - 10000)
    ptx = []
    new_my_addr =  Bitcoin::Key.generate
    begin
      utxo.each do |tx_i|
        next if tx_i['value'] == 0
        prev_tx = Bitcoin::P::Tx.new(Net::HTTP.get(URI("#{URL}tx/#{tx_i['txid']}/hex")).to_s.htb)
        ptx << {tx: prev_tx, ind: tx_i['vout']}
      end
      tx = build_tx do |t|
        ptx.each do |tx_i|
          t.input do |i|
            i.prev_out tx_i[:tx]
            i.prev_out_index tx_i[:ind]
            i.signature_key key
          end
        end
        t.output do |o|
          o.value amount
          o.to addr
        end
        if return_me > 0
          t.output do |o|
            o.value return_me
            o.to new_my_addr.addr
          end
        end
      end
      # tx = Bitcoin::Protocol::Tx.new( tx.to_payload )
      verify = true
      ptx.each_with_index do |txi, i|
        unless tx.verify_input_signature(i, txi[:tx])
          verify = false
          puts "Verify signature error ##{i}"
        end
      end
      if verify
        puts 'Verify signature: OK'
        hex =  tx.to_payload.unpack("H*")[0] # hex binary
        # puts hex.to_s
        uri = URI.parse("#{URL}tx")
        https = Net::HTTP.new(uri.host,uri.port)
        https.use_ssl = true
        req = Net::HTTP::Post.new(uri.path, {'Content-Type' =>'application/json'})
        req.body = "#{hex}"
        res = https.request(req)
        if res.code == '200'
          File.write(FILENAME,"#{new_my_addr.to_base58}\n", mode: 'a')
          puts "#{to_bitoc(amount)} tBTC has been transferred successfully, tx_id: #{res.body}"
          puts '---------------------------------------------------------'
        else
          puts "#{res.code} - #{res.message} - #{res.body}"
          new_walet_info new_my_addr.to_base58
        end
      end
    rescue => e
      puts "Error! #{e}"
      new_walet_info new_my_addr.to_base58
    end
  end
end while flag == '1'
puts 'Good luck!'




