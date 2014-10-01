# Actions for PegasusWMS-Split package

## GetHTML

```
curl -o {$O[1]} "http://pegasus.isi.edu"
```

## Split

```
split -l 100 -a 1 "{$I[1]}" part.
```

## Count

```
wc {$I[1]} > {$O[1]}
```
