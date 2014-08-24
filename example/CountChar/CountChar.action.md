# CountChar.pione

## ConvertToUTF8

Convert character encoding of text files into UTF-8.

```
iconv -c -f Shift_JIS -t UTF-8 {$I[1]} > {$O[1]}
```

## CountUTF8Char

Count UTF-8 characters in the text file.

```
#!/usr/bin/env ruby
# coding: utf-8

table = {}
text = File.open("{$I[1]}").read
text.split("").each do |c|
  table[c] =  table.has_key?(c) ? table[c].succ : 1
end
table.keys.sort {|a,b| table[b] <=> table[a] }.each do |key|
  puts "#{key.inspect[1..-2]}:#{table[key]}"
end
```

## Summarize

Make a summary about numbers of character in text files.

```
#!/usr/bin/env ruby
# coding: utf-8

table = {}
"{$I[1]}".split(" ").each do |path|
  File.read(path).split("\n").map do |line|
    c, number = line.split(":")
    table[c] = (table.has_key?(c) ? table[c] : 0) + number.to_i
  end
end
table.keys.sort {|a,b| table[b] <=> table[a] }.each do |key|
  puts "#{key.inspect[1..-2]}:#{table[key]}"
end
```