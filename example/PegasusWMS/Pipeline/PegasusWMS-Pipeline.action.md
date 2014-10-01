# Actions for PegasusWMS-Pipeline package

## GetHTML

Get a HTML file from http://pegasus.isi.edu.

```
curl -o {$O[1]} "http://pegasus.isi.edu"
```

## Count

Create a character count file.

```
wc {$I[1]} > {$O[1]}
```
