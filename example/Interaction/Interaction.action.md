# Actions for Interaction package

## InteractiveAction

```
# build public directory for pione-interactive
mkdir public
cp bin/* public
cp etc/* public
cp etc/.hidden-file.txt public

# set environment variables for CGI
export ENV_EXAMPLE1=a
export ENV_EXAMPLE2=b
export ENV_EXAMPLE3=c

# start interactive operation
pione-interactive browser --public public

cp public/* .
```
