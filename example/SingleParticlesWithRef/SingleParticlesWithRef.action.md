# Actions for SingleParticlesWithRef package

## ConvertRoiToPad

```
mrcImageWindowing -i {$*}.roi -o {$*}.mask -W 0.1 0.0 0.05 0.0 -m 18
mrcImagePad -i {$*}.mask -o {$*}.padtmp -W {$PAD_W} -H {$PAD_H} -m 3
mrcImageWindowing -i {$*}.padtmp -o {$*}.pad -W 0.1 0.0 0.1 0.0 -m 2
```

## ConvertPadToCorinfo

```
mrcImageAutoRotationCorrelation -i {$*}.pad -r {$TARGET}.ref2d -O {$*}.corinfo -fit {$*}.fit -cor {$*}.cormap -n {$nROT} -m 18 -range {$ROTMIN} {$ROTMAX} -Iter 2 -nRot2 {$nRot2} -nRot1 {$nRot1} -nRot3 {$nRot3} 2> /dev/null
```

## ConvertCorinfoTo3dinfo

```
awk '/Cor/ { print $7,$16,$2,$3,$4,$5,$9,$11,$12}' {$*}.corinfo | sort -r | sed -e s/.pad/.fit/ > {$*}.3dinfolst
head -n 1 {$*}.3dinfolst | awk '{print $2,$3,$4,$5,$6,$1}' > {$*}.3dinfo
```

## Create3dlst

```
cat {$I[1].as_string.join(" ")} | sort > {$TARGET}.3dlst
```

## Create3d

```
mrc2Dto3D -I {$TARGET}.3dlst -o {$TARGET}.3d -InterpolationMode 2 -Double -DoubleCounter {$TARGET}.3dcounter -CounterThreshold 0.5 -m 1 -WeightMode 2
```
