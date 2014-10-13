# Actions for Sum package

## MakeHeadTail

```
#!/usr/bin/env ruby
i = 1
File.readlines('list.txt').each do |line|
  head, tail = line.split(',')
  File.open("head#{i}.txt", "w+"){|f| f.print head}
  File.open("tail#{i}.txt", "w+"){|f| f.print tail}
  i += 1
end
```

## SumFiles

Calculate sum of files. This action use Bash's expr.

```
expr `cat {$INPUT[1]}` + `cat {$INPUT[2]}`
```

## Aggregation

```
#!/usr/bin/env ruby
sum = 0
'{$INPUT[1]}'.split(' ').sort.each do |filename|
  n = File.read(filename)
  sum += n.to_i
  puts n
end
puts "total: #{sum}"
```
