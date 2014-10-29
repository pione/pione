# Actions for LucasNumber package

## LucasNumber0

```
echo 2 > LucasNumber0.txt
```

## LucasNumber1

```
echo 1 > LucasNumber1.txt
```

## Calc

```
echo "`cat {$I[2]}` {$OP} `cat {$I[1]}`" | bc > {$O[1]}
```

## Result

```
cat {$I[1]} > {$O[1]}
```
