# Actions for DeferredChoiceWithPage package

## UserSelect

```
# start interactive operation
pione-interactive browser -o rule.txt --public ./etc

# generate an output
RULE=`cat rule.txt`
case "$RULE" in
  "rule A") touch a.txt ;;
  "rule B") touch b.txt ;;
  "rule C") touch c.txt ;;
esac
```

## A

```
echo 'You selected rule A' > {$O[1]}
```

## B

```
echo 'You selected rule B' > {$O[1]}
```

## C

```
echo 'You selected rule C' > {$O[1]}
```
