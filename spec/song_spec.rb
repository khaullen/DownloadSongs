#!/usr/bin/env ruby

require 'song'

describe Song do
  songA  = Song.new("termA termB  termC\ttermD\rtermE\ntermF")
  songA2 = Song.new("termA termB termC termD termE termF")
  songB  = Song.new("termA termB termX termY termZ") 

  it "correctly splits input string into search terms" do
    expect(songA.search_terms).to eq ['termA', 'termB', 'termC', 'termD', 'termE', 'termF'];      
  end

  it "correctly reassembles its search terms into a string for output" do
    expect(songA.to_s).to eq "termA termB termC termD termE termF"
  end

  it "correctly implements is_a" do
    expect(songA.is_a? Song).to eq true
  end

  it "correctly implements equality checks" do    
    expect(songA == nil).to eq false
    expect(songA == "termA termB termX termY termZ").to eq false
    expect(songA == songA).to eq true
    expect(songA == songA2).to eq true
    expect(songA == songB).to eq false
  end
end 
