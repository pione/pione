# Actions for Fib package

## Fib0

The value of fib(0) is 0.

```
echo -n '0' > fib0.txt
```

## Fib1

The value of fib(1) is 1.

```
echo -n '1' > fib1.txt
```

## Calc

Calculate the value of fib(n-1) + fib(n-2).

```
echo "`cat {$I[1]}` + `cat {$I[2]}`" | bc > {$O[1]}
```

## Result

Make the fib result.

```
cp {$I[1]} {$O[1]}
```
