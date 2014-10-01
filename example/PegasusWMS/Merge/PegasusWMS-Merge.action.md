# Actions for PegasusWMS-Merge package

## List

Create a file that contains names of files in a directory.

```
ls -l {$DIRS[$INDEX+1]} > {$O[1]}
```

## Join

Concatenate all files into a file.

```
cat {$I[1]} > {$O[1]}
```
