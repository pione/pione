# Actions for DeferredChoice

## UserSelect

The rule "UserSelect" selects a rule from rule A, B, or C.

```
case "$PIONE_CLIENT_UI" in
  "Browser")
    pione-interactive --ui Browser --type dialog --definition bin/ui.xml -o rule.txt ;;
  "GUI")
    if [ "{$DIALOG}" = "zenity" ]
    then
      zenity --list --title "select action" --column rule "rule A" "rule B" "rule C" > rule.txt
    else
      xmessage -print -center -buttons "rule A,rule B,rule C" "select action" > rule.txt
    fi ;;
  *)
    echo "rule A" > rule.txt
esac

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
